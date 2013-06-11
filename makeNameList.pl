#!/usr/bin/perl -w

# create a webpage linking common names to .svg files

# Input lines look like "Abacarus hystrix = Cereal Rust Mite"

print '<meta http-equiv="Content-Type" content="text/html;charset=utf-8">';
print "\n";
print "<html>\n";

while ($line = <>) {
  $line =~ /^(.*) = (.*)$/;
  $species = $1; $common = $2;
  next if lc($species) eq lc($common);
  $species =~ s/ /_/g;
  next if not -e "SVG/$species.svg";
  $species{$common} .= "<a href=\"http://s3.amazonaws.com/cf-templates-e27q3tu2tarc-us-east-1/SVG/$species.svg\">$species</a>, ";
}

foreach $common (sort keys %species) {
  $list = substr($species{$common}, 0, -2); # remove last space and comma
  print "<li>$common: $list</li>\n"; 
}

print "</html>\n";
