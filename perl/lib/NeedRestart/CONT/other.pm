# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2022 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::CONT::other;

use strict;
use warnings;

use parent qw(NeedRestart::CONT);
use NeedRestart qw(:cont);
use NeedRestart::Utils;

my $LOGPREF = '[other]';

needrestart_cont_register_fallback(__PACKAGE__)
    unless($<);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    return bless $self, $class;
}

sub check {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;
    my $norestart = shift;

    # stop here if no dedicated PID namespace is used
    return 0 unless $self->in_pidns($pid);

    print STDERR "$LOGPREF #$pid is part of a PID namespace and will be ignored\n" if($self->{debug});

    return 1;
}

sub get {
    my $self = shift;

    return ();
}

1;
