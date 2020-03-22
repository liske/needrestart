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

package NeedRestart::Strings;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    nr_strings
    nr_strings_fh
);

my $LOGPREF = '[Strings]';

# This strings implementation has been taken from PPT 0.14:
#
# Copyright 1999 Nathan Scott Thompson <quimby at city-net dot com>
#
my $PUNCTUATION = join '\\', split //, q/`~!@#$%^&*()-+={}|[]\:";'<>?,.\//; #`
my $PRINTABLE = '\w \t' . $PUNCTUATION;
my $CHUNKSIZE = 4096;

sub nr_strings_fh($$$) {
    my $debug = shift;
    my $re = shift;
    my $fh = shift;

    binmode($fh);

    my $offset = 0;
    while ($_ or read($fh, $_, $CHUNKSIZE)) {
	$offset += length($1) if(s/^([^$PRINTABLE]+)//o);
	my $string = '';

	do {
		$string .= $1 if(s/^([$PRINTABLE]+)//o);
	} until ($_ or !read($fh, $_, $CHUNKSIZE));

	if ($string =~ /$re/) {
	    close($fh);
	    return $string;
	}

        $offset += length($string);
    }
    close($fh);

    return undef;
}

sub nr_strings($$$) {
    my $debug = shift;
    my $re = shift;
    my $fn = shift;

    my $fh;
    unless(open($fh, '<', $fn)) {
	print STDERR "$LOGPREF Could not open file ($fn): $!\n" if($debug);
	return undef;
    }

    return nr_strings_fh($debug, $re, $fh);
}

1;
