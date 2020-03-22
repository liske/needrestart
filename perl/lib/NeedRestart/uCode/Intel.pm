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

package NeedRestart::uCode::Intel;

use strict;
use warnings;
use NeedRestart::uCode;
use NeedRestart::Utils;
use POSIX qw(uname);
use Locale::TextDomain 'needrestart';

use constant { NRM_INTEL_HELPER => q(/usr/lib/needrestart/iucode-scan-versions),
};

my $LOGPREF = '[uCode/Intel]';

sub nr_ucode_init {
    my ( $sysname, $nodename, $release, $version, $machine ) = uname;
    my $is_x86 = ( $machine =~ /^(i\d86|x86_64)$/ );

    die "$LOGPREF Not running on x86!\n" unless ($is_x86);
    die "$LOGPREF iucode-tool not available!\n" unless (`which iucode_tool`);
}

my $_avail;

sub nr_ucode_check_real {
    my $debug = shift;
    my $ui    = shift;
    my $info  = shift;
    my %vars;

    # get current microcode revision
    if ( defined( $info->{microcode} ) ) {
        $vars{CURRENT} = sprintf( "0x%04x", hex( $info->{microcode} ) );
        print STDERR
          "$LOGPREF #$info->{processor} current revision: $vars{CURRENT}\n"
          if ($debug);
    }
    else {
        print STDERR
"$LOGPREF #$info->{processor} current microcode revision not found in /proc/cpuinfo: $!\n"
          if ($debug);

        return ( NRM_UNKNOWN, %vars );
    }

    # find and cache microcode updates
    unless ( defined($_avail) ) {
        my $fh = nr_fork_pipe( $debug, NRM_INTEL_HELPER, $debug );
        while (<$fh>) {
            if (/\s*\d+(\/\d+)?: sig.+, rev (0x[\da-f]+),/) {
                $_avail = sprintf( "0x%04x", hex($2) );
                print STDERR
                  "$LOGPREF #$info->{processor} available revision: $2\n"
                  if ($debug);
                next;
            }
        }
        close($fh);
    }
    $vars{AVAIL} = $_avail if ( defined($_avail) );

    unless ( exists( $vars{CURRENT} ) && exists( $vars{AVAIL} ) ) {
        print STDERR
          "$LOGPREF #$info->{processor} did not get current microcode version\n"
          if ( $debug && !exists( $vars{CURRENT} ) );
        print STDERR
"$LOGPREF #$info->{processor} did not get available microcode version\n"
          if ( $debug && !exists( $vars{AVAIL} ) );

        return ( NRM_UNKNOWN, %vars );
    }

    if ( hex( $vars{CURRENT} ) >= hex( $vars{AVAIL} ) ) {
        return ( NRM_CURRENT, %vars );
    }

    return ( NRM_OBSOLETE, %vars );
}

1;
