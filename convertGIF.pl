#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

use utf8;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

@files = <*>;
foreach $file (@files) {
  next if $file !~ /.gif$/;
  $file =~ s/\.gif$//;
  $file =~ s/\(/\\(/;
  $file =~ s/\)/\\)/;
  system "convert $file.gif $file.jpg";
}
