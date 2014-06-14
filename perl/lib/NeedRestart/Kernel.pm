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
    NRK_UNKNOWN
    NRK_NOUPGRADE
    NRK_ABIUPGRADE
    NRK_VERUPGRADE
);

my $LOGPREF = '[Kernel]';

sub nr_kernel_check($$) {
    my $debug = shift;
    my $ui = shift;
    my %vars;

    my ($sysname, $nodename, $release, $version, $machine) = uname;
    $vars{KVERSION} = $release;

    print STDERR "$LOGPREF $sysname: kernel release $release, kernel version $version\n" if($debug);

    # autoload Kernel modules
    foreach my $module (findsubmod NeedRestart::Kernel) {
	my @ret;
	unless(eval "use $module; \@ret = ${module}::nr_kernel_check_real(\$debug, \$ui);") {
	    warn "Failed to load $module: $@" if($@ && $debug);
	}
	else {
	    return @ret;
	}
    }

    return (NRK_UNKNOWN, %vars);
}

1;
