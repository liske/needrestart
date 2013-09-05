# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::UI::stdio;

use strict;
use warnings;

use parent qw(NeedRestart::UI);
use NeedRestart qw(:ui);


needrestart_ui_register(__PACKAGE__, NEEDRESTART_PRIO_LOW);

sub progress_prep($$$) {
    my $self = shift;
    my ($max, $out) = @_;

    $self->SUPER::progress_prep($max, $out);

    print "$out:\n";

    $|++;
}

sub progress_step($$) {
    my $self = shift;
    my $s = shift;

    foreach my $i (1..$s) {
	print ".";
    }
}

sub progress_fin($) {
    my $self = shift;

    print "\n";

    $|--;
}


sub query_prep($) {
}

sub query_pkg($$$) {
    my $self = shift;

    die;
}

sub query_fin($) {
}

1;
