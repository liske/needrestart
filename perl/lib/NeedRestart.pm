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

package NeedRestart;

use strict;
use warnings;
use Module::Find;

use constant {
    NEEDRESTART_PRIO_LOW	=> 1,
    NEEDRESTART_PRIO_MEDIUM	=> 10,
    NEEDRESTART_PRIO_HIGH	=> 100,
};

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    NEEDRESTART_PRIO_LOW
    NEEDRESTART_PRIO_MEDIUM
    NEEDRESTART_PRIO_HIGH

    needrestart_ui
);

our @EXPORT_OK = qw(
    needrestart_ui_register
    needrestart_ui_init
);

our %EXPORT_TAGS = (
    ui => [qw(
	NEEDRESTART_PRIO_LOW
	NEEDRESTART_PRIO_MEDIUM
	NEEDRESTART_PRIO_HIGH

	needrestart_ui_register
	needrestart_ui_init
    )],
);

our $VERSION = '0.3';

my %UIs;

sub needrestart_ui_register($$) {
    my $pkg = shift;
    my $prio = shift;

    $UIs{$pkg} = $prio;
}

sub needrestart_ui_init($) {
    my $debug = shift;

    # autoload IV modules
    foreach my $module (findsubmod __PACKAGE__::UI) {
	eval "use $module;";
	warn "Error loading $module: $@\n" if($@ && $debug);
    }
}

sub needrestart_ui {
    my $debug = shift;

    needrestart_ui_init($debug) unless(%UIs);
    my ($ui) = sort { $UIs{$b} <=> $UIs{$a} } keys %UIs;

    print STDERR "Using UI '$ui'...\n" if($debug);

    return $ui->new();
}

1;
