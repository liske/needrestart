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

#
# This package is based on the result of the following paper:
#
# Security Analysis of x86 Processor Microcode
#  Daming D. Chen <ddchen@asu.edu>
#  Gail-Joon Ahn <gahn@asu.edu>
#
# https://www.dcddcc.com/docs/2014_paper_microcode.pdf
#
package NeedRestart::uCode::AMD;

use strict;
use warnings;
use NeedRestart::uCode;
use NeedRestart::Utils;
use File::Basename;
use POSIX qw(uname);
use Locale::TextDomain 'needrestart';

my $LOGPREF = '[uCode/AMD]';

sub nr_ucode_init {
    my ( $sysname, $nodename, $release, $version, $machine ) = uname;
    my $is_x86 = ( $machine =~ /^(i\d86|x86_64)$/ );

    die "$LOGPREF Not running on x86!\n" unless ($is_x86);
}

my $_ucodes;

sub _scan_ucodes {
    my $debug = shift;

    # scan AMD ucode files
    foreach my $fn (</lib/firmware/amd-ucode/microcode_*.bin>) {
        my $bn = basename( $fn, '.bin' );
        my $fh;

        unless ( open( $fh, '<:raw', $fn ) ) {
            warn "$LOGPREF Failed to open ucode source file '$fn': $!\n";
            next;
        }
        my @stat = stat($fh);

        my $fpos = read( $fh, my $buf, 12 );
        my ( $hdr_magic, $hdr_type, $hdr_size ) = unpack( 'a4VV', $buf );

        if ( $hdr_magic ne "DMA\0" ) {
            warn "$LOGPREF Invalid magic header ($hdr_magic)!\n";
            next;
        }
        if ( $hdr_type != 0 ) {
            warn "$LOGPREF Unsupported table type $hdr_type!\n";
            next;
        }

        for ( ; $fpos < $hdr_size ; ) {
            $fpos += read( $fh, $buf, 16 );
            my ( $pkg_cpuid, $pkg_errmask, $pkg_errcomp, $pkg_prid, $pkg_unk )
              = unpack( 'VVVvv', $buf );

            if ( $pkg_cpuid > 0 ) {
                $_ucodes->{cpuid}->{$pkg_cpuid} = $pkg_prid;
            }
        }

        for ( ; $fpos < $stat[7] ; ) {
            $fpos += read( $fh, $buf, 8 );
            my ( $upd_type, $upd_size ) = unpack( 'VV', $buf );

            $fpos += read( $fh, $buf, $upd_size );
            my (
                $pat_date, $pat_pid,  $pat_did,  $pat_dlen, $pat_iflg,
                $pat_dchk, $pat_ndid, $pat_sdid, $pat_prid
            ) = unpack( 'VVvCCVVVv', $buf );

            $_ucodes->{prid}->{$pat_prid} = $pat_pid;
        }
    }
}

sub nr_ucode_check_real {
    my $debug = shift;
    my $ui    = shift;
    my $info  = shift;

    # check for AMD cpu
    unless ( defined( $info->{vendor_id} )
        && $info->{vendor_id} eq 'AuthenticAMD' )
    {
        die "$LOGPREF #$info->{processor} cpu vendor id mismatch\n";
    }

    # get CPUID using kernel module
    my $cpuid;
    if ( open( my $fh, '<:raw', "/dev/cpu/$info->{processor}/cpuid" ) ) {
        seek( $fh, 1, 0 );
        read( $fh, my $eax, 16 );
        close($fh);
        $cpuid = unpack( 'V', $eax );
        printf( STDERR
              "$LOGPREF #$info->{processor} cpuid 0x%08x  (/dev/cpu/$info->{processor}/cpuid)\n",
            $cpuid
        ) if ($debug);
    }
    else {
        warn
"$LOGPREF #$info->{processor} Failed to open /dev/cpu/$info->{processor}/cpuid (Missed \`modprobe cpuid\`?): $!\n"
          if ($debug);
    }

    # get CPUID from /proc/cpuinfo
    my $family  = int( $info->{'cpu family'} );
    my $xfamily = 0;
    if ( $family > 0xf ) {
        $xfamily = $family - 0xf;
        $family  = 0xf;
    }

    my $model  = int( $info->{model} );
    my $xmodel = $model >> 4;
    $model = $model & 0xf;

    my $stepping = int( $info->{stepping} );
    my $eax =
      ( ( ( $xfamily & 0xff ) << 20 ) +
          ( ( $xmodel & 0xf ) << 16 ) +
          ( ( $family & 0xf ) << 8 ) +
          ( ( $model & 0xf ) << 4 ) +
          ( ( $stepping & 0xf ) << 0 ) );

    printf( STDERR "$LOGPREF #$info->{processor} cpuid 0x%08x  (/proc/cpuinfo)\n", $eax )
      if ($debug);

    if ($cpuid) {
        if ( $cpuid != $eax ) {
            warn "$LOGPREF #$info->{processor} CPUID mismatch detected!\n" if ($debug);
        }
    }
    else {
        $cpuid = $eax;
    }

    # get microcode version of cpu
    my $ucode = hex( $info->{microcode} );
    printf( STDERR "$LOGPREF #$info->{processor} running ucode 0x%08x\n", $ucode ) if ($debug);

    unless ( defined($_ucodes) ) {
        _scan_ucodes();
    }

    my %vars = ( CURRENT => sprintf( "0x%08x", $ucode ), );

    # check for microcode updates
    if ( exists( $_ucodes->{cpuid}->{$cpuid} ) ) {
        my $prid = $_ucodes->{cpuid}->{$cpuid};
        if ( exists( $_ucodes->{prid}->{$prid} ) ) {
            $vars{AVAIL} = sprintf( "0x%08x", $_ucodes->{prid}->{$prid} ),

              print STDERR "$LOGPREF #$info->{processor} found ucode $vars{AVAIL}\n" if ($debug);
            if ( $_ucodes->{prid}->{$prid} > $ucode ) {
                return ( NRM_OBSOLETE, %vars );
            }
        }
        else {
            print STDERR "$LOGPREF #$info->{processor} no ucode updates available\n" if ($debug);
        }
        return ( NRM_CURRENT, %vars );
    }
    else {
        print STDERR "$LOGPREF #$info->{processor} no ucode updates available\n" if ($debug);
        return ( NRM_CURRENT, %vars );
    }

    return ( NRM_UNKNOWN, %vars );
}

1;
