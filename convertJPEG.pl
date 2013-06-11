#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

use utf8;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

@files = <*>;
foreach $file (@files) {
  next if $file !~ /.jpeg$/;
  $file =~ s/\.jpeg$//;
  $file =~ s/\(/\\(/;
  $file =~ s/\)/\\)/;
  system "mv $file.jpeg $file.jpg";
}
