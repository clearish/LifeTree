#!/usr/bin/perl -w

# prints first occurrence of each link and node (no duplicates)
# prunes (one level of) leaves with no images (needs to be rerun for more)

$file = $ARGV[0];
open(FILE, $file);

while ($line = <FILE>) {
  if ($line =~ /^(.*) -> /) {
    $head = $1;
    $branch{$head} = 1;
  }
}

close(FILE);
open(FILE, $file);

while ($line = <FILE>) {

  # --- Links ---
  if ($line =~ /^([^ ]*) -> ([^ ]*) /) { # XXX careful whether links have attr
    push @links, $line; # process links last (after collecting hasImage info)

  # --- Nodes ---
  } elsif ($line =~ /^([^ ]*) \[shape/) {
    $node = $1; # already GV approved
    if ($line =~ /.jpg/) { $hasImage{$node} = 1; }
    print $line if (($line =~ /.jpg/ || exists $branch{$node})
      && not exists $doneNode{$node});
    $doneNode{$node} = 1;

  # --- Everything Else ---
  } else { print $line; }
}

foreach $line (@links) {
  $line =~ /^([^ ]*) -> ([^ ]*) /;
  $head = $1; $tail = $2;
  $tailGV = $tail; $tailGV =~ s/[\(\)\-\.]//g;
  print $line if ((exists $hasImage{$tail} || exists $branch{$tailGV})
    && not exists $doneLink{$head}{$tail});
  $doneLink{$head}{$tail} = 1;
}
