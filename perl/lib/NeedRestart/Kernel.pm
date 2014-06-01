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
use POSIX qw(uname);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_kernel_check
);

my $LOGPREF = '[Kernel]';

sub nr_kernel_check($$) {
    my $debug = shift;
    my $ui = shift;

    my ($sysname, $nodename, $release, $version, $machine) = uname;
    print STDERR "$LOGPREF Running kernel release $release, kernel version $version\n" if($debug);

    if($sysname eq 'Linux') {
	require NeedRestart::Kernel::Linux;
	return NeedRestart::Kernel::Linux::nr_linux_check($debug, $ui);
    }
    elsif($sysname eq 'GNU/kFreeBSD') {
	require NeedRestart::Kernel::kFreeBSD;
	return NeedRestart::Kernel::kFreeBSD::nr_kfreebsd_check($debug, $ui);
    }

    return (undef, "Running on unknown $sysname kernel.");
}

1;
