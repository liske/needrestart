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

package NeedRestart::CONT::LXC;

use strict;
use warnings;

use parent qw(NeedRestart::CONT);
use NeedRestart qw(:cont);
use NeedRestart::Utils;

my $LOGPREF = '[LXC]';

needrestart_cont_register(__PACKAGE__)
    unless($<);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    die "Could not get NS PID of #1!\n" unless(defined($self->{nspid}));

    $self->{lxc} = {};
    $self->{lxd} = {};

    if (-d q(/snap/lxd)) {
	$self->{has_lxd} = 1;
	$self->{lxd_bin} = q(/snap/bin/lxc);
	$self->{lxd_container_path} = q(/var/snap/lxd/common/lxd/containers);
	print STDERR "$LOGPREF LXD installed via snap\n" if($self->{debug});
    } else {
	$self->{has_lxd} = -x q(/usr/bin/lxc);
	$self->{lxd_bin} = q(/usr/bin/lxc);
	$self->{lxd_container_path} = q(/var/lib/lxd/containers);
    }

    return bless $self, $class;
}

sub check {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;
    my $norestart = shift;
    my $ns = $self->get_nspid($pid);

    # stop here if no dedicated PID namespace is used
    return 0 if(!$ns || $ns == $self->{nspid});

    unless(open(FCG, qq(/proc/$pid/cgroup))) {
	print STDERR "$LOGPREF #$pid: unable to open cgroup ($!)\n" if($self->{debug});
	return 0;
    }
    my $cg;
    {
	local $/;
	$cg = <FCG>;
	close(FCG);
    }

    # look for LXC cgroups
    return unless($cg =~ /^\d+:[^:]*:\/lxc(?:.payload)?[.\/]([^\/\n]+)($|\/)/m);

    my $name = $1;
    my $type = ($self->{has_lxd} && -d qq($self->{lxd_container_path}/$name) ? 'LXD' : 'LXC');

    unless($norestart) {
	print STDERR "$LOGPREF #$pid is part of $type container '$name' and should be restarted\n" if($self->{debug});

	$self->{lc($type)}->{$name}++;
    }
    else {
	print STDERR "$LOGPREF #$pid is part of $type container '$name'\n" if($self->{debug});
    }

    return 1;
}

sub get {
    my $self = shift;

    sub lxd_restart_with_project {
	my ($bin, $container) = @_;
	my @parts = split(/_/, $container);
	if ($#parts == 1) {
	    return [ $bin, 'restart', qq(--project=$parts[0]), $parts[1] ];
	} else {
	    [ $bin, 'restart', $container ]
	}
    }

    return (map {
	($_ => [qw(lxc-stop --reboot --name), $_]);
    } keys %{ $self->{lxc} }), (map {
	($_ => lxd_restart_with_project($self->{lxd_bin}, $_));
    } keys %{ $self->{lxd} });
}

1;
