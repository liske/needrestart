# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2014 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
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

package NeedRestart::Interp::Perl;

use strict;
use warnings;

use parent qw(NeedRestart::Interp);
use Cwd;
use Getopt::Std;
use NeedRestart qw(:interp);
use NeedRestart::Utils;
use Module::ScanDeps;

needrestart_interp_register(__PACKAGE__);

sub isa {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;

    return 1 if($bin =~ m@/usr/(local/)?bin/perl@);

    return 0;
}

sub files {
    my $self = shift;
    my $pid = shift;
    my $ptable = nr_ptable_pid($pid);
    my $cwd = getcwd();
    chdir($ptable->{cwd});

    # get original ARGV
    (my $bin, local @ARGV) = nr_parse_cmd($pid);

    # eat Perl's command line options
    my %opts;
    getopt('sTtuUWXhvV:cwdt:D:pnaF:l:0:I:m:M:fC:Sx:i:eE:', \%opts);

    # extract source file
    unless($#ARGV > -1) {
	chdir($cwd);
	print STDERR "#$pid  could not get a source file, skipping\n" if($self->{debug});
	return ();
    }
    my $src = $ARGV[0];
    unless(-r $src && -f $src) {
	chdir($cwd);
	print STDERR "#$pid source file not found, skipping\n" if($self->{debug});
	print STDERR "#$pid  reduced ARGV: ".join(' ', @ARGV)."\n" if($self->{debug});
	return ();
    }

    # prepare include path environment variable
    my %e = nr_parse_env($pid);
    local %ENV;
    if(exists($e{PERL5LIB})) {
	$ENV{PERL5LIB} = $e{PERL5LIB};
    }
    elsif(exists($ENV{PERL5LIB})) {
	delete($ENV{PERL5LIB});
    }

    @Module::ScanDeps::IncludeLibs = (exists($opts{I}) ? ($opts{I}) : ());
    my $href = scan_deps(
	files => [$src],
	recurse => 1,
    );

    my %ret = map {
	my $stat = nr_stat($href->{$_}->{file});
	$href->{$_}->{file} => ( defined($stat) ? $stat->{ctime} : undef );
    } keys %$href;

    chdir($cwd);
    return %ret;
}

1;
