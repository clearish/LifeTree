#!/usr/bin/perl -w

while ($line = <STDIN>) {
  if ($line =~ /^([^ ]*)( \[shape.*)$/) {
    $node = $1; $rest = $2;
    $node =~ s/[\(\)]//g;
    print "$node$rest\n";
  } else {
    $line =~ s/[\(\)]//g;
    print $line;
  }
}
