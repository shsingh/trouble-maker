#!/usr/bin/perl -w
my $file = '/etc/sysconfig/network';
my $data = '';

if (($ARGV[0] =~ 'RHEL') || ($ARGV[0] =~ 'Fedora')) {
	open(F,"$file") || die "could not open $file (r)";
	while(<F>) {
  	if ($_ =~ /^NETWORKING=/) {
    	$data .= "NETWORKING=no\n";
  	} else {
    	$data .= $_;
  	}
	}
	close(F);
	
	open(FL,">$file") || die "could not open $file (w)";
	print FL $data;
	close(FL);
	}
