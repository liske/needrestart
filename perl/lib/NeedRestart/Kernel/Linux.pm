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

package NeedRestart::Kernel::Linux;

use strict;
use warnings;
use NeedRestart::Utils;
use NeedRestart::Kernel;
use NeedRestart::Strings;
use POSIX qw(uname);
use Sort::Naturally;
use Locale::TextDomain 'needrestart';
use Fcntl qw(SEEK_SET);

use constant {
    NRK_LNX_GETVER_HELPER => q(/usr/lib/needrestart/vmlinuz-get-version),
};

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_linux_version_x86
    nr_linux_version_generic
);

my $LOGPREF = '[Kernel/Linux]';

sub nr_linux_version_x86($$) {
    my $debug = shift;
    my $fn = shift;

    my $fh;
    unless(open($fh, '<', $fn)) {
	print STDERR "$LOGPREF Could not open linux image ($fn): $!\n" if($debug);
	return undef;
    }
    binmode($fh);

    my $buf;

    # get kernel_version address from header
    seek($fh, 0x20e, SEEK_SET);
    read($fh, $buf, 2);
    my $offset = unpack 'v', $buf;

    # get kernel_version string
    seek($fh, 0x200 + $offset, SEEK_SET);
    read($fh, $buf, 128);
    close($fh);

    $buf =~ s/\000.*$//;
    return undef if($buf eq '');

    unless($buf =~ /^\d+\.\d+/) {
	print STDERR "$LOGPREF Got garbage from linux image header ($fn): '$buf'\n" if($debug);
	return undef;
    }

    return ($buf, 1);
}

sub nr_linux_version_generic($$) {
    my $debug = shift;
    my $fn = shift;

    # use helper script to get version string
    if(-x NRK_LNX_GETVER_HELPER) {
	my $fh = nr_fork_pipe($debug, NRK_LNX_GETVER_HELPER, $fn, $debug);
	if($fh) {
	    my $verstr = <$fh>;
	    close($fh);

	    if($verstr) {
		chomp($verstr);
		return ($verstr, 1) ;
	    }
	}
    }
    else {
	print STDERR "$LOGPREF ".(NRK_LNX_GETVER_HELPER)." is n/a\n" if($debug);
    }

    # fallback trying filename
    $fn =~ s/[^-]*-//;
    $fn =~ s/\.img$//;
    if($fn =~ /^\d+\.\d+/) {
	print STDERR "$LOGPREF version from filename: $fn\n" if($debug);

	return ($fn, 0);
    }

    return undef;
}

sub nr_kernel_check_real {
    my $debug = shift;
    my $filter = shift;
    my $ui = shift;
    my %vars;

    my ($sysname, $nodename, $release, $version, $machine) = uname;
    my $is_x86 = ($machine =~ /^(i\d86|x86_64)$/);
    $vars{KVERSION} = $release;

    die "$LOGPREF Not running on Linux!\n" unless($sysname eq 'Linux');

    my %kfiles = map {
	$_ => 1,
    } grep {
        # whitelist kernel images
        m/$filter/;
    }
    grep {
	# filter initrd images
	(!m@^/boot/init@);
    } (</boot/vmlinu*>, </boot/*.img>, </boot/kernel*>);

    $ui->progress_prep(scalar keys %kfiles, __ 'Scanning linux images...');

    my %kernels;
    foreach my $fn (reverse nsort keys %kfiles) {
	$ui->progress_step;
	my $stat = nr_stat($fn);

	unless(defined($stat)) {
	    print STDERR "$LOGPREF could not stat(2) on $fn\n" if($debug);
	    next;
	}

	if($stat->{size} < 1000000) {
	    print STDERR "$LOGPREF $fn seems to be too small\n" if($debug);
	    next;
	}

	my $verstr;
	my $abidtc;
	if($is_x86) {
	    ($verstr, $abidtc) = nr_linux_version_x86($debug, $fn);
	}
	unless(defined($verstr)) {
	    ($verstr, $abidtc) = nr_linux_version_generic($debug, $fn);
	}
	unless(defined($verstr)) {
	    print STDERR "$LOGPREF Could not get version string from $fn.\n" if($debug);
	    next;
	}
        $vars{ABIDETECT} += $abidtc;

	my $iversion = $verstr;
	$iversion =~ s/^Linux version //;
	$iversion =~ s/\s.+$//s;
	$kernels{$iversion} = (index($verstr, $release) != -1 && index($verstr, $version) != -1);

	print STDERR "$LOGPREF $fn => $verstr [$iversion]".($kernels{$iversion} ? '*' : '')."\n" if($debug);
    }
    $ui->progress_fin;

    unless(scalar keys %kernels) {
	print STDERR "$LOGPREF Did not find any linux images.\n" if($debug);
	return (NRK_UNKNOWN, %vars);
    }

    if(-e "/etc/redhat-release" && !-e "/etc/debian_version") {
	print STDERR "$LOGPREF using RPM version sorting\n" if($debug);
	($vars{EVERSION}) = reverse sort { nr_kernel_vcmp_rpm($a, $b); } keys %kernels;
    }
    else {
	($vars{EVERSION}) = reverse sort { nr_kernel_vcmp($a, $b); } keys %kernels;
    }
    print STDERR "$LOGPREF Expected linux version: $vars{EVERSION}\n" if($debug);

    return (NRK_VERUPGRADE, %vars) if($vars{KVERSION} ne $vars{EVERSION});
    return (NRK_ABIUPGRADE, %vars) unless(!$is_x86 || $kernels{$release});
    return (NRK_NOUPGRADE, %vars);
}

1;
