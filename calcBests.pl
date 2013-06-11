#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

# use utf8;
# binmode STDIN, ':utf8';
# binmode STDOUT, ':utf8';

$directory = ".";

$graphSize = 170;

$inputNode = $ARGV[0];

%printables = ();
%doneBest = ();

open NAMES, "NAMES.txt";
while ($line = <NAMES>) {
  $line =~ /(^.*) = (.*)$/;
  $formal = $1;
  $common = $2;
  # $formal =~ s/†//g;
  # $common =~ s/†//g;
  $formal =~ s/ /_/g;
  $common{$formal} = $common unless $common eq "";
}

open DEAD, "DEAD.txt";
while ($line = <DEAD>) {
  chomp($line);
  $dead{$line} = 1;
}

#while ($line = <STDIN>) {
#  $line =~ /^(.*) -> (.*)$/;
#  $head = $1;
#  $tailsString = $2;
#  $tailsString =~ s/†//g; # XXX
#  foreach $tail ($tailsString =~ m/{([^}]*)}/g) {
#    push @{$tails{$head}}, $tail;
#    push @{$heads{$tail}}, $head;
#    $fromTo{$head}{$tail} = 1;
#  }
#}

while ($line = <STDIN>) {
  $line =~ /^(.*) -> (.*)$/;
  $head = $1; $tail = $2;
  # $headBare = $head; $headBare =~ s/†//g; $dead{$headBare} = 1 if $head =~ /†/;
  # $tailBare = $tail; $tailBare =~ s/†//g; $dead{$tailBare} = 1 if $tail =~ /†/;
  push @{$tails{$head}}, $tail;
}

# for $key (keys %tails) { foreach $tail ( @{$tails{$key}} ) { print "$key: $tail\n"; } }

%depth = ();

sub calcImages {
  my $node = $_[0];
  return if exists $deepImage{$node}; # avoid infinite loops
  $deepImage{$node} = 0;
  foreach $daughter ( @{$tails{$node}} ) {
    &calcImages($daughter);
    if ($deepImage{$daughter}) { $deepImage{$node} = 1; }
  }
  $imageFile = "Images/$node.jpg";
  $imageFile =~ s/ /_/g;
  # $imageFile =~ s/\(/\\(/g; # this was here in an apparently working version,
  # $imageFile =~ s/\)/\\)/g; # but must be wrong
  $deepImage{$node} = 1 if -e "$imageFile";
  $hasImage{$node} = 1 if -e "$imageFile";
}

sub calcDepths {
  my($node, $depth) = ($_[0], $_[1]);
  return if exists $depth{$node};
  $depth{$node} = $depth;
  foreach $daughter ( @{$tails{$node}} ) { &calcDepths($daughter, $depth+1); }
}

sub calcSizes {
  my $node = $_[0];
  return if exists $size{$node}; # avoid infinite loops
  $size{$node} = 1;
  foreach $daughter ( @{$tails{$node}} ) {
    &calcSizes($daughter);
    $size{$node} += $size{$daughter};
  }
  # print "$size{$node}: $node\n";
}

sub calcRanks {
  my ($node, $motherRank) = ($_[0], $_[1]);
  return if exists $rank{$node}; # avoid infinite loops
  $rank{$node} = sprintf "%.2f", (1.5 * $size{$node} + $motherRank) / 2.5;
  # print "$rank{$node}: $node\n";
  foreach $daughter (@{$tails{$node}}) { &calcRanks($daughter, $rank{$node}); }
}

