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

package NeedRestart::Kernel::kFreeBSD;

use strict;
use warnings;
use NeedRestart::Utils;
use NeedRestart::Strings;
use POSIX qw(uname);
use Sort::Naturally;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_kfreebsd_check
);

my $LOGPREF = '[Kernel/kFreeBSD]';

sub nr_kfreebsd_check($$) {
    my $debug = shift;
    my $ui = shift;

    my ($sysname, $nodename, $release, $version, $machine) = uname;

    my @kfiles = reverse nsort </boot/kfreebsd-*>;
    $ui->progress_prep(scalar @kfiles, 'Scanning kernel images...');

    my %kernels;
    foreach my $fn (@kfiles) {
	$ui->progress_step;
	my $stat = nr_stat($fn);

	if($stat->{size} < 1000000) {
	    print STDERR "$LOGPREF $fn seems to be too small\n" if($debug);
	    next;
	}

	my $verstr = nr_strings_fh($debug, qr/FreeBSD \d.+:.+/, nr_fork_pipe($debug, qw(gunzip -c), $fn));
	unless(defined($verstr)) {
	    print STDERR "$LOGPREF Could not get version string from $fn.\n" if($debug);
	    next;
	}

	my $iversion = $verstr;
	$iversion =~ s/^.*FreeBSD //;
	chomp($iversion);
	$iversion =~ s/\s.+$//;
	$kernels{$iversion} = (index($verstr, $release) != -1 && index($verstr, $version) != -1);

	print STDERR "$LOGPREF $fn => $verstr [$iversion]".($kernels{$iversion} ? '*' : '')."\n" if($debug);
    }
    $ui->progress_fin;

    return (undef, "Did not find any kernel images (/boot/kfreebsd-*)!")
	unless(scalar keys %kernels);

    my ($eversion) = reverse nsort keys %kernels;
    print STDERR "$LOGPREF Expected kernel version: $eversion\n" if($debug);

    return ($release, qq(Not running the expected kernel version $eversion.))
	if($release ne $eversion);

    return ($release, qq(Running kernel has an ABI compatible upgrade pending.))
	unless($kernels{$release});

    return ($release, undef);
}

1;
