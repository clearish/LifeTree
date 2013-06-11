#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

# use utf8;
# binmode STDIN, ':utf8';
# binmode STDOUT, ':utf8';

if (not -d "Images.NEW") { system "mkdir Images.NEW"; }

foreach $file (<HTML/*>) {
  open FILE, "<$file";
  while ($line = <FILE>) {
    if ($line =~ /thumbinner/) {
      push @thumbs, "$file:$line";
      last;
    }
  }
  close FILE;
}

foreach $line (@thumbs) {
  $line =~ /^HTML\/([^:]*):.*src=\"([^"]*)(\.[A-Za-z]*)\"/;
  $name = $1; $srcbase = $2; $srctype = $3;
  $nameSys = $name;
  $nameSys =~ s/\(/\\(/g;
  $nameSys =~ s/\)/\\)/g;

   # $srcbase =~ s/ /\\ /g; 
   # $srcbase =~ s/\(/\\(/g;
   # $srcbase =~ s/\)/\\)/g;

  $typelc = lc($srctype);

  if (not -e "Images.NEW/$name$typelc") {
    system "curl http:$srcbase$srctype > Images.NEW/$nameSys$typelc";
  }

  select(undef, undef, undef, rand(0.1)); # usleep wasn't working for some reason
}
