# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2022 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
#
# License:
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this package; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#

package NeedRestart::Interp::Python;

use strict;
use warnings;

use parent qw(NeedRestart::Interp);
use Cwd qw(abs_path getcwd);
use Getopt::Std;
use NeedRestart qw(:interp);
use NeedRestart::Utils;

my $LOGPREF = '[Python]';

needrestart_interp_register(__PACKAGE__);

sub isa {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;

    return 1 if($bin =~ m@^/usr/(local/)?bin/python([23][.\d]*)?$@);

    return 0;
}

sub _scan($$$$$) {
    my $debug = shift;
    my $pid = shift;
    my $src = shift;
    my $files = shift;
    my $path = shift;

    my $fh;
    open($fh, '<', $src) || return;
    # find used modules
    my %modules = map {
	(/^\s*import\s+(\S+)/ ? ($1 => 1) : (/^\s*from\s+(\S+)\s+import\s+/ ? ($1 => 1) : ()))
    } <$fh>;
    close($fh);

    # track file
    $files->{$src}++;

    # scan module files
    if(scalar keys %modules) {
	foreach my $module (keys %modules) {
	    $module =~ s@\.@/@g;
	    $module .= '.py';

	    foreach my $p (@$path) {
		my $fn = ($p ne '' ? "$p/" : '').$module;
		&_scan($debug, $pid, $fn, $files, $path) if(!exists($files->{$fn}) && -r $fn && -f $fn);
	    }
	}
    }
}

sub source {
    my $self = shift;
    my $pid = shift;
    my $ptable = nr_ptable_pid($pid);
    unless($ptable->{cwd}) {
	print STDERR "$LOGPREF #$pid: could not get current working directory, skipping\n" if($self->{debug});
	return undef;
    }
    my $cwd = getcwd();
    chdir("/proc/$pid/root/$ptable->{cwd}");

    # skip the process if the cwd is unreachable (i.e. due to mnt ns)
    unless(getcwd()) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: process cwd is unreachable\n" if($self->{debug});
	return undef;
    }

    # get original ARGV
    (my $bin, local @ARGV) = nr_parse_cmd($pid);

    # eat Python's command line options
    my %opts;
    {
	local $SIG{__WARN__} = sub { };
	getopts('BdEhim:ORQ:sStuvVW:x3?c:', \%opts);
    }

    # skip python -c '...' calls
    if(exists($opts{c})) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: uses no source file (-c), skipping\n" if($self->{debug});
	return undef;
    }

    # extract source file
    unless($#ARGV > -1) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: could not get a source file, skipping\n" if($self->{debug});
	return undef;
    }

    my $src = abs_path($ARGV[0]);
    chdir($cwd);
    unless(defined($src) && -r $src && -f $src) {
	print STDERR "$LOGPREF #$pid: source file not found, skipping\n" if($self->{debug});
	print STDERR "$LOGPREF #$pid:  reduced ARGV: ".join(' ', @ARGV)."\n" if($self->{debug});
	return undef;
    }

    return $src;
}

sub files {
    my $self = shift;
    my $pid = shift;
    my $cache = shift;
    my $ptable = nr_ptable_pid($pid);
    unless($ptable->{cwd}) {
	print STDERR "$LOGPREF #$pid: could not get current working directory, skipping\n" if($self->{debug});
	return ();
    }
    my $cwd = getcwd();
    chdir("/proc/$pid/root/$ptable->{cwd}");

    # skip the process if the cwd is unreachable (i.e. due to mnt ns)
    unless(getcwd()) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: process cwd is unreachable\n" if($self->{debug});
	return ();
    }

    # get original ARGV
    (my $bin, local @ARGV) = nr_parse_cmd($pid);

    # eat Python's command line options
    my %opts;
    {
	local $SIG{__WARN__} = sub { };
	getopts('BdEhim:ORQ:sStuvVW:x3?c:', \%opts);
    }

    # skip python -c '...' calls
    if(exists($opts{c})) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: uses no source file (-c), skipping\n" if($self->{debug});
	return ();
    }

    # extract source file
    unless($#ARGV > -1) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: could not get a source file, skipping\n" if($self->{debug});
	return ();
    }
    my $src = abs_path ($ARGV[0]);
    unless(defined($src) && -r $src && -f $src) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: source file not found, skipping\n" if($self->{debug});
	print STDERR "$LOGPREF #$pid:  reduced ARGV: ".join(' ', @ARGV)."\n" if($self->{debug});
	return ();
    }
    print STDERR "$LOGPREF #$pid: source=$src\n" if($self->{debug});

    # use cached data if avail
    if(exists($cache->{files}->{(__PACKAGE__)}->{$src})) {
	print STDERR "$LOGPREF #$pid: use cached file list\n" if($self->{debug});
	return %{ $cache->{files}->{(__PACKAGE__)}->{$src} };
    }

    # prepare include path environment variable
    my %e = nr_parse_env($pid);
    local %ENV;
    if(exists($e{PYTHONPATH})) {
	$ENV{PYTHONPATH} = $e{PYTHONPATH};
    }
    elsif(exists($ENV{PYTHONPATH})) {
	delete($ENV{PYTHONPATH});
    }

    # get include path
    my ($pyread, $pywrite) = nr_fork_pipe2($self->{debug}, $ptable->{exec}, '-');
    print $pywrite "import sys\nprint(sys.path)\n";
    close($pywrite);
    my ($path) = <$pyread>;
    close($pyread);

    # look for module source files
    my @path;
    if(defined($path)) {
	chomp($path);
	$path =~ s/^\['//;
	$path =~ s/'\$//;
	@path = map { "/proc/$pid/root/$_"; } split("', '", $path);
    }
    else {
	print STDERR "$LOGPREF #$pid: failed to retrieve include path\n" if($self->{debug});
    }

    my %files;
    _scan($self->{debug}, $pid, $src, \%files, \@path);

    my %ret = map {
	my $stat = nr_stat("/proc/$pid/root/$_");
	$_ => ( defined($stat) ? $stat->{ctime} : undef );
    } keys %files;

    chdir($cwd);

    $cache->{files}->{(__PACKAGE__)}->{$src} = \%ret;
    return %ret;
}

1;
