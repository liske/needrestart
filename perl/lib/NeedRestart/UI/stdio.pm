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

package NeedRestart::UI::stdio;

use strict;
use warnings;

use parent qw(NeedRestart::UI);
use NeedRestart qw(:ui);


needrestart_ui_register(__PACKAGE__, NEEDRESTART_PRIO_LOW);

sub progress_prep($$$$) {
    my $self = shift;
    my ($max, $out, $pass) = @_;

    $|++;

    print "$out";
    print "\n" if($self->{debug});
}

sub progress_step($$) {
    my $self = shift;
    my $bin = shift;

    print '.' if($bin && !$self->{debug});
}

sub progress_fin($) {
    my $self = shift;

    print "\n" if(!$self->{debug});

    $|--;
}


sub announce {
    my $self = shift;
    my $kversion = shift;
    my $kmessage = shift;

    print "Pending kernel upgrade!\n\nRunning kernel version:\n  ${kversion}\n\nDiagnostics:\n  ${kmessage}\n\nYou should consider to reboot this machine to activate the pending kernel upgrade. You need to reboot MANUALLY! [Return]\n";
    <STDIN>;
}


sub notice($$) {
    my $self = shift;
    my $out = shift;

    print "$out\n";
}


sub _query($$) {
    my $self = shift;
    my($query, $def) = @_;
    my @def = ($def eq 'Y' ? qw(yes no all skip) : qw(no yes all skip));

    my $i;
    do {
	print "$query [", ($def eq 'Y' ? 'Ynas' : 'yNas'), '] ';
	if($self->{stdio_same}) {
	    print "$self->{stdio_same}\n";
	    return $self->{stdio_same};
	}

	$i = lc(<STDIN>);
	chomp($i);
	$i =~ s/^\s+//;
	$i =~ s/\s+$//;
    } while(!( ($i) = map { (substr($_, 0, length($i)) eq $i ? ($_) : ())} @def ));

    return ($self->{stdio_same} = 'yes') if($i eq 'all');
    return ($self->{stdio_same} = 'no') if($i eq 'skip');

    return $i;
}

sub query_pkgs($$$$$) {
    my $self = shift;
    my $out = shift;
    my $def = shift;
    my $pkgs = shift;
    my $cb = shift;

    delete($self->{stdio_same});

    print "$out\n";
    foreach my $rc (sort keys %$pkgs) {
	&$cb($rc) if($self->_query("Restart $rc?", ($def ? 'N' : 'Y')) eq 'yes');
    }
}

1;
