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
  nr_ucode_register
  NRM_UNKNOWN
  NRM_CURRENT
  NRM_OBSOLETE
);

my $LOGPREF = '[ucode]';

sub nr_ucode_check {
    my $debug = shift;
    my $ui    = shift;
    my @PKGS;

    # autoload ucode modules
    foreach my $module ( findsubmod NeedRestart::uCode ) {
        unless ( eval "use $module (); 1;" ) {
            warn "$LOGPREF Failed to load $module: $@" if ( $@ && $debug );
        }
        else {
            print STDERR "$LOGPREF using $module\n"
              if ($debug);

            push( @PKGS, $module );
        }
    }

    unless ( scalar @PKGS > 0 ) {
        print STDERR "$LOGPREF no supported processor microcode detection\n"
          if ($debug);
        return ( NRM_UNKNOWN, () );
    }

    # parse /proc/cpuinfo
    my %processors;
    my %sockels;
    {
        my $fh;
        unless ( open( $fh, '<', '/proc/cpuinfo' ) ) {
            warn "$LOGPREF Failed to read /proc/cpuinfo: $!\n"
              if ($debug);
            return ( NRM_UNKNOWN, () );
        }

        local $/ = "\n\n";

        while (<$fh>) {

            # transform key: value into hash
            my %data;
            foreach ( split(/\n+/) ) {
                $data{$1} = $2 if (/^(.+\S)\s*: (.+)$/);
            }

            if ( defined( $data{processor} ) ) {

                # save processor details
                $processors{ $data{processor} } = \%data;

                # save physical to logical mapping
                my $sockel = 0;
                if ( defined( $data{'physical id'} ) ) {
                    $sockel = $data{'physical id'};
                }
                push( @{ $sockels{$sockel} }, $data{processor} );
            }
        }
    }

    $ui->progress_prep( (scalar keys %sockels) * (scalar @PKGS),
        __ 'Scanning processor microcode...' );

    my ( $state, @vars ) = (NRM_UNKNOWN);
    foreach my $sid ( keys %sockels ) {
        my $pid = $sockels{$sid}[0];

        # call ucode modules
        foreach my $pkg (@PKGS) {
            my ( $nstate, @nvars ) = (NRM_UNKNOWN);
            eval
"(\$nstate, \@nvars) = ${pkg}::nr_ucode_check_real(\$debug, \$ui, \$processors{\$pid});";
            print STDERR $@
              if ( $@ && $debug );
            $ui->progress_step;

            if ( $nstate > $state ) {
                ( $state, @vars ) = ( $nstate, @nvars );
            }

            if ( $nstate == NRM_OBSOLETE ) {
                last;
            }
        }
    }

    $ui->progress_fin;

    return ( $state, @vars );
}

1;