# this algorithm is simpler to implement but maybe slower than
# repeatedly popping the best daughter's best
sub calcBests {
  my $node = $_[0];
  my $numBests = $_[1];
  # print STDERR "Running calcBests($node)\n"; # good to see where the infinite loops are
  return if exists $doneBest{$node}; # avoid infinite loops
  $doneBest{$node} = 1;
  foreach $daughter (@{$tails{$node}}) { &calcBests($daughter, $numBests); }
  @allBests = (); # will store all daughter's bests, plus daughters
  foreach $daughter (@{$tails{$node}}) {
    push @allBests, $daughter if $deepImage{$daughter};
    push @allBests, @{$bests{$daughter}};
  }
  @sorted = sort { $rank{$b} <=> $rank{$a} } @allBests; # sort by decreasing rank
  splice @sorted, $numBests if @sorted > $numBests; # truncate to $numBest elements
  @{$bests{$node}} = @sorted; # wrong?

  # print "†" if exists $dead{$node};
  # print "$node ->"; 
  # foreach $best (@{$bests{$node}}) {
  #   $printBest = $best;
  #   $printBest = "†" . $printBest if exists $dead{$best};
  #   print " {$printBest|$rank{$best}}";
  # }
  # print "\n";
}

# returns a reasonable filename for a node name (as output by pruneLinks.pl)
# node, this CAN contain parens, dots, dashes
sub cleanFilename {
  my $name = $_[0];
  $name =~ s/ +/_/g;
  $name =~ s/×_*/X_/g;
  $name =~ s/’/_quo_/g;
  $name =~ s/,/_com_/g;
  $name =~ s/&/_amp_/g;
  $name =~ s/[^A-Za-z0-9()_.\-]+/_x_/g; # replace anything else with _x_ (will collapse different names!)
  return $name;
}

