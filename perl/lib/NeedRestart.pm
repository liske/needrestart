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

package NeedRestart;

use strict;
use warnings;
use Module::Find;
use NeedRestart::Utils;
use NeedRestart::NS;
use Sort::Naturally;

use constant {
    NEEDRESTART_PRIO_LOW	=> 1,
    NEEDRESTART_PRIO_MEDIUM	=> 10,
    NEEDRESTART_PRIO_HIGH	=> 100,
};

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    NEEDRESTART_PRIO_LOW
    NEEDRESTART_PRIO_MEDIUM
    NEEDRESTART_PRIO_HIGH

    needrestart_ui
    needrestart_interp_check
    needrestart_interp_source
    needrestart_ns_check
);

our @EXPORT_OK = qw(
    needrestart_ui_register
    needrestart_ui_init
    needrestart_interp_register
    needrestart_ns_register
);

our %EXPORT_TAGS = (
    ui => [qw(
	NEEDRESTART_PRIO_LOW
	NEEDRESTART_PRIO_MEDIUM
	NEEDRESTART_PRIO_HIGH

	needrestart_ui_register
	needrestart_ui_init
    )],
    interp => [qw(
	needrestart_interp_register
    )],
    ns => [qw(
	needrestart_ns_register
    )],
);

our $VERSION = '2.1';
my $LOGPREF = '[Core]';

my %UIs;

sub needrestart_ui_register($$) {
    my $pkg = shift;
    my $prio = shift;

    $UIs{$pkg} = $prio;
}

sub needrestart_ui_init($$) {
    my $debug = shift;
    my $prefui = shift;

    # load prefered UI module
    if(defined($prefui)) {
	return if(eval "use $prefui; 1;");
    }

    # autoload UI modules
    foreach my $module (findsubmod NeedRestart::UI) {
	unless(eval "use $module; 1;") {
	    warn "Error loading $module: $@\n" if($@ && $debug);
	}
    }
}

sub needrestart_ui {
    my $debug = shift;
    my $prefui = shift;

    needrestart_ui_init($debug, $prefui) unless(%UIs);
    my ($ui) = sort { ncmp($UIs{$b}, $UIs{$a}) } keys %UIs;

    return undef unless($ui);

    print STDERR "$LOGPREF Using UI '$ui'...\n" if($debug);

    return $ui->new($debug);
}


my %Interps;
my $idebug;

sub needrestart_interp_register($) {
    my $pkg = shift;

    $Interps{$pkg} = new $pkg($idebug);
}

sub needrestart_interp_init($) {
    $idebug = shift;

    # autoload Interp modules
    foreach my $module (findsubmod NeedRestart::Interp) {
	unless(eval "use $module; 1;") {
	    warn "Error loading $module: $@\n" if($@ && $idebug);
	}
    }
}

sub needrestart_interp_check($$$) {
    my $debug = shift;
    my $pid = shift;
    my $bin = shift;

    needrestart_interp_init($debug) unless(%Interps);

    foreach my $interp (values %Interps) {
	if($interp->isa($pid, $bin)) {
	    print STDERR "$LOGPREF #$pid is a ".(ref $interp)."\n" if($debug);

	    my $ps = nr_ptable_pid($pid);
	    my %files = $interp->files($pid);

	    if(grep {!defined($_) || $_ > $ps->start} values %files) {
		if($debug) {
		    print STDERR "$LOGPREF #$pid uses obsolete script file(s):";
		    print STDERR join("\n$LOGPREF #$pid  ", '', map {(!defined($files{$_}) || $files{$_} > $ps->start ? $_ : ())} keys %files);
		    print STDERR "\n";
		}

		return 1;
	    }
	}
    }

    return 0;
}

sub needrestart_interp_source($$$) {
    my $debug = shift;
    my $pid = shift;
    my $bin = shift;

    needrestart_interp_init($debug) unless(%Interps);

    foreach my $interp (values %Interps) {
	if($interp->isa($pid, $bin)) {
	    print STDERR "$LOGPREF #$pid is a ".(ref $interp)."\n" if($debug);

	    my $src = $interp->source($pid);
	    print STDERR "$LOGPREF #$pid source is ".(defined($src) ? $src : 'UNKNOWN')."\n" if($debug);

	    return ($src) if(defined($src));;
	    return ();
	}
    }

    return ();
}


my @NS;
my $ndebug;

sub needrestart_ns_register($) {
    my $pkg = shift;

    push(@NS, new $pkg($ndebug));
}

sub needrestart_ns_init($) {
    $ndebug = shift;

    # autoload NS modules
    foreach my $module (findsubmod NeedRestart::NS) {
	unless(eval "use $module; 1;") {
	    warn "Error loading $module: $@\n" if($@ && $ndebug);
	}
    }

    push(@NS, new NeedRestart::NS($ndebug));
}

sub needrestart_ns_check($$$) {
    my $debug = shift;
    my $pid = shift;
    my $bin = shift;

    needrestart_ns_init($debug) unless(@NS);

    foreach my $ns (@NS) {
	if($ns->check($pid, $bin)) {
	    print STDERR "$LOGPREF #$pid is part of a ".(ref $ns)." domain\n" if($debug);

	    return 1;
	}
    }

    return 0;
}

1;
