#!/usr/bin/perl -w

# This script converts a tree (in the form of a list of links) into .json
# data that could be read in by D3.js for example.

# For example:
# ./jsonify.pl Caniformia < PRUNED.txt

$root = $ARGV[0];

while ($line = <STDIN>) {
  $line =~ /^(.*) -> (.*)$/;
  $head = $1;
  $tail = $2;
  push @{$tails{$head}}, $tail;
}

sub jsonify {
  my $node = $_[0];
  my $depth = $_[1];

  $tab = "";
  for (0 .. $depth) { $tab .= "   "; }
  print "$tab {\"name\": \"$node\"";

  if (exists $tails{$node}) {
    my $length = @{$tails{$node}};

    my $i = 0;
    for $daughter ( @{$tails{$node}} ) {
      if ($i == 0) { print ", \"children\": [\n"; }
      &jsonify ($daughter, $depth+1);
 
      if ($i == $length-1) { print " ]\n"; }
      else { print ",\n"; }
      $i++;
    }
  } else {
    # $size = 100 * (8-$depth);
    # if ($size < 200) { $size = 200; }
    $size = 300;
    print ",\"size\": $size";
  }

  print " }";
}

&jsonify($root, 0);
