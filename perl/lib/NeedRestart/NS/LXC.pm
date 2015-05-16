# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2015 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::NS::LXC;

use strict;
use warnings;

use parent qw(NeedRestart::NS);
use Getopt::Std;
use NeedRestart qw(:ns);
use NeedRestart::Utils;

my $LOGPREF = '[LXC]';

needrestart_ns_register(__PACKAGE__);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{lxc} = {};
    return bless $self, $class;
}

sub check {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;
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
    return 0 unless($cg =~ /^\d+:[^:]+:\/lxc\/(.+)$/m);

    my $name = $1;
    print STDERR "$LOGPREF #$pid is part of LXC container '$name'\n" if($self->{debug});

    return 1 if(exists($self->{lxc}->{$name}));
    
    # get parent outside the ns pid
    my $ppid = $self->find_nsparent($pid);

    # stop here if no parent has been found or is #1
    return 0 unless(!$ppid || $ppid != 1);

    print STDERR "$LOGPREF #${pid}'s ns pid parent is #$ppid\n" if($self->{debug});
    
    # get original ARGV
    (my $pbin, local @ARGV) = nr_parse_cmd($ppid);

    # parse command line options
    #my %opts;
    #qgetopts('sTtuUWXhvV:cwdt:D:pnaF:l:0:I:m:M:fC:Sx:i:eE:', \%opts);

    $self->{lxc}->{$name} = \@ARGV;

    return 1;
}

1;
