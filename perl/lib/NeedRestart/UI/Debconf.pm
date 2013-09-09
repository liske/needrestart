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

package NeedRestart::UI::Debconf;

use strict;
use warnings;

use parent qw(NeedRestart::UI);
use NeedRestart qw(:ui);
use Debconf::Client::ConfModule qw(:all);

version('2.0');
capb;

needrestart_ui_register(__PACKAGE__, NEEDRESTART_PRIO_HIGH);

sub new() {
    my $class = shift;

    return bless {}, $class;
}

sub progress_prep($$$) {
    my $self = shift;
    my ($max, $out) = @_;

    $self->SUPER::progress_prep($max, $out);

    $|++;

    db_subst('needrestart/ui-progress_title', 'OUT', $out);
    db_progress('START', 0, $max, 'needrestart/ui-progress_title');

    print "$out";
}

sub progress_step($$) {
    my $self = shift;
    my $s = shift;

    foreach my $i (1..$s) {
	db_progress('STEP', 1);
	db_progress('INFO', 'needrestart/ui-progress_info');
    }
}

sub progress_fin($) {
    my $self = shift;

    print "\n";

    $|--;
}


sub notice($$) {
    my $self = shift;
    my $out = shift;

#    $self->{dialog}->msgbox(title => 'Notice', text => $out);
}


sub query_pkgs($$$$$) {
    my $self = shift;
    my $out = shift;
    my $def = shift;
    my $pkgs = shift;
    my $cb = shift;

    # prepare checklist array
#    my @l = map { my $p = $_; map { ("$_", ["from $p", ($def ? 0 : 1)]) } sort keys %{ $pkgs->{$p} }} sort keys %$pkgs;

    # get selected rc script
#    my @s = $self->{dialog}->checklist(text => $out, list => \@l);

    # restart each selected RC script
#    &$cb($_) for @s;
}

1;
