# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2014 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::Kernel;

use strict;
use warnings;
use NeedRestart::Utils;
use NeedRestart::Strings;
use Sort::Naturally;
use Fcntl qw(SEEK_SET);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_kernel_check
    nr_kernel_version_x86
);

my $LOGPREF = '[Kernel]';

sub nr_kernel_version_x86($$) {
    my $debug = shift;
    my $fn = shift;

    my $fh;
    unless(open($fh, '<', $fn)) {
	print STDERR "$LOGPREF Could not open kernel image ($fn): $!\n" if($debug);
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
	print STDERR "$LOGPREF Got garbage from kernel image header ($fn): '$buf'\n" if($debug);
	return undef;
    }

    return $buf;
}

sub nr_kernel_check($) {
    my $debug = shift;

    my $fh;
    open($fh, '/proc/version') || return (undef, "Could not read /proc/version: $!");
    my $kverstr = <$fh>;
    close($fh);
    chomp($kverstr);
    my $kversion = $kverstr;
    $kversion =~ s/^[\D]+(\S+)\s.+$/$1/;

    print STDERR "$LOGPREF Scanning kernel images...\n$LOGPREF Running kernel version: $kversion => $kverstr\n" if($debug);

    my %kernels;
    foreach my $fn (</boot/vmlinu*>) {
	my $stat = nr_stat($fn);

	if($stat->{size} < 1000000) {
	    print STDERR "$LOGPREF $fn seems to be to small\n" if($debug);
	    next;
	}

	my $verstr = nr_kernel_version_x86($debug, $fn);
	unless(defined($verstr)) {
	    $verstr = nr_strings($debug, qr/^(Linux version )?\d\.\d+\S*\s/, $fn);

	    unless(defined($verstr)) {
		print STDERR "$LOGPREF Could not get version string from $fn.\n" if($debug);
		next;
	    }
	}

	$verstr =~ s/^Linux version //;
	chomp($verstr);
	print STDERR "$LOGPREF $fn => $verstr\n" if($debug);

	my $iversion = $verstr;
	$iversion =~ s/\s.+$//;

	$kernels{$iversion} = 1;
	foreach my $token (split(/ /, $verstr)) {
	    if(index($kverstr, $token) == -1) {
		$kernels{$iversion} = 0;
		last;
	    }
	}
    }

    return (undef, "Did not find any kernel images (/boot/vmlinu*)!")
	unless(scalar keys %kernels);

    my ($eversion) = reverse nsort keys %kernels;
    print STDERR "$LOGPREF Expected kernel version: $eversion\n" if($debug);

    return ($kversion, qq(Running kernel has a ABI compatible upgrade pending.))
	if(!exists($kernels{$kversion}));

    return ($kversion, qq(Running not the expected kernel version $eversion.))
	if($kversion ne $eversion);

    return ($kversion, undef);
}

1;
