#!/usr/bin/perl -w

$topRoot = $ARGV[0];
$topParent = $ARGV[1];

# returns a reasonable filename for a node name (as output by pruneLinks.pl)
# node, this CAN contain parens, dots, dashes
sub cleanFilename {
  my $name = $_[0];
  $name =~ s/ +/_/g; $name =~ s/×_*/X_/g; $name =~ s/’/_quo_/g; $name =~ s/,/_com_/g; $name =~ s/&/_amp_/g;
  $name =~ s/[^A-Za-z0-9()_.\-]+/_x_/g; # replace anything else with _x_ (will collapse different names!)
  return $name;
}

# @lines = <>;
# push @lines, "$topParent -> $topRoot\n";

# foreach $line (@lines) {
# ...

system("./run.pl $topRoot $topParent"); # until I can figure out why the above todesn't work...

while ($line = <STDIN>) {
  # print STDERR "Graphing $line";
  $line =~ /^(.*) -> (.*)$/;
  $parent = $1; $name = $2;

  $name = &cleanFilename($name);
  $parent = &cleanFilename($parent);

  $nameSys = $name;
  $nameSys =~ s/\(/\\(/g;
  $nameSys =~ s/\)/\\)/g;
  # $parentSys = $parent;
  # $parentSys =~ s/\(/\\(/g;
  # $parentSys =~ s/\)/\\)/g;

  $rawfile = "RAW/$name--PAR--$parent.RAW";
  # $rawfileSys = "RAW/$nameSys--PAR--$parentSys.RAW";

  next if not -e $rawfile; # for perl, not shell

  system "./filterColor.pl \"$rawfile\" > \"$name.1\""; # don't need to backslash parens inside quotes
  system "./filterColor.pl \"$name.1\" > \"$name.2\"";
  system "./filterColor.pl \"$name.2\" > \"$name.3\"";
  system "./filterColor.pl \"$name.3\" > \"$name.4\"";
  system "./filterColor.pl \"$name.4\" > \"$name.5\"";
  system "./filterColor.pl \"$name.5\" > \"$name.6\"";
  system "./removeParens.pl < \"$name.6\" > \"$name.clean\"";
  system "./hideBranchesColor.pl \"$name.clean\" > \"$name.hb\"";

  # system "./addWeights.pl \"$name.hb\" > \"$name.weighted\"";
  # system "./addWikiLink.pl \"$name.weighted\" > \"$name.linked\"";

  system "./addWikiLink.pl \"$name.hb\" > \"$name.linked\"";

  system "./makeGraph.pl \"$name.linked\" > \"$name.gv\"";
  system "./addUp.pl \"$name\" \"$parent\" < \"$name.gv\" > \"$name.up.gv\"";
  system "neato -Tsvg \"$name.up.gv\" -o \"SVG/$name.svg\"";

  # leave the .RAW file there in case we messed something up and want to go back
  system "rm $nameSys.1 $nameSys.2 $nameSys.3 $nameSys.4 $nameSys.5 $nameSys.6 $nameSys.clean $nameSys.hb $nameSys.linked $nameSys.gv $nameSys.up.gv";
}
