#!/usr/bin/perl -w

$directory = ".";

$self = $ARGV[0];
$selfGV = $self; # $selfGV =~ s/[\(\)\-\.]//g;

  # this code needs to exactly match that in calcBests.pl / calcBests.Batch.pl
  $selfGV =~ s/[\(\)]//g; # hopefully resulting in no clashes
  $selfGV =~ s/^([0-9])/Num_$1/g;
  $selfGV =~ s/\./_dot_/g;
  $selfGV =~ s/-/_dash_/g;
  $selfGV =~ s/\//_slash_/g;
  $selfGV =~ s/,/_comma_/g;
  $selfGV =~ s/__/_/g; # graphviz can't handle this
  $selfGV =~ s/_$//g;  # or this
  $selfGV =~ s/&//g;   # or this
  $selfGV =~ s/;//g;   # for safe measure

$parent = $ARGV[1];
$parentGV = $parent; # $parentGV =~ s/[\(\)\-\.]//g;

  # this code needs to exactly match that in calcBests.pl / calcBests.Batch.pl
  $parentGV =~ s/[\(\)]//g; # hopefully resulting in no clashes
  $parentGV =~ s/^([0-9])/Num_$1/g;
  $parentGV =~ s/\./_dot_/g;
  $parentGV =~ s/-/_dash_/g;
  $parentGV =~ s/\//_slash_/g;
  $parentGV =~ s/,/_comma_/g;
  $parentGV =~ s/__/_/g; # graphviz can't handle this
  $parentGV =~ s/_$//g;  # or this
  $parentGV =~ s/&//g;   # or this
  $parentGV =~ s/;//g;   # for safe measure

while ($line = <STDIN>) {
  if ($line =~ /END GRAPH/) {
    # print "$selfGV -> wikilink [style=invis];\n";
    # print "wikilink [shape=box,style=bold,color=white,label=\"\",penwidth=0";
    # print ",URL=\"$prefix/$self\""; 
    # print ",image=\"/Users/noah/Desktop/LifeTree/wikilink.png\"";
    # print "];\n";

    print "$parentGV -> $selfGV [color=\"#960F1E\",penwidth=30];\n";
    print "$parentGV [shape=box,style=bold,color=\"#960F1E\",label=\"\",penwidth=15";
    print ",URL=\"$parent.svg\""; 
    print ",image=\"$directory/up.png\"";
    print "];\n";
  }
  print $line;
}
