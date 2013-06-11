#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

use utf8;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

@files = <*>;
foreach $file (@files) {
  next if $file !~ /.png$/;
  $file =~ s/\.png$//;
  $file =~ s/\(/\\(/;
  $file =~ s/\)/\\)/;
  # system "convert $file.png $file.jpg";
  system "convert $file.png -background white -flatten $file.jpg";
}
