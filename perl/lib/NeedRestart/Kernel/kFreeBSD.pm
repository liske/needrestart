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

package NeedRestart::Kernel::kFreeBSD;

use strict;
use warnings;
use NeedRestart::Utils;
use NeedRestart::Kernel;
use NeedRestart::Strings;
use POSIX qw(uname);
use Sort::Naturally;
use Locale::TextDomain 'needrestart';

my $LOGPREF = '[Kernel/kFreeBSD]';

sub nr_kernel_check_real {
    my $debug = shift;
    my $filter = shift;
    my $ui = shift;
    my %vars;

    my ($sysname, $nodename, $release, $version, $machine) = uname;
    $vars{KVERSION} = $release;

    die "$LOGPREF Not running on GNU/kFreeBSD!\n" unless($sysname eq 'GNU/kFreeBSD');

    my @kfiles = grep {m/$filter/;} reverse nsort </boot/kfreebsd-*>;
    $ui->progress_prep(scalar @kfiles, __ 'Scanning kfreebsd images...');

    my %kernels;
    foreach my $fn (@kfiles) {
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

	my $verstr = nr_strings_fh($debug, qr/FreeBSD \d.+:.+/, nr_fork_pipe($debug, qw(gunzip -c), $fn));
	unless(defined($verstr)) {
	    print STDERR "$LOGPREF Could not get version string from $fn.\n" if($debug);
	    next;
	}

	my $iversion = $verstr;
	$iversion =~ s/^.*FreeBSD //;
	chomp($iversion);
	$iversion =~ s/\s.+$//;
	$verstr =~ s/(#\d+):/$1/;
	$kernels{$iversion} = (index($verstr, $release) != -1 && index($verstr, $version) != -1);

	print STDERR "$LOGPREF $fn => $verstr [$iversion]".($kernels{$iversion} ? '*' : '')."\n" if($debug);
    }
    $ui->progress_fin;

    unless(scalar keys %kernels) {
	print STDERR "$LOGPREF Did not find any kfreebsd images (/boot/kfreebsd-*)!\n" if($debug);
	return (NRK_UNKNOWN, %vars);
    }

    ($vars{EVERSION}) = reverse sort { nr_kernel_vcmp($a, $b); } keys %kernels;
    print STDERR "$LOGPREF Expected kfreebsd version: $vars{EVERSION}\n" if($debug);

    return (NRK_VERUPGRADE, %vars) if($vars{KVERSION} ne $vars{EVERSION});
    return (NRK_ABIUPGRADE, %vars) unless($kernels{$release});
    return (NRK_NOUPGRADE, %vars);
}

1;
