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


sub announce {
    my $self = shift;
    my $kversion = shift;
    my $kmessage = shift;

    dcres( subst('needrestart/ui-kernel_announce', 'KVERSION', $kversion) );
    dcres( subst('needrestart/ui-kernel_announce', 'KMESSAGE', $kmessage) );
    dcres( fset('needrestart/ui-kernel_announce', 'seen', 0) );
    dcres( settitle('needrestart/ui-kernel_title') );
    dcres( input('critical', 'needrestart/ui-kernel_announce') );
    dcres( go );
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

    if($r eq 'backup') {
	print STDERR "User canceled.\n";
	return;
    }

    print STDERR "User declined any service restarts.\n"
	if($#s == -1);

    # restart each selected service script
    &$cb($_) for @s;
}

1;
