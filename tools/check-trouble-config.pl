#!/usr/bin/perl -w
#------------------------------------------------------------------------------
#
#  Copyright (C) 2004  Josh More
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#------------------------------------------------------------------------------

print "
Trouble-maker configuration check version 0.03
Copyright (C) 2004 by Josh More
Trouble-maker comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute it under certain conditions.
For details, see the file 'COPYING' included with this distribution.

";

#------------------------------------------------------------
# Load modules
#------------------------------------------------------------
use YAML;
use Data::Dumper;

my ($file,$dump) = @ARGV;

$/ = undef;
open(F,$file) || die "Could not load $file (r) - $!\n";
my $config = <F>;
close(F);

my $lc = 0;
for my $l (split(/\n/,$config)) {
	$lc++;
	if ($l =~ /\t/) {
		die "Tab character found at line $lc.\nYAML does not support tabs.\n";
	}
}

my $hashref = Load($config) || die "Could not load file $file - $!\n";

print "YAML Configuration OK\n\n";

if ($dump) {
	print Dumper($hashref); 
}




