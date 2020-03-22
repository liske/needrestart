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

package NeedRestart::UI::stdio;

use strict;
use warnings;

use parent qw(NeedRestart::UI);
use NeedRestart qw(:ui);
use Locale::TextDomain 'needrestart';

needrestart_ui_register(__PACKAGE__, NEEDRESTART_PRIO_LOW);

sub _announce {
    my $self = shift;
    my $message = shift;
    my %vars = @_;

    print "\n";
    $self->wprint(\*STDOUT, '', '', __x("Pending kernel upgrade!\n\nRunning kernel version:\n  {kversion}\n\nDiagnostics:\n  {message}\n\nRestarting the system to load the new kernel will not be handled automatically, so you should consider rebooting. [Return]\n",
					 kversion => $vars{KVERSION},
					 message => $message,
		   ));
    <STDIN> if (-t *STDIN && -t *STDOUT);
}


sub announce_abi {
    my $self = shift;
    my %vars = @_;

    $self->_announce(__ 'The currently running kernel has an ABI compatible upgrade pending.', %vars);
}


sub announce_ver {
    my $self = shift;
    my %vars = @_;

    $self->_announce(__x("The currently running kernel version is not the expected kernel version {eversion}.",
			 eversion => $vars{EVERSION},
		     ), %vars);
}


sub announce_ehint {
    my $self = shift;
    my %vars = @_;

    $self->wprint(\*STDOUT, '', '', __x(<<EHINT, ehint => $vars{EHINT}));

This system runs {ehint}. For more details, run «needrestart -m a».

You should consider rebooting!

EHINT

    <STDIN> if (-t *STDIN && -t *STDOUT);
}


sub announce_ucode {
    my $self = shift;
    my %vars = @_;

    print "\n";
    $self->wprint(\*STDOUT, '', '', __x("Pending processor microcode upgrade!\n\nDiagnostics:\n  The currently running processor microcode revision is {current} which is not the expected microcode revision {avail}.\n\nRestarting the system to load the new processor microcode will not be handled automatically, so you should consider rebooting. [Return]\n",
			 current => $vars{CURRENT},
			 avail => $vars{AVAIL},
		   ));
    <STDIN> if (-t *STDIN && -t *STDOUT);
}


sub notice($$) {
    my $self = shift;
    my $out = shift;

    return unless($self->{verbosity});

    my $indent = ' ';
    $indent .= $1 if($out =~ /^(\s+)/);

    $self->wprint(\*STDOUT, '', $indent, "$out\n");
}

sub vspace {
    my $self = shift;

    return unless($self->{verbosity});

    $self->SUPER::vspace(\*STDOUT);
}


sub command {
    my $self = shift;
    my $out = shift;

    print "$out\n";
}


sub _query($$) {
    my $self = shift;
    my($query, $def) = @_;
    my @def = ($def eq 'Y' ? qw(yes no auto stop) : qw(no yes auto stop));

    my $i;
    do {
	$self->wprint(\*STDOUT, '', '', "$query [" . ($def eq 'Y' ? 'Ynas?' : 'yNas?') . '] ');
	if($self->{stdio_same}) {
	    my $s = $self->{stdio_same};
	    if($s eq 'auto') {
		$s = ($def eq 'Y' ? 'yes' : 'no');
	    }

	    print __($s), "\n";
	    return $s;
	}

	$i = <STDIN> if(-t *STDIN && -t *STDOUT);
	unless(defined($i)) {
	    $i = 'n';
	    last;
	}
	$i = lc($i);
	chomp($i);
	$i =~ s/^\s+//;
	$i =~ s/\s+$//;

	if($i eq '?') {
	    $self->wprint(\*STDOUT, '', '', __ <<HLP);
  (Y)es  - restart this service
  (N)o   - do not restart this service
  (A)uto - auto restart all remaining services
  (S)top - stop restarting services

HLP
	}
    } while(!( ($i) = map { (substr($_, 0, length($i)) eq $i ? ($_) : ())} @def ));

    if($i eq 'auto') {
	$self->{stdio_same} = 'auto';
	return ($def eq 'Y' ? q(yes) : q(no));
    }
    return ($self->{stdio_same} = 'no') if($i eq 'stop');

    return $i;
}

sub query_pkgs($$$$$$) {
    my $self = shift;
    my $out = shift;
    my $def = shift;
    my $pkgs = shift;
    my $overrides = shift;
    my $cb = shift;

    delete($self->{stdio_same});

    $self->wprint(\*STDOUT, '', '', "$out\n");
    foreach my $rc (sort keys %$pkgs) {
	my ($or) = grep { $rc =~ /$_/; } keys %$overrides;
	my $d = (defined($or) ? ($overrides->{$or} ? 'Y' : 'N') : ($def ? 'N' : 'Y'));

	&$cb($rc) if($self->_query(__x('Restart «{rc}»?', rc => $rc), $d) eq 'yes');
    }
}

sub query_conts($$$$$$) {
    my $self = shift;

    $self->query_pkgs(@_);
}

1;
