# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2018 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::uCode::Intel;

use strict;
use warnings;
use NeedRestart::uCode;
use NeedRestart::Utils;
use POSIX qw(uname);
use Sort::Naturally;
use Locale::TextDomain 'needrestart';
use File::Which qw(where);

use constant {
    NRM_INTEL_HELPER => q(/usr/lib/needrestart/iucode-scan-versions),
};

my $LOGPREF = '[uCode/Intel]';

sub nr_ucode_init {
    my ($sysname, $nodename, $release, $version, $machine) = uname;
    my $is_x86 = ($machine =~ /^(i\d86|x86_64)$/);

    die "$LOGPREF Not running on x86!\n" unless($is_x86);
    die "$LOGPREF iucode-tool not available!\n" unless(where 'iucode_tool');
}

sub nr_ucode_check_real {
    my $debug = shift;
    my $ui = shift;
    my %vars;

    my $fh = nr_fork_pipe($debug, NRM_INTEL_HELPER, $debug);
    while(<$fh>) {
        if (/^iucode_tool:.+signature (0x[\da-f]+)/) {
            $vars{sig_current} = $1;
            print STDERR "$LOGPREF current signature: $1\n" if($debug);
            next;
        }

        if (/\s+\d+\/\d+: sig (0x[\da-f]+),/) {
            $vars{sig_avail} = $1;
            print STDERR "$LOGPREF available signature: $1\n" if($debug);
            next;
        }
    }
    close($fh);

    unless(exists($vars{sig_current}) && exists($vars{sig_avail})) {
        print STDERR "$LOGPREF did not get current microcode version\n" if($debug && !exists($vars{sig_current}));
        print STDERR "$LOGPREF did not get available microcode version\n" if($debug && !exists($vars{sig_avail}));
    
        return (NRM_UNKNOWN, %vars);
    }

    if($vars{sig_current} eq $vars{sig_avail}) {
        return (NRM_CURRENT, %vars);
    }

    return (NRM_OBSOLETE, %vars);
}

1;
