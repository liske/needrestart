# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2025 (C) Thomas Liske <thomas@fiasko-nw.net>
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

sub compare_ucode_versions {
    my ($debug, $processor, %vars) = @_;

    # if no firmware is available for the current CPU, that's
    # considered up to date. the rationale here is that if we warn on
    # this, we're actually going to warn for certain new CPUs that
    # have an up-to-date, built-in firmware without any update. that,
    # in turn, creates alert fatigue and makes operators more likely
    # to ignore warnings.
    unless ( exists( $vars{AVAIL} ) ) {
        print STDERR
	    "$LOGPREF #$processor did not get available microcode version\n"
	    if ( $debug );
        return NRM_CURRENT;
    }
    # from here on, there is a microcode file available
    #
    # if we can't find a microcode firmware for the current CPU,
    # *that* is a problem.
    unless ( exists( $vars{CURRENT} )  ) {
        print STDERR
            "$LOGPREF #$processor did not get current microcode version\n"
            if ( $debug);

        return NRM_UNKNOWN;
    }

    if ( hex( $vars{CURRENT} ) >= hex( $vars{AVAIL} ) ) {
        return NRM_CURRENT;
    }

    return NRM_OBSOLETE;
}

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
            my @nvars;
            eval "\@nvars = ${pkg}::nr_ucode_check_real(\$debug, \$ui, \$processors{\$pid});";
            if ( $@ ) {
                print STDERR $@
                    if ($debug);
                $ui->progress_step;
                next;
            }
            $ui->progress_step;

            my $nstate = compare_ucode_versions( $debug, $pid, @nvars );
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
