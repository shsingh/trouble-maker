#!/usr/bin/perl -w
open(F,"/etc/inittab") || die "could not open /etc/inittab (r)";
open(FL,">/etc/inittab.lock") || die "could not open /etc/inittab.lock (w)";
while(<F>) {
  if ($_ =~ /^id/) {
    my @l = split(/:/,$_);
    if ( $l[1] != 5 ) {
      die "Sorry, this problem requires graphical login, please re-run.\n";
    } else {
      $l[1] = 3;
      print FL join(':',@l);
    }
  } else {
    print FL $_;
  }
}
close(F);
close(FL);
rename('/etc/inittab','/tmp/problem-files/inittab.bak');
rename('/etc/inittab.lock','/etc/inittab');
