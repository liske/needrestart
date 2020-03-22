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

package NeedRestart::UI;

use strict;
use warnings;
use Text::Wrap qw(wrap);
use Term::ReadKey;

# NeedRestart::UI internals properties
# ====================================
#
# $self->{verbosity}: 1 if needrestart is in verbose mode, 0
# otherwise.
#
# $self->{progress}: if undef, disable the progress bar.  Otherwise:
#
#   $self->{progress}->{msg}: message to print (last message printed).
#
#   $self->{progress}->{count}: current progress (number of steps done
#   since the beginning).
#
#   $self->{progress}->{max}: Expected total number of steps.  If 0,
#   the bar will always be at 0.
#
# $self->{fhin}, $self->{fhout}: original stdin/stdout filehandles.
# NeedRestart::UI may change the filehandles to ensure we have a
# terminal.  The original filehandles are saved in these two
# attributes in progress_prep, and restored in progress_fin.


# my $ui = new NeedRestart::UI(VERBOSITY);
#
# VERBOSITY indicates whether needrestart is otherwise verbose (0 or
# 1).  If VERBOSITY is 1, we disable the progress indicator:
# otherwise, the output would not be nice.
sub new {
    my $class = shift;
    my $verbosity = shift;

    return bless {
	verbosity => $verbosity,
	progress => undef,
    }, $class;
}

# my $nb_columns = _get_terminal_columns(FILEHANDLE);
# e.g.: my $nb_columns = _get_terminal_columns(\*STDOUT);
# => 103
#
# This is a wrapper for GetTerminalSize to cope with Debian
# Bug#824564.
sub _get_terminal_columns {
    my ($filehandle) = @_;
    # workaround Debian Bug#824564 in Term::ReadKey: pass filehandle
    # twice
    my ($columns) = GetTerminalSize($filehandle, $filehandle);
    return $columns;
}

# my $columns = &_get_columns();
#
# Return the number of columns to use for output.
sub _get_columns {
    my $default_columns = 80;           # Sane default
    if (-t *STDOUT) {
        my ($columns) = _get_terminal_columns(\*STDOUT);

        # Cope with 0-width terminals (see Debian bug #942759).
        return $columns == 0? $default_columns: $columns;
    }
    else {
        return $default_columns;
    }
}

# $ui->wprint(FILEHANDLE, SP1, SP2, MESSAGE);
#
# Print the MESSAGE to the given FILEHANDLE, wrapping text if we can get
# the number of columns.
#
# SP1 and SP2 are resp. Text::Wrap::wrap's $initial_tab and
# $subsequent_tab.
sub wprint {
    my $self = shift;
    my $fh = shift;
    my $sp1 = shift;
    my $sp2 = shift;
    my $message = shift;

    # only wrap output if it is a terminal
    if (-t $fh) {
	my ($cols) = _get_terminal_columns($fh, $fh);
	$Text::Wrap::columns = $cols? $cols: 80;

	print $fh wrap($sp1, $sp2, $message);
    }
    else {
	print $fh "$sp1$message";
    }
}

# $ui->progress_prep(MAX, OUT);
#
# Prepare for displaying a new progress bar.
#
# Disable the progress bar if we don't have a terminal.  Restore the
# terminal if necessary.  Reset the progress counter.  Print the
# initial line.
#
# MAX: expected total number of steps.
#
# OUT: the message, e.g. "Scanning processes..."
sub progress_prep($$$) {
    my $self = shift;
    my ($max, $out) = @_;

    unless(($self->{verbosity} != 1) || !(-t *STDERR)) {
	# restore terminal if required (debconf)
	unless(-t *STDIN) {
	    open($self->{fhin}, '<&', \*STDIN) || die "Can't dup stdin: $!\n";
	    open(STDIN, '< /dev/tty') || open(STDIN, '<&1');
	}
	unless(-t *STDOUT) {
	    open($self->{fhout}, '>&', \*STDOUT) || die "Can't dup stdout: $!\n";
	    open(STDOUT, '> /dev/tty') || open(STDOUT, '>&2');
	}

	$self->{progress} = {
	    count => 0,
	    max => $max,
	};
    }
    else {
	# disable progress indicator while being verbose
	$self->{progress} = undef;
    }

    $self->_progress_msg($out);
}

# $ui->progress_step();
#
# Add one step to the progress and update the display.
sub progress_step($) {
    my $self = shift;

    return unless defined($self->{progress});

    $self->_progress_inc();

    1;
}

# $ui->progress_fin();
#
# Restore stdin/out as they were before the preparation.
sub progress_fin($) {
    my $self = shift;

    return unless defined($self->{progress});

    $self->_progress_fin();

    # restore STDIN/STDOUT if required (debconf)
    open(STDIN, '<&', \*{$self->{fhin}}) || die "Can't dup stdin: $!\n"
	if($self->{fhin});
    open(STDOUT, '>&', \*{$self->{fhout}}) || die "Can't dup stdout: $!\n"
	if($self->{fhout});
}

# $ui->_progress_msg(MESSAGE);
#
# Set the current MESSAGE and update the display.
sub _progress_msg {
    my $self = shift;

    return unless defined($self->{progress});

    $self->{progress}->{msg} = shift;
    $self->_progress_out();
}

# $ui->_progress_inc();
#
# Increase progress by one step and redisplay.
sub _progress_inc {
    my $self = shift;

    $self->{progress}->{count}++;
    $self->_progress_out();
}

# $ui->_progress_out();
#
# Print the current message and progress bar.
sub _progress_out {
    my $self = shift;

    my $msg = $self->{progress}->{msg};
    my $max = $self->{progress}->{max};
    my $count = $self->{progress}->{count};

    # The line looks like this:
    # my message [====                ]
    # <- wmsg ->..<---- wbar -------->.

    # 3 columns are preassigned (the space and the square brackets);
    # we need to split the remaining space between the message and the
    # bar itself.
    my $remaining_space = _get_columns() - 3;

    # We use 70% max of the remaining space.
    my $wmsg = int($remaining_space * 0.7);
    # Shrink if the message is actually shorter.
    $wmsg = length($msg) if(length($msg) < $wmsg);

    my $wbar = $remaining_space - $wmsg;

    my $bar = '=' x ($wbar*( $max > 0 ? $count/$max : 0 ));
    printf("%-${wmsg}s [%-${wbar}s]\r", substr($msg, 0, $wmsg), $bar);
}

# $ui->_progress_fin();
#
# Finish the progress.  Redisplay the line, removing the bar.
sub _progress_fin {
   my $self = shift;
   my $columns = _get_columns;

   $self->{progress}->{count} = 0;

   print $self->{progress}->{msg}, ' ' x ($columns - length($self->{progress}->{msg})), "\n";
}

sub announce_abi {
}


sub announce_ver {
}


sub announce_ucode {
}


sub notice($$) {
}

sub vspace {
    my $self = shift;
    my $fh = shift;

    print $fh "\n" if(defined($fh));
}

sub command() {
   my $self = shift;

   $self->notice(@_);
}


sub query_pkgs($$$$$) {
}

sub query_conts($$$$$) {
}

sub runcmd {
    my $self = shift;
    my $cb = shift;

    &$cb;
}

1;
