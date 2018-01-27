# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2018 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::uCode;

use strict;
use warnings;
use NeedRestart::Utils;
use Module::Find;
use Locale::TextDomain 'needrestart';

use constant {
    NRM_UNKNOWN  => 0,
    NRM_CURRENT  => 1,
    NRM_OBSOLETE => 2,
};

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_ucode_check
    NRM_UNKNOWN
    NRM_CURRENT
    NRM_OBSOLETE
);

my $LOGPREF = '[ucode]';
my @PKGS;

sub nr_ucode_check {
    my $debug = shift;
    my $ui = shift;

    # autoload ucode modules
    foreach my $module (findsubmod NeedRestart::uCode) {
        unless(eval "use $module; ${module}::nr_ucode_init(\$debug);") {
            warn "Failed to load $module: $@" if($@ && $debug);
        }
        else {
	       push(@PKGS, $module);
	   }
    }

    unless(scalar @PKGS > 0) {
        print STDERR "$LOGPREF no supported processor microcode detection\n" if($debug);
        return (NRM_UNKNOWN, ());
    }

    $ui->progress_prep(scalar @PKGS, __ 'Scanning processor microcode...');

    # autoload ucode modules
    my ($state, @vars) = (NRM_UNKNOWN);
    foreach my $pkg (@PKGS) {
        eval "(\$state, \@vars) = ${pkg}::nr_ucode_check_real(\$debug, \$ui);";

        $ui->progress_step;

        if($state == NRM_OBSOLETE) {
            $ui->progress_fin;
            return ($state, @vars) 
        }
    }

    $ui->progress_fin;
    return ($state, @vars);
}

1;
