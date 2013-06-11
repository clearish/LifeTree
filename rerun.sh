#!/bin/sh
# finds the parent automatically, calls run.pl, webify.pl, spiffSVG.pl

./run.pl "$1" "`grep " -> $1\$" PRUNED.txt | awk '{ print $1 }'`"
./webify.sh "SVG/$1.svg"
./spiffSVG.sh "SVG/$1.svg"
