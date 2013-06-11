#!/usr/bin/perl -w

# NOTE MOST OF THE WORK THIS SCRIPT IS DOING IS NO LONGER NEEDED

use List::Util qw(min max);

$file = $ARGV[0];
open(FILE,$file);

# $fileSys = $file;
# $fileSys =~ s/\(/\\(/g;
# $fileSys =~ s/\)/\\)/g;
# $fileSys =~ s/ /\\ /g;

$length = `grep shape= \"$file\" | wc -l`;
$length =~ /^ *([0-9]*)/;
$length = $1;
$arrowHead = ($length <= 2 ? ", arrowhead=none" : "");

if ($length == 5) { $length += 10; }
$length += 10;
$size = min(($length**0.3) * 2.5, 15) + $length**0.1;

$file =~ /^(.*)\./;
$graphName = $1;
$graphName =~ s/_/ /g;
$graphName =~ s/  / /g;
$graphName =~ s/[\(\)\-\.]//g;

print "digraph \"$graphName\" {\n";
print "epsilon=0.000000001\n"; # default 0.1, lower means search harder
print "overlap=false;\n";
if ($length < 1000) { print "splines=true;\n"; } # was 500
else { print "splines=false;\n"; }
print "edge [style=tapered, arrowsize=1$arrowHead];\n"; # arrowhead=none
# print "node [fixedsize=true,height=0.75];\n";
# $size *= 1.9 * max(0.7, min(0.85,(100/$length)));
$sizeX = $size * 1.9 * max(0.8, min(1.1,(70/$length)));
$sizeY = $size * 1.4 * max(0.8, min(1.1,(70/$length)));

# this scales graph down to fit a box; doesn't affect layout
print "size=\"$sizeX,$sizeY\";\n"; 

# STANDARD:
$sep = max(2,int(15-200/$length));
$esep = max(3.9,int(10-100/$length));

# FOR REDO's that broke splines...
# $sep = 1+max(2,int(15-200/$length)); # 1+ or 2+, 3+, or 4+ if necessary
# $esep = -1+max(3.9,int(10-100/$length)); # -1 or -2 if necessary

print "sep=\"+$sep\"; // minimum border between nodes\n";
print "esep=\"+$esep\"; // border between splines and nodes\n";

# print "sep=\"+12\"; // minimum border between nodes\n";
# print "esep=\"+6\"; // border between splines and nodes\n";

print "mode=ipsep;\n";

while ($line = <FILE>) { print $line; }

print "} // END GRAPH \n";
