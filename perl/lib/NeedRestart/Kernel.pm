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
use Sort::Naturally;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_kernel_check
);

sub nr_kernel_check($) {
    my $debug = shift;

    my $fh;
    open($fh, '/proc/version') || return (undef, "Could not read /proc/version: $!");
    my $kverstr = <$fh>;
    close($fh);
    chomp($kverstr);
    my $kversion = $kverstr;
    $kversion =~ s/^[\D]+(\S+)\s.+$/$1/;

    print STDERR "Scanning kernel images\nRunning kernel version: $kversion\n" if($debug);

    my %kernels;
    foreach my $fn (</boot/vmlinu*>) {
	my $stat = nr_stat($fn);

	if($stat->{size} < 1000000) {
	    print STDERR " $fn: seems to be to small\n" if($debug);
	    next;
	}

	my $fh = nr_fork_pipe($debug, qw(strings -n 48), $fn);
        my ($verstr) = grep { /^\d\.\d+\S*\s/ } <$fh>;
	close($fh);
	chomp($verstr);
	my $iversion = $verstr;
	$iversion =~ s/\s.+$//;

#	$kernels{$iversion} = 1;
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
    print STDERR "Expected kernel version: $eversion\n" if($debug);

    return ($kversion, qq(Running kernel has a ABI compatible upgrade pending.))
	if(!exists($kernels{$kversion}));

    return ($kversion, qq(Running not the expected kernel version $eversion.))
	if($kversion ne $eversion);

    return ($kversion, undef);
}

1;
