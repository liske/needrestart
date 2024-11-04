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

package NeedRestart::Interp::Perl;

use strict;
use warnings;

use parent qw(NeedRestart::Interp);
use Cwd qw(abs_path getcwd);
use Getopt::Std;
use NeedRestart qw(:interp);
use NeedRestart::Utils;

my $LOGPREF = '[Perl]';

needrestart_interp_register(__PACKAGE__, "perl");

sub isa {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;

    return 1 if($bin =~ m@^/usr/(local/)?bin/perl(5[.\d]*)?$@);

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
	(/^\s*use\s+([a-zA-Z][\w:]+)/ ? ($1 => 1) : ())
    } <$fh>;
    close($fh);

    # track file
    $files->{$src}++;

    # scan module files
    if(scalar keys %modules) {
	foreach my $module (keys %modules) {
        # skip some well-known Perl pragmas
        next if ($module =~ /^(constant|strict|vars|v5(\.\d+)?|warnings)$/);

	    $module =~ s@::@/@g;
	    $module .= '.pm';

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

    # eat Perl's command line options
    my %opts;
    {
	local $SIG{__WARN__} = sub { };
	getopts('sTtuUWXhvV:cwdt:D:pnaF:l:0:I:m:M:fC:Sx:i:eE:', \%opts);
    }

    # skip perl -e '...' calls
    if(exists($opts{e}) || exists($opts{E})) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: uses no source file (-e), skipping\n" if($self->{debug});
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

    # eat Perl's command line options
    my %opts;
    {
	local $SIG{__WARN__} = sub { };
	getopts('sTtuUWXhvV:cwdt:D:pnaF:l:0:I:m:M:fC:Sx:i:eE:', \%opts);
    }

    # skip perl -e '...' calls
    if(exists($opts{e}) || exists($opts{E})) {
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: uses no source file (-e), skipping\n" if($self->{debug});
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
	chdir($cwd);
	print STDERR "$LOGPREF #$pid: use cached file list\n" if($self->{debug});
	return %{ $cache->{files}->{(__PACKAGE__)}->{$src} };
    }

    # prepare include path environment variable
    my @path;
    local %ENV;

    # get include path from env
    my %e = nr_parse_env($pid);
    if(exists($e{PERL5LIB})) {
	@path = map { "/proc/$pid/root/$_"; } split(':', $e{PERL5LIB});
    }

    # get include path from @INC
    my $plread = nr_fork_pipe($self->{debug}, $ptable->{exec}, '-e', 'print(join("\n", @INC));');
    push(@path, map { "/proc/$pid/root/$_"; } <$plread>);
    close($plread);
    chomp(@path);

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
