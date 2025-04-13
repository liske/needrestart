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

package NeedRestart::CONT::machined;

use strict;
use warnings;

use parent qw(NeedRestart::CONT);
use NeedRestart qw(:cont);
use NeedRestart::Utils;

my $LOGPREF = '[machined]';

needrestart_cont_register(__PACKAGE__)
    unless($<);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{machined} = {};
    return bless $self, $class;
}

sub check {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;
    my $norestart = shift;

    # stop here if no dedicated PID namespace is used
    return 0 unless $self->in_pidns($pid);

    my $cg = nr_get_cgroup($pid);
    return 0 unless(defined($cg));

    # look for machined or systemd-nspawn cgroups
    return 0 unless($cg =~ m@^/machine\.slice/(machine)-([^.]+)\.scope(/|$)@m ||
                    $cg =~ m@^/machine\.slice/(systemd-nspawn)\@([^.]+)\.service(/|$)@);

    my $name = $2;
    my $mgr = ($1 eq "machine") ? "systemd-machined" : $1;

    unless($norestart) {
	print STDERR "$LOGPREF #$pid is part of $mgr container '$name' and should be restarted\n" if($self->{debug});

	$self->{machined}->{$name}++;
    }
    else {
	print STDERR "$LOGPREF #$pid is part of $mgr container '$name'\n" if($self->{debug});
    }

    return 1;
}

sub get {
    my $self = shift;

    return map {
	($_ => [qw(machinectl reboot), $_]);
    } keys %{ $self->{machined} };
}

1;
