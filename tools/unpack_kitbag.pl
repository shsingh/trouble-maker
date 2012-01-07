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
print "Trouble-maker module unpacker version 0.03
Copyright (C) 2004 by Josh More
Trouble-maker comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute it under certain conditions.
For details, see the file 'COPYING' included with this distribution.

";


#------------------------------------------------------------
# Load modules
#------------------------------------------------------------
use Cwd;
my $start_dir = getcwd;

use Archive::Tar;
my $tar = Archive::Tar->new;


#------------------------------------------------------------
# Usage
#------------------------------------------------------------
if ($#ARGV != 1) {
	die "
Usage: pack_trouble.pl [packed dir] [unpacked dir]

Where the packed directory contains several module files,
and the unpacked directory is the target for the expanded trouble modules.
";
}


#------------------------------------------------------------
# Load arguments
#------------------------------------------------------------
my ($packed_dir,$unpacked_dir) = @ARGV;
if ($unpacked_dir !~ /^\//) {
	$unpacked_dir = $start_dir . '/' . $unpacked_dir;
	if (! -d $unpacked_dir) {
		die "$unpacked_dir must be a directory\n";
	}
}
if ($packed_dir !~ /^\//) {
	$packed_dir = $start_dir . '/' . $packed_dir;
	if (! -d $packed_dir) {
		die "$packed_dir must be a directory\n";
	}
}


#------------------------------------------------------------
# Parse troubles
#------------------------------------------------------------
opendir(TROUBLES,$packed_dir) || die "Could not open modules directory $packed_dir - $!\n";
my @troubles = grep(/^[^.]/,readdir(TROUBLES));
closedir(TROUBLES);


#------------------------------------------------------------
# Unpack troubles
#------------------------------------------------------------
for my $trouble (@troubles) {
	print "  unpacking $trouble\n";
	my $module = $packed_dir . '/' . $trouble;
	my $base_trouble = $trouble;
	$base_trouble =~ s/\.tar$//;
	my $unpacked_module = "$unpacked_dir/$base_trouble";
	$tar->read($module) || warn "Could not read module $module - $!\n";
	if (! -d $unpacked_module) {
		mkdir($unpacked_module) || warn "Could not create module directory $unpacked_module - $!\n";
	}
	chdir($unpacked_module);
	$tar->extract() || warn "Could not extract files from $module - $!\n";
	$tar->clear();
}
