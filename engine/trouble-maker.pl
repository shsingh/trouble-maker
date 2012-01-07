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

#------------------------------------------------------------
# Load modules
#------------------------------------------------------------
use Getopt::Long;
use Archive::Tar;
use YAML qw(Load LoadFile Dump DumpFile);
use Data::Dumper;
use File::Copy;
use File::Basename;
use strict;

print "
Trouble-maker version 0.03
Copyright (C) 2004 by Josh More
Trouble-maker comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute it under certain conditions.
For details, see the file 'COPYING' included with this distribution.
";

# Check against accidental operation
my $bypass = 0;
if (!$bypass) {
	print "
This program is intended for training purposes only, and will cause system problems.\nTo proceed, type 'yes'.\n(To bypass this step, change the value of the \$bypass variable to '1')\n> ";
	my $answer = <STDIN>;
	chomp($answer);
	if ($answer ne 'yes') {
		die "Exiting.........\n";
	}
}
if ($<) {
	die "\n\nSorry, trouble-maker must be run as root.\n\n";
}




#------------------------------------------------------------
# Parse the command line options
#------------------------------------------------------------
my $os_version = '';
my $selection_mode = 'random';
my $backup_dir = '/tmp/trouble-maker/backup/';
my $rescue_dir = '/tmp/trouble-maker/rescue/';
my $kitbag = '/usr/local/trouble-maker/kitbag/';
my $result = GetOptions (
		"version=s"		=> \$os_version,			# string
		"selection=s"	=> \$selection_mode,	# string
		"backupdir=s"	=> \$backup_dir,			# string
		"rescuedir=s" => \$rescue_dir,			# string
		"kitbag=s"    => \$kitbag,					# string
	);
my $tar = Archive::Tar->new;
my %debug = (
	parse_modules => 0,
	choose_modules => 0,
	backup => 0,
	run => 0,
);
my %supported_os = (
	RHEL_3 => 1,
	Fedora_2 => 1,
	#FreeBSD_5 => 1,
	#FreeBSD_4 => 1,
	SUSE_9 => 1,
	#Slackware_10 => 1,
	#OpenServer_5 => 1,
);
my %dirs = (
	'backup' => $backup_dir,
	'rescue' => $rescue_dir,
);



#------------------------------------------------------------
# Verify the command line options
#   We remove and remake the directories to ensure that
#   they are clean before running the process.  This prevents
#   confusion from prior runs.
#------------------------------------------------------------
if (!defined($supported_os{$os_version})) {
	#TODO: in version 1.1, attempt to autodetect the system version.
	die "\n\nOperating system '$os_version' not supported.  Please use one of:\n   " .  join("\n   ",sort(keys(%supported_os))) . "\nfor the --version switch.\n\n";
}

if (($selection_mode ne 'random') && (! -e "$kitbag/$selection_mode")) {
	$selection_mode .= '.tar';
}
if (($selection_mode ne 'random') && (! -e $selection_mode) && (! -e "$kitbag/$selection_mode")) {
	die "\n\nSelection '$selection_mode' not supported.  Please use either 'random' or a valid filename for the --selection switch.\n\n";
}

if (! -d $kitbag) {
	die "\n\nNo kitbag found at $kitbag.\n";
}