sub printGraph {
  my $node = $_[0];
  my $root = $_[1];
  my $R = $_[2]; # color R-value of parent
  my $G = $_[3]; # color G-value of parent
  my $B = $_[4]; # color B-value of parent

  # print STDERR "Called printGraph($node, [";
  # foreach $able (keys %printables) { print STDERR "$able "; }
  # print STDERR "]\n";

  # my $best = $rank{$node};
  # my @myBests = @{$bests{$node}};
  # my $worstNode = $myBests[-1];
  # my $worst = $rank{$worstNode}; # the lowest-rank descendant we'll be printing
  # my $depthFact = $worst / $best;

  my $depthFactOrig = $rank{$root} / ($rank{$node}+1);
  # $depthFact += (2000 / ($size{$root}+1)**2);
  print STDERR "$node -- depthFact:$depthFactOrig, size:$size{$node}\n";

  my $depthFact = $depthFactOrig + min(1.8, 250/($size{$root}+1)); # increase depth of small graphs

  # periods and dashes are important in species names but not allowed in
  # graphviz.  Change them to _dot_ and _dash_
  my $nodeGV = $node;
  $nodeGV =~ s/[\(\)]//g; # hopefully resulting in no clashes
  $nodeGV =~ s/^([0-9])/Num_$1/g;
  $nodeGV =~ s/\./_dot_/g;
  $nodeGV =~ s/-/_dash_/g;
  $nodeGV =~ s/\//_slash_/g;
  $nodeGV =~ s/,/_comma_/g;
  $nodeGV =~ s/__/_/g; # graphviz can't handle this
  $nodeGV =~ s/_$//g;  # or this
  $nodeGV =~ s/&//g;   # or this
  $nodeGV =~ s/;//g;   # for safe measure

  # shouldn't have any spaces at this point
  # $nodeGV =~ s/ /_/g; # ... not understanding why anymore...

  # --- Color Shift code went here ---

  my $offset = 0;
  my $lightness = ($R + $G + $B) * (100/255) / 3; # 0-100
  if ($lightness < 20) { $offset = 20 - $lightness; }
  # $offset = (50 - $darkness); # avoid both poles
  # $offset = $offset + 2; # but bias towards the light
  $offset = $offset * 1.5; # a good factor to adjust for lightness control

  $R = max(20,min(int($R + $offset), 230));
  $G = max(20,min(int($G + $offset), 230));
  $B = max(20,min(int($B + $offset), 230));

  # and then save to hex string
  my $color = sprintf ("\#%2.2X%2.2X%2.2X", $R, $G, $B);
  # $color = "#888888";

  my $fraction = $size{$node} / ($size{$root}+1);

  my $printR = int($R * (1-$fraction**0.9));
  my $printG = int($G * (1-$fraction**0.9));
  my $printB = int($B * (1-$fraction**0.9));

  my $nodeColor = sprintf ("\#%2.2X%2.2X%2.2X", $printR, $printG, $printB);
  my $edgeColor = $nodeColor;

  # my $nodeColor = $edgeColor = "#888888";
  # $edgeWidth = 10;

  # my $edgeWidth = max(1,35-(15*$depthFact**0.7))+8;
  # $edgeWidth -= max(1, 20 / ($size{$root}+1));

  foreach $daughter (@{$tails{$node}}) {
    if (exists $printables{$daughter}) {

      # Adjust Color Here

      my $factor = 2.9;
      $factor += min(5,50/$size{$node});

      my $shift = 2**max(0,10-(($depthFactOrig*$factor)**0.80)); # control degree of color shift
      # $shift += 3*($fraction**4); # shift more if we're a large percentage of the graph?

      if ($shift < 20) {
        # randomly CHANGE, don't randomly stay the same
        # random numbers either between 0.5 and 1, or else between -0.5 to -1
        $randR = rand(1)-0.5; $randR = $randR > 0 ? $randR + 0.5 : $randR - 0.5;
        $randG = rand(1)-0.5; $randG = $randG > 0 ? $randG + 0.5 : $randG - 0.5;
        $randB = rand(1)-0.5; $randB = $randB > 0 ? $randB + 0.5 : $randB - 0.5;
      } else { # if shift is large, we want the option of one of R G B NOT moving
        $randR = rand(2)-1;
        $randG = rand(2)-1;
        $randB = rand(2)-1;
      }

      $nextR = max(20,min($R + int($randR*$shift),230)); # 30, 255
      $nextG = max(20,min($G + int($randG*$shift),230));
      $nextB = max(20,min($B + int($randB*$shift),230));

      # if ($size{$node} + $size{$daughter} > $size{$root}) { $len = 1.01; }
      # else { $len = 0.99; }

      my $daughtDepth = $rank{$root} / ($rank{$daughter}+1);
      $daughtDepth += min(1.8, 250/($size{$root}+1)); # increase depth of small graphs
      my $avgDepth = ($daughtDepth + $depthFact*2) / 3;
      # my $depthDist = ($daughtDepth - $depthFact)/10;
      my $portion = $size{$node} / ($size{$root}+1);

      my $daughtPort = $size{$daughter} / ($size{$root}+1);
      my $edgeWidth1 = min(37,($daughtPort*123)**0.8+8); # based on size of daughter
      my $edgeWidth2 = max(1,38-(15*$daughtDepth**0.4))+8; # based on rank of daughter
      my $edgeWidth = ($edgeWidth1*1.8 + $edgeWidth2*1.2)/3;

      my $edgeWeight = max(1,10/($avgDepth+$portion));

      my $daughtGV = $daughter;
      # $daughtGV = "†" . $daughter if exists $dead{$daughter};
      # Graphviz Cleanup
      $daughtGV =~ s/[\(\)]//g; # hopefully resulting in no clashes
      $daughtGV =~ s/^([0-9])/Num_$1/g;
      $daughtGV =~ s/\./_dot_/g;
      $daughtGV =~ s/-/_dash_/g;
      $daughtGV =~ s/\//_slash_/g;
      $daughtGV =~ s/,/_comma_/g;
      $daughtGV =~ s/__/_/g; # graphviz can't handle this
      $daughtGV =~ s/_$//g;  # or this
      $daughtGV =~ s/&//g;   # or this
      $daughtGV =~ s/;//g;   # for safe measure
      $daughtGV =~ s/ /_/g;  # not needed, no spaces at this point anyway...
      print "$nodeGV -> $daughtGV [color=\"$edgeColor\",penwidth=$edgeWidth,len=$edgeWeight];\n";
      &printGraph($daughter, $root, $nextR, $nextG, $nextB);
    }
  }

  # $fontSize = 20;

  my $fontSize = 85 - min(($depthFact**1.5)*6,80-35); # not smaller than 35
  # $fontSize -= min(10,(6000 / ($size{$root}+1)));
  # $fontSize -= 3 if $node ne $root;
  $fontSize += 9 if $node eq $root;
  $fontSize = max(1, $fontSize);
  $fontSize = int($fontSize*1.2); # (compromising for shrinkImage shift...)

  # my $borderWidth = 6;
  my $borderWidth = max(6,13-$depthFact);
  $borderWidth += 3 if $node eq $root;

  # note, label is not made safe for graphviz, since it's not
  # picky about labels, and some labels get parsed as (GV-style) html
  if (exists $common{$node}) {
          # && $common =~ /[a-z]/) for not dealing with linked common names?
    $label = $common{$node};
  } elsif ($node =~ /Incertae_Sedis/i) { $label = "Incertae Sedis"; }
  else {
    $label = $node;
    $label = join ' ', map({ucfirst()} split /\s/, $label);
    $label =~ s/_/ /g;
  }

  my $tooltip = $node;
  $tooltip = join ' ', map({ucfirst()} split /\s/, $tooltip);
  $tooltip =~ s/_/ /g;
  $tooltip =~ s/× */×/g;
  $tooltip =~ s/&.*//g; # deal with things like "Marsh Cudweed&lt "

  $label =~ s/× */×/g;
  $label =~ s/&.*//g; # deal with things like "Marsh Cudweed&lt "
  $label = `echo \"$label\" | fmt -14`;
  $label =~ s/\n/\\n/g;

  $labelHTML = $label;
  $labelHTML =~ s/\\n/<br\/>/g; # split words over lines for graphviz

  if (exists $dead{$node}) {
    $label = "†" . $label;
    $labelHTML = "†" . $labelHTML;
  }

  my $imageName = &cleanFilename($node); # remove spaces and nasties but keep parens
  # $imageName =~ s/\(/\\(/g; # these must be wrong 
  # $imageName =~ s/\)/\\)/g; # but were here in an apparently working version

  my $URL = &cleanFilename($node) . ".svg";

  print "$nodeGV [";

  $shape = "box";
  # $shape = "folder";
  # $shape = "box" if (@{$tails{$node}} < 2);

  print "shape=$shape,labelloc=t,fontsize=$fontSize,label=\"$label\"";
  print ",tooltip=\"$tooltip\"";
  print ",style=bold,color=\"$nodeColor\",penwidth=$borderWidth";
  print ",margin=\"0.035,0.025\"";
  print ",URL=\"$URL\"";
  if ($hasImage{$node}) {
    print ",label=<<table title=\"$label\" href=\"$URL\" border=\"0\" cellborder=\"0\" cellpadding=\"0\" cellspacing=\"0\">";
    print "<tr><td align=\"center\" title=\"$label\" href=\"$URL\"><img src=\"$directory/Images/$imageName.jpg\"/></td></tr>";
    print "<tr><td title=\"$label\" href=\"$URL\" bgcolor=\"$color\"><font point-size=\"$fontSize\">$labelHTML</font></td></tr>";
    print "</table>>";
  }
  else { print ",label=\"$label\""; }
  print "];\n";

}

&calcImages($inputNode);
# &calcDepths($inputNode, 0); # never used
&calcSizes($inputNode);
&calcRanks($inputNode, $size{$inputNode});
&calcBests($inputNode, $graphSize);

@rootBests = @{$bests{$inputNode}};

foreach $best (@rootBests) { $printables{$best} = 1; }

&printGraph($inputNode, $inputNode, 175, 175, 110);

# foreach $head (keys %tails) { print "$head: ($depth{$head})\n"; }
