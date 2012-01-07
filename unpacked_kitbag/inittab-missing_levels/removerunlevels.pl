#!/usr/bin/perl -w
open(F,"/etc/inittab") || die "could not open /etc/inittab (r)";
open(FL,">/etc/inittab.lock") || die "could not open /etc/inittab.lock (w)";
while(<F>) {
  if ($_ =~ /^l\d:\d/) {
    print FL '#' . $_;
  } else {
    print FL $_;
  }
}
close(F);
close(FL);
rename('/etc/inittab','/tmp/problem-files/inittab.bak');
rename('/etc/inittab.lock','/etc/inittab');

