# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2020 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::Utils;

use strict;
use warnings;

use Proc::ProcessTable;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_ptable
    nr_ptable_pid
    nr_parse_cmd
    nr_parse_env
    nr_readlink
    nr_stat
    nr_fork_pipe
    nr_fork_pipe_stderr
    nr_fork_pipew
    nr_fork_pipe2
);

my %ptable;
{
    local $SIG{__WARN__} = sub {};
    %ptable = map {$_->pid => $_} @{ new Proc::ProcessTable(enable_ttys => 1)->table };
}

sub nr_ptable() {
    return \%ptable;
}

sub nr_ptable_pid($) {
    my $pid = shift;

    return $ptable{$pid};
}

sub nr_parse_cmd($) {
    my $pid = shift;

    my $fh;
    open($fh, '<', "/proc/$pid/cmdline") || return ();
    local $/ = "\000";
    my @cmdline = <$fh>;
    chomp(@cmdline);
    close($fh);

    return @cmdline;
}

sub nr_parse_env($) {
    my $pid = shift;

    my $fh;
    open($fh, '<', "/proc/$pid/environ") || return ();
    local $/ = "\000";
    my @env = <$fh>;
    chomp(@env);
    close($fh);

    return map { (/^([^=]+)=(.*)$/ ? ($1, $2) : ()) } @env;
}

my %readlink;
sub nr_readlink($) {
    my $pid = shift;

    return $readlink{$pid} if(exists($readlink{$pid}));

    my $fn = "/proc/$pid/exe";

    return ($readlink{$pid} = readlink($fn));
}

my %stat;
sub nr_stat($) {
    my $fn = shift;

    return $stat{$fn} if(exists($stat{$fn}));

    my @stat = stat($fn);

    return undef unless($#stat > -1);

    $stat{$fn} = {
	dev => $stat[0],
	ino => $stat[1],
	mode => $stat[2],
	nlink => $stat[3],
	uid => $stat[4],
	gid => $stat[5],
	rdev => $stat[6],
	size => $stat[7],
	atime => $stat[8],
	mtime => $stat[9],
	ctime => $stat[10],
	blksize => $stat[11],
	blocks => $stat[12],
    };

    return $stat{$fn};
}

sub nr_fork_pipe($@) {
    my $debug = shift;

    my $pid = open(HPIPE, '-|');
    defined($pid) || die "Can't fork: $!\n";

    if($pid == 0) {
	close(STDIN);
	close(STDERR) unless($debug);

	undef $ENV{LANG};

	exec(@_);
	exit;
    }

    \*HPIPE
}

sub nr_fork_pipe_stderr {
    my $debug = shift;

    my $pid = open(HPIPE, '-|');
    defined($pid) || die "Can't fork: $!\n";

    if($pid == 0) {
	open(STDERR, '>&', STDOUT) || die "Can't dup stderr: $!\n";
	close(STDIN);

	undef $ENV{LANG};

	exec(@_);
	exit;
    }

    \*HPIPE
}

sub nr_fork_pipew($@) {
    my $debug = shift;

    my $pid = open(HPIPE, '|-');
    defined($pid) || die "Can't fork: $!\n";

    if($pid == 0) {
	close(STDOUT);
	close(STDERR) unless($debug);

	undef $ENV{LANG};

	exec(@_);
	exit;
    }

    \*HPIPE
}

sub nr_fork_pipe2($@) {
    my $debug = shift;

    my ($pread, $fhwrite);
    pipe($pread, $fhwrite) || die "Can't pipe: $!\n";

    my $fhread;
    my $pid = open($fhread, '-|');
    defined($pid) || die "Can't fork: $!\n";

    if($pid == 0) {
	open(STDIN, '<&', $pread) || die "Can't dup stdin: $!\n";
	close(STDERR) unless($debug);

	undef $ENV{LANG};

	exec(@_);
	exit;
    }
    close($pread);

    return ($fhread, $fhwrite);
}

1;
