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

package NeedRestart::Interp::Java;

use strict;
use warnings;

use parent qw(NeedRestart::Interp);
use NeedRestart qw(:interp);
use NeedRestart::Utils;

my $LOGPREF = '[Java]';

needrestart_interp_register(__PACKAGE__);

sub isa {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;

    return 1 if($bin =~ m@/.+/bin/java@);

    return 0;
}

sub source {
    # n/a (no shebang)
    return undef;
}

sub files {
    my $self = shift;
    my $pid = shift;

    my %ret = map {
	my $stat = nr_stat("/proc/$pid/root/$_");
	$_ => ( defined($stat) ? $stat->{ctime} : undef );
    } map {
	my $l = readlink;
	(defined($l) && $l =~ /\.(class|jar)( \(deleted\))?$/ ? $l : ());
    } grep {1;} </proc/$pid/fd/*>;

    return %ret;
}

1;
