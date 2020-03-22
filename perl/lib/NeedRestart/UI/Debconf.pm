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

package NeedRestart::UI::Debconf;

use strict;
use warnings;

use parent qw(NeedRestart::UI);
use NeedRestart qw(:ui);
use Sort::Naturally;

use constant {
    DCTMPL => '/usr/share/needrestart/needrestart.templates',
};

BEGIN {
    die __PACKAGE__." is not supported as normal user!\n" if($<);
}

use Debconf::Client::ConfModule qw(:all);

version('2.0');
capb('backup');

needrestart_ui_register(__PACKAGE__, NEEDRESTART_PRIO_HIGH);

sub dcres(@) {
    return unless(scalar @_);

    my ($rc, @bulk) = @_;

    if($rc != 0 && $rc != 30) {
	stop;

	die "Debconf: $bulk[0]\n";
    }

    return @bulk;
}

sub new {
    my $class = shift;
    my $verbosity = shift;

    dcres( x_loadtemplatefile(DCTMPL) ) if(-r DCTMPL);

    return bless {
	verbosity => $verbosity,
    }, $class;
}

sub _announce {
    my $self = shift;
    my $templ = shift;
    my %vars = @_;

    foreach my $k (keys %vars) {
	dcres( subst($templ, $k, $vars{$k}) );
    }

    dcres( fset($templ, 'seen', 0) );
    dcres( settitle('needrestart/ui-kernel_title') );
    dcres( input('critical', $templ) );
    dcres( go );
}

sub announce_abi {
    my $self = shift;

    $self->_announce('needrestart/ui-kernel_announce_abi', @_);
}

sub announce_ver {
    my $self = shift;

    $self->_announce('needrestart/ui-kernel_announce_ver', @_);
}

sub announce_ehint {
    my $self = shift;
    my %vars = @_;
    my $templ = q(needrestart/ui-ehint_announce);

    foreach my $k (keys %vars) {
	dcres( subst($templ, $k, $vars{$k}) );
    }

    dcres( fset($templ, 'seen', 0) );
    dcres( settitle('needrestart/ui-ehint_title') );
    dcres( input('critical', $templ) );
    dcres( go );
}

sub announce_ucode {
    my $self = shift;
    my %vars = @_;
    my $templ = 'needrestart/ui-ucode_announce';

    foreach my $k (keys %vars) {
        dcres( subst($templ, $k, $vars{$k}) );
    }

    dcres( fset($templ, 'seen', 0) );
    dcres( settitle('needrestart/ui-ucode_title') );
    dcres( input('critical', $templ) );
    dcres( go );
}


sub notice {
    my $self = shift;
    my $out = shift;

    return unless($self->{verbosity});

    my $indent = ' ';
    $indent .= $1 if($out =~ /^(\s+)/);

    $self->wprint(\*STDERR, '', $indent, "$out\n");
}

sub vspace {
    my $self = shift;

    return unless($self->{verbosity});

    $self->SUPER::vspace(\*STDERR);
}


sub command {
    my $self = shift;
    my $out = shift;

    print STDERR "$out\n";
}


sub query_pkgs($$$$$$) {
    my $self = shift;
    my $out = shift;
    my $defno = shift;
    my $pkgs = shift;
    my $overrides = shift;
    my $cb = shift;

    # prepare checklist array
    my @l = nsort keys %$pkgs;

    # apply rc selection overrides
    my @selected = ();
    foreach my $pkg (@l) {
	my $found;
	foreach my $re (keys %$overrides) {
	    next unless($pkg =~ /$re/);

	    push(@selected, $pkg) if($overrides->{$re});
	    $found++;
	    last;
	}

	push(@selected, $pkg) unless($defno || $found);
    }
    dcres(set('needrestart/ui-query_pkgs', join(', ', @selected)));

    dcres( subst('needrestart/ui-query_pkgs', 'OUT', $out) );
    dcres( subst('needrestart/ui-query_pkgs', 'PKGS', join(', ', @l)) );
    dcres( fset('needrestart/ui-query_pkgs', 'seen', 0) );
    dcres( settitle('needrestart/ui-query_pkgs_title') );
    dcres( input('critical', 'needrestart/ui-query_pkgs') );
    my ($r) = dcres( go );

    my ($s) = dcres( get('needrestart/ui-query_pkgs') );

    # user has canceled
    return unless(defined($s));
    return if($r eq 'backup');

    # get selected rc.d script
    my @s = split(/, /, $s);

    $self->runcmd(sub {
	# restart each selected service script
	&$cb($_) for @s;
		  });
}

sub query_conts($$$$$$) {
    my $self = shift;
    my $out = shift;
    my $defno = shift;
    my $pkgs = shift;
    my $overrides = shift;
    my $cb = shift;

    # prepare checklist array
    my @l = nsort keys %$pkgs;

    # apply rc selection overrides
    my @selected = ();
    foreach my $pkg (@l) {
	my $found;
	foreach my $re (keys %$overrides) {
	    next unless($pkg =~ /$re/);

	    push(@selected, $pkg) if($overrides->{$re});
	    $found++;
	    last;
	}

	push(@selected, $pkg) unless($defno || $found);
    }
    dcres(set('needrestart/ui-query_conts', join(', ', @selected)));

    dcres( subst('needrestart/ui-query_conts', 'OUT', $out) );
    dcres( subst('needrestart/ui-query_conts', 'CONTS', join(', ', @l)) );
    dcres( fset('needrestart/ui-query_conts', 'seen', 0) );
    dcres( settitle('needrestart/ui-query_conts_title') );
    dcres( input('critical', 'needrestart/ui-query_conts') );
    my ($r) = dcres( go );

    my ($s) = dcres( get('needrestart/ui-query_conts') );

    # user has canceled
    return unless(defined($s));
    return if($r eq 'backup');

    # get selected rc.d script
    my @s = split(/, /, $s);

    $self->runcmd(sub {
	# restart each selected service script
	&$cb($_) for @s;
		  });
}

sub runcmd {
    my $self = shift;

    local *STDOUT;

    # Debconf kills STDOUT... try to restore it
    open(STDOUT, '> /dev/tty') || open(STDOUT, '>&2');

    $self->SUPER::runcmd(@_);

    close(STDOUT);
}

# Workaround for Debian Bug#893152
#
# Using Debconf leaks a fd to this module's source file. Since Perl seems
# not to set O_CLOEXEC the fd keeps open if the Debconf package uses fork
# to restart needrestart piped to Debconf. The FD will leak into restarted
# daemons if using Sys-V init.
foreach my $fn (</proc/self/fd/*>) {
    my $dst = readlink($fn);

    # check if the FD is the package source file
    if ($dst && ($dst eq __FILE__) && $fn =~ /\/(\d+)$/) {
        open(my $fh, "<&=", $1) || warn("$!\n");
        close($fh);
    }
}

1;
