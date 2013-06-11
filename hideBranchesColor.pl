#!/usr/bin/perl -w

use List::Util qw(min max);

# Removes images from final branch nodes (we've already pruned useless leaves)
# Makes minor adjustments to images that will actually be displayed

$file = $ARGV[0];
open(FILE, $file);

$newMargins = "0.20,-0.05";

while ($line = <FILE>) {
  if ($line =~ /^(.*) -> (.*);/) {
    $head = $1;
    $branch{$head} = 1;
  }
}

close(FILE);
open(FILE, $file);

while ($line = <FILE>) {

  # nodes with images... (image must be last attribute!)
  if ($line =~ /^(.*) (\[shape=.*),label=<<table.*table>>(.*)$/) {
    $name = $1; $restA = $2; $restB = $3;

    # --- tweak image of leaf node
    if (not exists $branch{$name}) {
      $line =~ s/\\n/ /g; # long labels under images (graphviz <br> is broken?)

      $line =~ /align="center" title="([^"]*)"/; # NOTE TWO TITLES! (this one is second)
      $title = $1;
      $length = length($title);

      # XXX COPIED from calcBests.pl!
      $title = `echo \"$title\" | fmt -14`;

      # find length of longest WORD in title
      @words = sort { length $b <=> length $a } split '\n', $title;
      $length = length($words[0]); 

      $size = 38 - ($length*1.05); # font size decreases with length
      $size += 1.5**(7-$length); # plus a boost for the shorties
      $size = max(1, int($size));
      $size = int($size * 1.3); # compromising for shrinkImages

      # ... we could restrict this to non-folders with "if ($line =~ /shape=box/)"
      $line =~ s/point-size="[^"]*"/point-size="$size"/;

      print $line;
    }

    # --- remove image from branch and reset margins
    else {
      $restA =~ s/shape=folder/shape=box/; # change now-blank folder to box
      $restA =~ s/margin="[^"]*"/margin="$newMargins"/; # different margins for branches
      $line =~ /<font[^>]*>(.*)<\/font>/; # only one font per line, <br/>
      $label = $1;
      $label =~ s/<br\/>/\\n/g;
      print "$name $restA,label=\"$label\"$restB \n";
    }

  # --- change non-image branches to be boxes, not folders
  } else {
      $line =~ s/shape=folder/shape=box/;
      $line =~ s/margin="[^"]*"/margin="$newMargins"/; # different margins for branches
      print $line; 
  }
}
