#!/usr/bin/perl -w

@files = <SVG/*.svg>;

foreach $file (@files) {
  open IN, "<$file";
  open OUT, ">$file.clean";
  $i = 0;
  foreach $line (<IN>) {
    $i++;
    if ($i <= 10) { print OUT $line; } # preserve first 10 lines
    else {
      $line =~ s/^<!--.*-->$//g; # remove comments
      $line =~ s/([0-9])\.[0-9]*/$1/g; # get rid of all decimals
      # $line =~ s/([0-9]\.[0-9])[0-9]*/$1/g; # get rid of decimal after one
      print OUT $line;
    }
  }
  close IN;
  close OUT;
  system "mv \"$file.clean\" \"$file\"";
}
