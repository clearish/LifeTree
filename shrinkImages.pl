#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

use utf8;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

if (not -d "Images.SHRUNK") { system "mkdir Images.SHRUNK"; }

@files = <Images/*.jpg>;
foreach $file (@files) {
  $file =~ s/^Images\///;
  $file =~ s/\(/\\(/;
  $file =~ s/\)/\\)/;
  # NOTE this shrinks and grows to achieve around 290x290 in AREA
  system "convert -geometry 85000@ Images/$file Images.SHRUNK/$file";

  # to ONLY shrink, try this (haven't tested)
  system "convert -resize 85000@ Images/$file Images.SHRUNK/$file";
}
