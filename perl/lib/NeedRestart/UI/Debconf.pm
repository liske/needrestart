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

use constant {
    DCTMPL => '/usr/share/needrestart/needrestart.templates',
};

version('2.0');
capb('backup');

needrestart_ui_register(__PACKAGE__, NEEDRESTART_PRIO_HIGH);

sub dcres(@) {
    my ($rc, @bulk) = @_;

    if($rc != 0 && $rc != 30) {
	stop;

	die "Debconf: $bulk[0]\n";
    }

    return @bulk;
}

sub new {
    my $class = shift;
    my $debug = shift;

    dcres( x_loadtemplatefile(DCTMPL) ) if(-r DCTMPL);

    return bless {
	debug => $debug
    }, $class;
}

sub _announce {
    my $self = shift;
    my $templ = shift;
    my %vars = @_;

    foreach my $k (keys %vars) {
	dcres( subst($templ, $k, $vars{$k}) );
    }

    dcres( fset($templ, 'seen', 0) );
    dcres( settitle('needrestart/ui-kernel_title') );
    dcres( input('critical', $templ) );
    dcres( go );
}

sub announce_abi {
    my $self = shift;

    $self->_announce('needrestart/ui-kernel_announce_abi', @_);
}


sub announce_ver {
    my $self = shift;

    $self->_announce('needrestart/ui-kernel_announce_ver', @_);
}


sub notice {
    my $self = shift;
    my $out = shift;

    print STDERR "$out\n";
}


sub query_pkgs($$$$$) {
    my $self = shift;
    my $out = shift;
    my $defno = shift;
    my $pkgs = shift;
    my $cb = shift;

    # prepare checklist array
    my @l = sort keys %$pkgs;

    dcres(set('needrestart/ui-query_pkgs', join(', ', ($defno ? () : @l) )));

    dcres( subst('needrestart/ui-query_pkgs', 'OUT', $out) );
    dcres( subst('needrestart/ui-query_pkgs', 'PKGS', join(', ', @l)) );
    dcres( fset('needrestart/ui-query_pkgs', 'seen', 0) );
    dcres( settitle('needrestart/ui-query_pkgs_title') );
    dcres( input('critical', 'needrestart/ui-query_pkgs') );
    my ($r) = dcres( go );

    my ($s) = dcres( get('needrestart/ui-query_pkgs') );

    stop;

    # Debconf kills STDOUT... try to restore it
    open(STDOUT, '> /dev/tty') || open(STDOUT, '>&2');

    # get selected rc.d script
    my @s = split(/, /, $s);

    # user has canceled
    return if($r eq 'backup');

    # restart each selected service script
    &$cb($_) for @s;
}

1;
