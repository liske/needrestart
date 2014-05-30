# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::UI;

use strict;
use warnings;
use Term::ProgressBar::Simple;
use Test::MockObject;

sub new {
    my $class = shift;
    my $debug = shift;

    return bless {
	debug => $debug,
	progress => undef,
    }, $class;
}

sub progress_prep($$$$) {
    my $self = shift;
    my ($max, $out, $pass) = @_;

    unless($self->{debug}) {
	# restore terminal if required (debconf)
	unless(-t *STDIN) {
	    open($self->{fhin}, '<&', \*STDIN) || die "Can't dup stdin: $!\n";
	    open(STDIN, '< /dev/tty') || open(STDIN, '<&1');
	}
	unless(-t *STDOUT) {
	    open($self->{fhout}, '>&', \*STDOUT) || die "Can't dup stdout: $!\n";
	    open(STDOUT, '> /dev/tty') || open(STDOUT, '>&2');
	}

	$self->{progress} = Term::ProgressBar::Simple->new({
	    count => $max,
	    remove => 1,
	});
    }
    else {
        $self->{progress} = Test::MockObject->new();
        $self->{progress}->set_true('update');
        $self->{progress}->set_true('message');
    }

    $self->{progress}->message($out);
}

sub progress_step($$) {
    my $self = shift;
    my $bin = shift;

    $self->{progress}++;

    1;
}

sub progress_fin($) {
    my $self = shift;

    undef($self->{progress});

    # restore STDIN/STDOUT if required (debconf)
    open(STDIN, '<&', \*{$self->{fhin}}) || die "Can't dup stdin: $!\n"
	if($self->{fhin});
    open(STDOUT, '>&', \*{$self->{fhout}}) || die "Can't dup stdout: $!\n"
	if($self->{fhout});
}


sub announce {
}


sub notice($$) {
}


sub query_pkgs($$$$) {
}

1;
