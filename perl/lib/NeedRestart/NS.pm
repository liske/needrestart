# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2015 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::NS;

use strict;
use warnings;
use NeedRestart::Utils;

my $LOGPREF = '[NS]';

sub new {
    my $class = shift;
    my $debug = shift;

    my $stat = nr_stat(q(/proc/1/ns/pid));
    my $nspid;
    if($stat) {
	$nspid = $stat->{ino};
	print STDERR "$LOGPREF #1 uses ns pid:[$nspid]\n" if($debug);
    }
    else {
	print STDERR "$LOGPREF unable to get init's ns pid\n" if($debug);
    }

    return bless {
	debug => $debug,
	nspid => $nspid,
    }, $class;
}

sub check($$) {
    my $self = shift;

    return 0 unless($self->{nspid});

    my $pid = shift;
    my $stat = nr_stat(qq(/proc/$pid/ns/pid));

    return 0 unless($stat);

    # return true if process is part of a different pid namespace than our init
    if($self->{nspid} != $stat->{ino}) {
	print STDERR "$LOGPREF #$pid has descent ns pid:[$stat->{ino}]\n" if($self->{debug});
	return 1;
    }
    else {
	return 0;
    }
}

1;
