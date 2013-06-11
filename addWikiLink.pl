#!/usr/bin/perl -w

$prefix = "http://species.wikimedia.org/wiki";

$file = $ARGV[0];
# $fileSys = $file;
# $fileSys =~ s/\(/\\(/g;
# $fileSys =~ s/\)/\\)/g;
# $fileSys =~ s/ /\\ /g;
# $fileGV = $file;
# $fileGV =~ s/[\(\)\-\.]//g;
# $fileGV =~ s/ /_/g;

open(FILE, $file);

$length = `wc -l "$file"`;
$length =~ /^ *([0-9][0-9]*) /;
$length = $1;
if ($length == 1) {
  $line = <FILE>;
  $line =~ s/\.svg//g;
  $line =~ s/href=\"/href=\"$prefix\//g;
  print $line;
} else {
  while ($line = <FILE>) { print $line; }
}
