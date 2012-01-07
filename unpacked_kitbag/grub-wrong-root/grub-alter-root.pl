#!/usr/bin/perl -w

my $file = '/boot/grub/grub.conf';
if ($ARGV[0] eq 'SUSE_9') {
	$file = '/boot/grub/menu.lst';
}

open(F,"$file") || die "could not open $file (r)";
open(FL,">$file.lock") || die "could not open $file.conf.lock (w)";
while(<F>) {
  if ($_ =~ /^\s+kernel/) {
    chomp($_);
    my @l = split(/ /,$_);
    my $line = '';
    for my $i (@l) {
      if ($i =~ /^root=/) {
        $line .= $i . 'typo ';
      } else {
        $line .= $i . ' ';
      }
    }
    print FL $line . "\n";
  } else {
    print FL $_;
  }
}
close(F);
close(FL);
rename("$file.lock",$file);

