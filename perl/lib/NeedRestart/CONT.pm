# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2025 (C) Thomas Liske <thomas@fiasko-nw.net>
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

package NeedRestart::CONT;

use strict;
use warnings;
use NeedRestart::Utils;

my $LOGPREF = '[CONT]';

my $root_pidns = nr_get_pid_ns(1);
my $ptable = nr_ptable();

sub new {
    my $class = shift;
    my $debug = shift;

    die "Could not get PID namespace of #1!\n" unless(defined($root_pidns));

    return bless {
	debug => $debug,
	pidns => $root_pidns,
    }, $class;
}

sub check {
    my $self = shift;

    return 0;
}

sub get {
    my $self = shift;

    return ();
}

sub in_pidns {
    my $self = shift;
    my $pid = shift;

    my $ns = nr_get_pid_ns($pid);
    return $ns && $ns != $self->{pidns};
}

sub find_nsparent {
    my $self = shift;
    my $pid = shift;

    return undef unless(exists($ptable->{$pid}));

    my $ns = nr_get_pid_ns($ptable->{$pid}->{ppid});

    return $ptable->{$pid}->{ppid} if($ns && $ns == $self->{pidns});

    return $self->find_nsparent($ptable->{$pid}->{ppid});
}

1;
