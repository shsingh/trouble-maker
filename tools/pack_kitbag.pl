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
print "Trouble-maker module packer version 0.03
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

use File::Basename;


#------------------------------------------------------------
# Usage
#------------------------------------------------------------
if ($#ARGV != 1) {
	die "
Usage: pack_trouble.pl [unpacked dir] [packed dir]

Where the unpacked directory contains several directories that each contain module files,
and the packed directory is the target for the new trouble modules.
";
}


#------------------------------------------------------------
# Load arguments
#------------------------------------------------------------
my ($unpacked_dir,$packed_dir) = @ARGV;
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
opendir(TROUBLES,$unpacked_dir) || die "Could not open modules directory $unpacked_dir - $!\n";
my @troubles = grep(/^[^.]/,readdir(TROUBLES));
closedir(TROUBLES);


#------------------------------------------------------------
# Pack troubles
#------------------------------------------------------------
for my $trouble (@troubles) {
	my $newdir = $unpacked_dir . '/' . $trouble;
	if (-e "$newdir/config.yaml") {
		print "  packing $trouble\n";
		opendir(PACKME,$newdir) || die "Could not open unpacked module $newdir - $!\n";
		my @packus = grep(/^[^.]/,readdir(PACKME));
		closedir(PACKME);
		chdir($newdir) || die "Could not chdir to $newdir - $!\n";
		$tar->add_files(@packus) || warn "Could not add files [" . join(',',@packus) . "] to tar - $!\n";
		$tar->write("$packed_dir/$trouble.tar") || warn "Could not write $trouble.tar - $!\n";
		$tar->clear;
	}
}
