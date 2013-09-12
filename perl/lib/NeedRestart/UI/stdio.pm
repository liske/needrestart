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

    $|++;

    print "$out";
}

sub progress_step($$) {
    my $self = shift;

    print '.';
}

sub progress_fin($) {
    my $self = shift;

    print "\n";

    $|--;
}


sub notice($$) {
    my $self = shift;
    my $out = shift;

    print "$out\n";
}


sub _query($$) {
    my($query, $def) = @_;
    my @def = ($def eq 'Y' ? qw(yes no) : qw(no yes));

    my $i;
    do {
	print "$query [", ($def eq 'Y' ? 'Yn' : 'yN'), '] ';;
	$i = lc(<STDIN>);
	chomp($i);
	$i =~ s/^\s+//;
	$i =~ s/\s+$//;
    } while(!( ($i) = map { (substr($_, 0, length($i)) eq $i ? ($_) : ())} @def ));

    return $i;
}

sub query_pkgs($$$$$) {
    my $self = shift;
    my $out = shift;
    my $def = shift;
    my $pkgs = shift;
    my $cb = shift;

    print "$out\n";
    foreach my $pkg (sort keys %$pkgs) {
	print "\n$pkg:\n";

	foreach my $rc (keys %{ $pkgs->{$pkg} }) {
	    &$cb($rc) if(_query("Restart $rc?", ($def ? 'N' : 'Y')) eq 'yes');
	}
    }
}

1;
