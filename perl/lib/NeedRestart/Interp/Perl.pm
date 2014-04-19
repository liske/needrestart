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

package NeedRestart::Interp::Perl;

use strict;
use warnings;

use parent qw(NeedRestart::Interp);
use NeedRestart qw(:interp);
use NeedRestart::Utils;
use Module::ScanDeps;

needrestart_interp_register(__PACKAGE__);

sub isa {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;

    return 1 if($bin =~ m@/usr/(local/)?bin/perl@);

    return 0;
}

sub files {
    my $self = shift;
    my $pid = shift;

    my @cmdline = nr_parse_cmd($pid);
    my $src = $cmdline[1];

    my $href = scan_deps(
	files => [$src],
	recurse => 1,
    );

    return map {
	my $stat = nr_stat($href->{$_}->{file});
	$href->{$_}->{file} => ( defined($stat) ? $stat->{ctime} : undef );
    } keys %$href;
}

1;
