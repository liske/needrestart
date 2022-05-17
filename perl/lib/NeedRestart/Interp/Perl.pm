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
use Module::ScanDeps;

my $LOGPREF = '[Perl]';

needrestart_interp_register(__PACKAGE__);

sub isa {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;

    return 1 if($bin =~ m@^/usr/(local/)?bin/perl(5[.\d]*)?$@);

    return 0;
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
    my %e = nr_parse_env($pid);
    local %ENV;
    if(exists($e{PERL5LIB})) {
	$ENV{PERL5LIB} = $e{PERL5LIB};
    }
    elsif(exists($ENV{PERL5LIB})) {
	delete($ENV{PERL5LIB});
    }

    @Module::ScanDeps::IncludeLibs = (exists($opts{I}) ? ($opts{I}) : ());
    my $href;
    {
	# Silence warnings of Module::ScanDeps for dynamic loaded modules (github issue #41)
	local $SIG{__WARN__} = sub { };

	$href = scan_deps(
	    files => [$src],
	    recurse => 1,
	    );
    }

    my %ret = map {
	my $stat = nr_stat("/proc/$pid/root/$href->{$_}->{file}");
	$href->{$_}->{file} => ( defined($stat) ? $stat->{ctime} : undef );
    } keys %$href;

    chdir($cwd);

    $cache->{files}->{(__PACKAGE__)}->{$src} = \%ret;
    return %ret;
}

1;