for my $dir (keys(%dirs)) {
	if (! -d $dirs{$dir}) {
		# Automatically create this directory
		my $mkdir = '';
		if (substr($dirs{$dir},0,1) eq '/') {
			$mkdir = '/';
		}
		for my $d (split(/\//,$dirs{$dir})) {
			if ($d) { # Skip empty dir if path is given from /
				$mkdir .= $d . '/';
				if (! -d $mkdir) {
					mkdir($mkdir) || die "\n\n" . uc($dir) . " directory '$mkdir' does not exist or could not be created.\nPlease specify a valid $dir directory with the --$dir" . "dir switch\n\n";
				}
			}
		}
	}
	if (!rmdir($dirs{$dir})) {
		die "$dir directory not empty.  Please empty this directory before proceeding.\n";
	} else {
		if (!mkdir($dirs{$dir})) {
			die "Error adding $dirs{$dir} - $!\n";
		}
	}
}

		
#------------------------------------------------------------
# Parse the trouble modules and build an info hash
#------------------------------------------------------------
my %troubles = ();  # Nobody knows the troubles I've seen
opendir(TDIR,$kitbag) || die "Could not open $kitbag to find modules.  - $!\n";
my @troubles = grep(/^[^.]/,readdir(TDIR));
closedir(TDIR);
my @empty = ();
for my $trouble (@troubles) {
	# For faster access, we delibrately do not compress the modules
	$tar->read("$kitbag/$trouble") || die "Cannot read trouble module $kitbag/$trouble.  Maybe not a tar file.  - $!\n";
	if (my $config = $tar->get_content('config.yaml')) {
		if (my $hashref = Load($config)) {
			$hashref->{'package requirements'}->{'COMMON'} = \@empty if (!defined($hashref->{'package requirements'}->{'COMMON'}));
			$hashref->{'package requirements'}->{$os_version} = \@empty if (!defined($hashref->{'package requirements'}->{$os_version}));
			$hashref->{'system requirements'}->{'COMMON'} = \@empty if (!defined($hashref->{'system requirements'}->{'COMMON'}));
			$hashref->{'system requirements'}->{$os_version} = \@empty if (!defined($hashref->{'system requirements'}->{$os_version}));
			$troubles{$trouble} = $hashref;
			# Seems to have loaded properly
		} else {
			warn "Cannot read YAML data from config.yaml in $kitbag/$trouble. - $!";
		}
		
	} else {
		warn "Cannot read config.yaml from $kitbag/$trouble.  - $!";
	}
	$tar->clear;
}



#------------------------------------------------------------
# Optionally dump the contents of %troubles, for debugging.
#------------------------------------------------------------
warn Dumper(\%troubles) if ($debug{'parse_modules'}); 



#------------------------------------------------------------
# Module selection
#------------------------------------------------------------
my $chosen = '';
my $description_id = 0;

CHOOSE: while ( ($chosen,$description_id) = choose() ) {
	warn("CHOOSE: Checking $chosen for system suitability\n") if ($debug{'choose_modules'});
	my ($version_ok, $packages_ok, $system_ok) = (0, 0, 0);

	CHOOSE_OS: for my $allowed_version (@{ $troubles{$chosen}->{'os requirements'} }) {
		if ($allowed_version eq $os_version) {
			$version_ok = 1;
			warn("CHOOSE_OS: PASS on [$allowed_version]\n") if ($debug{'choose_modules'});
			last CHOOSE_OS;
		} else {
			warn("CHOOSE_OS: NEXT on [$allowed_version]\n") if ($debug{'choose_modules'});
		}
	}

	my @allowed_packages = ( @{ $troubles{$chosen}->{'package requirements'}->{$os_version} } , @{ $troubles{$chosen}->{'package requirements'}->{'COMMON'} } );
	if ($#allowed_packages < 0) {
		$packages_ok = 1;
	} else {
		CHOOSE_PACKAGES: for my $allowed_package (@allowed_packages) {
			if (package_ok($allowed_package)) {
				$packages_ok++;
				warn("CHOOSE_PACKAGES: PASS on [$allowed_package]\n") if ($debug{'choose_modules'});
			} else {
				$packages_ok = 0;
				warn("CHOOSE_PACKAGES: FAIL on [$allowed_package]\n") if ($debug{'choose_modules'});
				last CHOOSE_PACKAGES;
			}
		}
	}

	my @allowed_systems = ( @{ $troubles{$chosen}->{'system requirements'}->{$os_version} } , @{ $troubles{$chosen}->{'system requirements'}->{'COMMON'} } );
	if ($#allowed_systems < 0) {
		$system_ok = 1;
	} else {
		CHOOSE_SYSTEM: for my $allowed_system (@allowed_systems) {
			if (system_ok($allowed_system)) {
				$system_ok++;
				warn("CHOOSE_SYSTEM: PASS on [$allowed_system]\n") if ($debug{'choose_modules'});
			} else {
				$system_ok = 0;
				warn("CHOOSE_SYSTEM: FAIL on [$allowed_system]\n") if ($debug{'choose_modules'});
				last CHOOSE_SYSTEM;
			}
		}
	}

	if (($version_ok) && ($packages_ok) && ($system_ok)) {
		last CHOOSE;
	} else {
		warn("CHOOSE: FAIL module [$chosen] on \$version_ok,\$packages_ok,\$system_ok = [$version_ok,$packages_ok,$system_ok]\n") if ($debug{'choose_modules'});
		delete($troubles{$chosen}); # We do not want to choose this one again
	}
}

if ($chosen) {
	warn "Chose module: $chosen\n" if ($debug{'choose_modules'});
	warn Dumper(\$troubles{$chosen}) if ($debug{'parse_modules'}); 
	$tar->read("$kitbag/$chosen") || die "Cannot read trouble module $kitbag/$chosen.  Maybe not a tar file.  - $!\n";

	# Perform backups
	my @nonexistant_files = ();
	my $backup_details = '';
	if (defined($troubles{$chosen}->{'backup files'})) {
		for my $file (@{ $troubles{$chosen}->{'backup files'} }) {
			if ( (-e $file) && (! -d $file) ) {
				copy($file,$backup_dir) || warn "Could not copy $file to $backup_dir - $!" if ($debug{'backup'});
			} else {
				push(@nonexistant_files,$file);
			}
		}
	}
	if (defined($troubles{$chosen}->{'backup script'})) {
		my $bs = $troubles{$chosen}->{'backup script'};
		my $bscontent = $tar->get_content($bs) || warn "Could not get tar content for backup script: $bs - $!\n" if ($debug{'backup'});
		open(O,">$backup_dir/$bs") || warn "Could not open $backup_dir/$bs (w) - $!\n" if ($debug{'backup'});
		print O $bscontent;
		close(O);
		if (-e "$backup_dir/$bs") {
			chmod(0500,"$backup_dir/$bs") || warn "Could not change permissions on $backup_dir/$bs - $!\n";
			$/ = undef;
			#------------------------------------------------------------
			# Secure system command from Perl Cookbook, 19.6
			#------------------------------------------------------------
			die "cannot fork: $!" unless defined(my $pid = open(BACKUPPROCESS, "-|"));
			if ($pid) {
				# primary
				$backup_details = <BACKUPPROCESS>;
				close(BACKUPPROCESS);
			} else {
				exec("$backup_dir/$bs",$os_version) || warn "Cannot exec $backup_dir/$bs - $!";
			}
			$/ = "\n";
		}
	}
	open(BACKUP,">$backup_dir/BACKUP") || warn "Could not store backup details in $backup_dir/BACKUP - $!";
	print BACKUP "Files that could not be backed up:\n" . join("\n",@nonexistant_files) . "\n----------------------\n$backup_details";
	print BACKUP "\n";
	close(BACKUP);


	# Description
	my $description = "No Description Available";
	if (defined($troubles{$chosen}->{'description'}->[$description_id])) {
		$description = $troubles{$chosen}->{'description'}->[$description_id];
	}
	open(DESCRIPTION,">$rescue_dir/DESCRIPTION") || warn "Cannot open $rescue_dir/DESCRIPTION (w) - $!\n";
	print DESCRIPTION $description;
	print DESCRIPTION "\n";
	close(DESCRIPTION);


	# Details
	my $details = 'No Details Available';
	if (defined($troubles{$chosen}->{'details'})) {
		$details = $troubles{$chosen}->{'details'};
	}
	open(DETAILS,">$rescue_dir/DETAILS") || warn "Cannot open $rescue_dir/DETAILS (w) - $!\n";
	print DETAILS $details;
	print DETAILS "\n";
	close(DETAILS);


	# Check script
	if (defined($troubles{$chosen}->{'check script'})) {
		my $cs = $troubles{$chosen}->{'check script'};
		my $cscontent = $tar->get_content($cs) || warn "Could not get tar content for check script: $cs - $!\n" if ($debug{'run'});
		open(O,">$rescue_dir/CHECK") || warn "Could not open $rescue_dir/CHECK (w) - $!\n" if ($debug{'run'});
		print O $cscontent;
		close(O);
		if (-e "$rescue_dir/CHECK") {
			chmod(0500,"$rescue_dir/CHECK") || warn "Could not change permissions on $rescue_dir/CHECK - $!\n";
		}
	}


	# Trouble script
	if (defined($troubles{$chosen}->{'trouble script'})) {
		my $ts = $troubles{$chosen}->{'trouble script'};
		my $tscontent = $tar->get_content($ts) || warn "Could not get tar content for trouble script: $ts - $!\n" if ($debug{'run'});
		open(O,">$rescue_dir/TROUBLE-SCRIPT") || warn "Could not open $rescue_dir/TROUBLE-SCRIPT (w) - $!\n" if ($debug{'run'});
		print O $tscontent;
		close(O);

		if (-e "$rescue_dir/TROUBLE-SCRIPT") {
			chmod(0500,"$rescue_dir/TROUBLE-SCRIPT") || warn "Could not change permissions on $rescue_dir/TROUBLE-SCRIPT - $!\n";
			$/ = undef;
			#------------------------------------------------------------
			# Secure system command from Perl Cookbook, 19.6
			#------------------------------------------------------------
			die "cannot fork: $!" unless defined(my $pid = open(TROUBLEPROCESS, "-|"));
			if ($pid) {
				# primary
				$backup_details = <TROUBLEPROCESS>;
				close(TROUBLEPROCESS);
			} else {
				exec("$rescue_dir/TROUBLE-SCRIPT",$os_version) || warn "Cannot exec $rescue_dir/TROUBLE-SCRIPT - $!";
			}
			$/ = "\n";
		}
		print "PROBLEM:\n";
	} else {
		print "This problem is process-based, not problem-based\nPROCESS:\n";
	}
	
	print "$description\n";
	$tar->clear;

} else {
	die "Error involving module selection.  Contact the engine maintainers.\n";
}




#------------------------------------------------------------
# Subroutine: Check package
#------------------------------------------------------------
sub package_ok {
	my ($allowed_package) = @_;
	if (($os_version eq 'RHEL_3') || ($os_version eq 'Fedora_2') || ($os_version eq 'SUSE_9')) {
		# RPM based package detection - "rpm -q <package>" returns 0 if the package is installed, and 256 if it is not.
		if (system('rpm','-q',$allowed_package,'--quiet')) {
			return(0);
		} else {
			return(1);
		}
	} elsif (($os_version eq 'FreeBSD_4') || ($os_version eq 'FreeBSD_5')) {
		# ports based package detection - untested
		# Shell escapes may be an issue here, so be sure to check it under BSD
		if (system("pkg_info $allowed_package* > /dev/null 2>&1")) {
			return(0);
		} else {
			return(1);
		}
	} elsif ($os_version eq 'Slackware_10') {
		# package based package detection - untested
		opendir(SLACKPACK,"/var/adm/packages/") || die "Could not open dir /var/adm/packages/ - $!\n";
		my @slackpacks = grep(/^[^.]/,readdir(SLACKPACK));
		closedir(SLACKPACK);
		for my $slackpack (@slackpacks) {
			$slackpack =~ /(.+?)-\d/;
			if ($allowed_package =~ /$1/) {
				return(1);
			}
		}
		return(0);
	} elsif ($os_version eq 'OpenServer_5') {
		die "Package handling code for OpenServer is not yet implemented.  Please contact the engine developers.\n";
	} else {
		die "Error involving initialization of \$os_version variable [$os_version].  Contact the engine maintainers.\n";
	}
}

#------------------------------------------------------------
# Subroutine: Check system
#------------------------------------------------------------
sub system_ok {
	my ($allowed_system) = @_;
	if (($allowed_system =~ /^!/) || ($allowed_system =~ /^-/)) {
		return eval($allowed_system);
	} else {
		# If the system call runs with errors, return false, otherwise, return true
		if (system($allowed_system)) {
			return(0);
		} else {
			return(1);
		}
	}
}

#------------------------------------------------------------
# Subroutine: Choose a module
#------------------------------------------------------------
sub choose {
	my $suggested_module = '';
	my $description_id = 0;
	my $module_check = Archive::Tar->new;
	if ($selection_mode eq 'random') {
		# Yes, we are aware that rand() is not as random as could be.  However, it is nicely cross system and random enough for our purposes.  There is no reason to require yet another perl module.
		my @options = keys(%troubles);
		if ($#options + 1) {
			$suggested_module = $options[int(rand($#options + 1))];
			my @descs = @{ $troubles{$suggested_module}->{'description'} };
			return($suggested_module,int(rand($#descs + 1)));
		} else {
			die "No modules remaining for selection\n";
		}
	} elsif (-e $selection_mode) {
		if (my $arrayref = LoadFile($selection_mode)) {
			my @choices = @{$arrayref};
			ORDERED_CHOICE: for (my $t = 0; $t <= $#choices; $t++) {
				if ($choices[$t]->{'state'} eq 'ON') {
					$choices[$t]->{'state'} = 'OFF';
					DumpFile($selection_mode,\@choices);
					($suggested_module, $description_id) = ($choices[$t]->{'name'},$choices[$t]->{'description'});
					last ORDERED_CHOICE;
				}
			}
			if ($suggested_module) {
				return($suggested_module, $description_id);
			} else {
				die "No modules remaining for selection in $selection_mode\n";
			}
		} else {
			die "Error parsing $selection_mode.  Check for proper YAML syntax.  -  $!\n";
		}
	} elsif (defined($troubles{$selection_mode})) {
		my @descs = @{ $troubles{$selection_mode}->{'description'} };
    return($selection_mode,int(rand($#descs + 1)));
	} else {
		die "Error involving initialization of \$selection_mode variable [$selection_mode].  Contact the engine maintainers.\n";
	}
}
