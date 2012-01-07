#!/usr/bin/perl -w
my $file = '/etc/hosts';
open(F,"$file") || die "could not open $file (r)";
open(FL,">$file.lock") || die "could not open $file.lock (w)";
my $hostname = `hostname`;
if ($ARGV[0] eq 'SUSE_9') {
	$hostname = `hostname -f`;
}
chomp($hostname);
while(<F>) {
        if ($_ =~ /^127.0.0.1/) {
                chomp($_);
                print FL $_ . " $hostname\n";
        } else {
                print FL $_;
        }
}
close(F);
close(FL);
rename("$file.lock","$file");
