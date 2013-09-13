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

sub dcres(@) {
    my ($rc, @bulk) = @_;

    if($rc != 0) {
	stop;

	die "Debconf: $bulk[0]\n";
    }

    return @bulk;
}

sub new() {
    my $class = shift;

    dcres( x_loadtemplatefile("debconf.templates") );

    return bless {}, $class;
}

sub progress_prep($$$) {
    my $self = shift;
    my ($max, $out) = @_;

    $self->SUPER::progress_prep($max, $out);

    dcres( subst('needrestart/ui-progress_title', 'OUT', $out) );
    dcres( progress('START', 0, $max, 'needrestart/ui-progress_title') );
}

sub progress_step($$) {
    my $self = shift;
    my $bin = shift;

    dcres( progress('STEP', 1) );
    dcres( subst('needrestart/ui-progress_info', 'BIN', $bin) );
    dcres( progress('INFO', 'needrestart/ui-progress_info') );
}

sub progress_fin($) {
    my $self = shift;

    dcres( progress('STOP') );

    unregister('needrestart/ui-progress_title');
    unregister('needrestart/ui-progress_info');
}


sub notice($$) {
    my $self = shift;
    my $out = shift;

#    $self->{dialog}->msgbox(title => 'Notice', text => $out);
#    $stop++;
#    dcres(0, "notice");

    stop;
}


sub query_pkgs($$$$$) {
    my $self = shift;
    my $out = shift;
    my $def = shift;
    my $pkgs = shift;
    my $cb = shift;

    # prepare checklist array
    my @l = map { my $p = $_; map { ($_) } sort keys %{ $pkgs->{$p} }} sort keys %$pkgs;

    dcres( subst('needrestart/ui-query_pkgs', 'OUT', $out) );
    dcres( subst('needrestart/ui-query_pkgs', 'PKGS', join(', ', @l)) );
    dcres( fset('needrestart/ui-query_pkgs', 'seen', 0) );
    dcres( settitle('needrestart/ui-query_pkgs_title') );
    dcres( input('critical', 'needrestart/ui-query_pkgs') );
    dcres( go );

    my ($s) = dcres(get('needrestart/ui-query_pkgs'));

    stop;

    # get selected rc script
    my @s = split(/, /, $s);

    # restart each selected RC script
    &$cb($_) for @s;
}

1;
