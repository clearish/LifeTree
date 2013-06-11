#!/usr/bin/perl -w

# Supplements edges with weights according to how far from a leaf we are.

use List::Util qw(min max);

$file = $ARGV[0];
$fileSys = $file;
$fileSys =~ s/\(/\\(/g;
$fileSys =~ s/\)/\\)/g;

# don't weight very small graphs
$length = `wc -l $fileSys`;
$length =~ /^ *([0-9][0-9]*) /;
$length = $1;
if ($length < 80) {
  open(FILE, $file);
  while ($line = <FILE>) { print $line; } 
  exit;
}

$input = ".addingWeights.$file.in";
$output = ".addingWeights.$file.out";
$inputSys = ".addingWeights.$fileSys.in";
$outputSys = ".addingWeights.$fileSys.out";
system "grep \"\\->\" $fileSys > $outputSys"; # gather only links

open(WEIGHTS, ">.addingWeights");

# WORKING
# @lens = (0,1,1.5,2,3,4,5,6,7,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9);
# @lens = (0,1,1.1,1.2,1.3,2,3,4,5,6,7,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9);

# MORE CONSERVATIVE
# @lens = (1,1.5,2,3,4,4.5,5,5.3,5.6,5.9,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6);

# EVEN MORE...
# @lens = (2,3,4,4.5,5,5.3,5.6,5.9,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6);

# JUST A THOUGHT
@lens = (1,2,4,6,4,2,1.5,1.3,1.2,1.1,1.05,1.02,1.01,1.009,1.008,1.007,1.006,1.005,1.004,1.003,1.002,1.001,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);

$count = 0;
$continue = 1;

while ($continue) {

  $continue = 0;

  # 1, 2, 2.5, 2.9, 3, 3, 3
  # if ($count == 0) { $count = 1; }
  # else { $count = min($count + (1/$count),3); }

  $count++;

  system "mv $outputSys $inputSys";

  open(INPUT, $input);
  open(OUTPUT, ">$output");

  for (keys %branch) { $branch{$_} = 0; }

  # distinguish branches from leaves
  while ($line = <INPUT>) {
    if ($line =~ /^(.*) -> /) {
      $head = $1;
      $branch{$head} = 1;
    }
  }

  close(INPUT);
  open(INPUT, $input);

  while ($line = <INPUT>) {

    $line =~ /-> ([^ ]*) /; # XXX breaks on edges without attributes!
    $tail = $1;

    if ($branch{$tail}) {
      print OUTPUT $line; # --- save for later
    } else {
      $len=$lens[$count];
      $line =~ s/\];/,len=$len];/; # XXX again, only for edges with attrs
      print WEIGHTS $line; # --- write out leaf with weight
      $continue = 1;
    }
  }

  close(INPUT);
}

open(FILE, $file);

while ($line = <FILE>) {
  
  if ($line =~ /->/) {
    $line =~ s/ \[.*\];\n//;
    print `grep \"^$line \" .addingWeights`;
  } else { print $line; }
}

# system "rm $inputSys $outputSys .addingWeights";
