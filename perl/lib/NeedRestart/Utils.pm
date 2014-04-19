# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2014 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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
    nr_ptable_pid
    nr_parse_cmd
    nr_stat
);

my %ptable = map {$_->pid => $_} @{ new Proc::ProcessTable(enable_ttys => 0)->table };

sub nr_ptable_pid($) {
    my $pid = shift;

    return $ptable{$pid};
}

sub nr_parse_cmd($) {
    my $pid = shift;

    open(HCMD, '<', "$main::nrconf{procfs}/$pid/cmdline") || return ();
    local $/ = "\000";
    my @cmdline = <HCMD>;
    close(HCMD);

    return @cmdline;
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

1;
