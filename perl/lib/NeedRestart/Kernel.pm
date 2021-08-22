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

package NeedRestart::Kernel;

use strict;
use warnings;
use NeedRestart::Utils;
use Module::Find;
use POSIX qw(uname);

use constant {
    NRK_UNKNOWN    => 0,
    NRK_NOUPGRADE  => 1,
    NRK_ABIUPGRADE => 2,
    NRK_VERUPGRADE => 3,
};

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_kernel_check
    nr_kernel_vcmp
    nr_kernel_vcmp_rpm
    NRK_UNKNOWN
    NRK_NOUPGRADE
    NRK_ABIUPGRADE
    NRK_VERUPGRADE
);

my $LOGPREF = '[Kernel]';

sub nr_kernel_check {
    my $debug = shift;
    my $filter = shift;
    my $ui = shift;
    my %vars;

    my ($sysname, $nodename, $release, $version, $machine) = uname;
    $vars{KVERSION} = $release;

    print STDERR "$LOGPREF $sysname: kernel release $release, kernel version $version\n" if($debug);

    # autoload Kernel modules
    foreach my $module (findsubmod NeedRestart::Kernel) {
	my @ret;
	unless(eval "use $module; \@ret = ${module}::nr_kernel_check_real(\$debug, \$filter, \$ui);") {
	    warn "Failed to load $module: $@" if($@ && $debug);
	}
	else {
	    return @ret;
	}
    }

    return (NRK_UNKNOWN, %vars);
}

## The following version number comparing stuff was taken from Dpkg::Version.
## The code has been adopted to be usable in needrestart w/o any additional
## dependencies.

sub _nr_kversion_order {
    my ($x) = @_;

    if ($x eq '~') {
        return -1;
    } elsif ($x =~ /^\d$/) {
        return $x * 1 + 1;
    } elsif ($x =~ /^[A-Za-z]$/) {
        return ord($x);
    } else {
        return ord($x) + 256;
    }
}

sub _nr_kversion_strcmp($$) {
    my @a = map { _nr_kversion_order($_); } split(//, shift);
    my @b = map { _nr_kversion_order($_); } split(//, shift);

    while (1) {
        my ($a, $b) = (shift @a, shift @b);
        return 0 unless(defined($a) || defined($b));

        $a ||= 0; # Default order for "no character"
        $b ||= 0;

        return 1 if($a > $b);
        return -1 if($a < $b);
    }
}

# compare kernel version strings according to Debian's dpkg version scheme
sub nr_kernel_vcmp($$) {
    # sort well known devel tags just as grub does
    my @v = map {
	my $v = $_;
	$v =~ s/[._-](pre|rc|test|git|old|trunk)/~$1/g;
	$v;
    } @_;

    my @a = split(/(?<=\d)(?=\D)|(?<=\D)(?=\d)/, shift(@v));
    my @b = split(/(?<=\d)(?=\D)|(?<=\D)(?=\d)/, shift(@v));

    while(1) {
	my ($a, $b) = (shift @a, shift @b);
	return 0 unless(defined($a) || defined($b));

	$a ||= 0;
	$b ||= 0;
	if($a =~ /^\d+$/ && $b =~ /^\d+$/) {
	    my $cmp = $a <=> $b;
	    return $cmp if($cmp);
	}
	else {
	    my $cmp = _nr_kversion_strcmp($a, $b);
	    return $cmp if($cmp);
	}
    }
}

# compare kernel version strings according to RPM version sorting
# adopted from RPM::VersionSort
sub nr_kernel_vcmp_rpm {
    # split version strings by non-alphanumeric digits
    my @a = split(/[^a-z\d]+/i, shift);
    my @b = split(/[^a-z\d]+/i, shift);

    while(1) {
	my ($a, $b) = (shift @a, shift @b);
	return 0 unless(defined($a) || defined($b));

	# shorter version strings looses (by equal beginning)
	return 1 unless(defined($b));
	return -1 unless(defined($a));

	# integer part wins over string part
	return 1 if($a =~ /^\d/ && $b =~ /^[a-z]/i);
	return -1 if ($a =~ /^[a-z]/i && $b =~ /^\d/);

	# compare version parts as int or string
	if($a =~ /^\d+$/) {
	    my $cmp = $a <=> $b;
	    return $cmp if($cmp);
	}
	else {
	    my $cmp = $a cmp $b;
	    return $cmp if($cmp);
	}
    }
}

1;
