#!/usr/bin/perl -w

# returns a reasonable filename for a node name (as output by pruneLinks.pl)
# node, this CAN contain parens, dots, dashes
sub cleanFilename {
  my $name = $_[0];
  $name =~ s/ +/_/g; $name =~ s/×_*/X_/g; $name =~ s/’/_quo_/g; $name =~ s/,/_com_/g; $name =~ s/&/_amp_/g;
  $name =~ s/[^A-Za-z0-9()_.\-]+/_x_/g; # replace anything else with _x_ (will collapse different names!)
  return $name;
}

$name = &cleanFilename($ARGV[0]);
$nameSys = $name;
$nameSys =~ s/\(/\\(/g;
$nameSys =~ s/\)/\\)/g;
$nameSys =~ s/ /\\ /g;

$parent = &cleanFilename($ARGV[1]);
$parentSys = $parent;
$parentSys =~ s/\(/\\(/g;
$parentSys =~ s/\)/\\)/g;
$parentSys =~ s/ /\\ /g;

system "./calcBests.pl \"$nameSys\" < PRUNED.txt 2>calcBests.LOG > \"$nameSys.raw\"";

  # Cancel on imageless leaves
  # $length = `wc -l \"$nameSys.raw\"`;
  # $length =~ /^ *([0-9]*)/;
  # $length = $1;
  # if ($length == 1) {
  #   $imageFile = "Images/$ARGV[0].jpg";
  #   $imageFile =~ s/ /_/g;
  #   # $imageFile =~ s/\(/\\(/g; # I SUSPECT THIS IS WRONG, so I'm leaving it out.
  #   # $imageFile =~ s/\)/\\)/g; # Go back and see if calcBest and calcBest.Batch perform better without it
  #   if (not -e $imageFile) {
  #     system "rm $nameSys.raw";
  #     exit;
  #   }
  #  }

  ## system "./shift.pl < \"$nameSys.raw\" > \"$nameSys.shuf\"";
system "./filterColor.pl \"$nameSys.raw\" > \"$nameSys.1\"";
system "./filterColor.pl \"$nameSys.1\" > \"$nameSys.2\"";
system "./filterColor.pl \"$nameSys.2\" > \"$nameSys.3\"";
system "./filterColor.pl \"$nameSys.3\" > \"$nameSys.4\"";
system "./filterColor.pl \"$nameSys.4\" > \"$nameSys.5\"";
system "./filterColor.pl \"$nameSys.5\" > \"$nameSys.6\"";
system "./removeParens.pl < \"$nameSys.6\" > \"$nameSys.clean\"";
system "./hideBranchesColor.pl \"$nameSys.clean\" > \"$nameSys.hb\"";
system "./addWeights.pl \"$nameSys.hb\" > \"$nameSys.weighted\"";

  ## system "./addWikiLink.pl \"$nameSys.weighted\" > \"$nameSys.linked\"";
  system "./addWikiLink.pl \"$nameSys.hb\" > \"$nameSys.linked\"";

system "./makeGraph.pl \"$nameSys.linked\" > \"$nameSys.gv\"";
system "./addUp.pl \"$nameSys\" \"$parentSys\" < \"$nameSys.gv\" > \"$nameSys.up.gv\"";
system "neato -Tsvg \"$nameSys.up.gv\" -o \"SVG/$nameSys.svg\"";

system "rm $nameSys.raw $nameSys.1 $nameSys.2 $nameSys.3 $nameSys.4 $nameSys.5 $nameSys.6 $nameSys.clean $nameSys.hb $nameSys.weighted $nameSys.linked $nameSys.gv $nameSys.up.gv";
