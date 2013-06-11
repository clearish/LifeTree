#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

# use utf8;
# binmode STDIN, ':utf8';
# binmode STDOUT, ':utf8';

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

if (not -d "HTML") { system "mkdir HTML"; }

PAGE: while ($line = <>) {
  next if $line !~ /<title>(.*)<\/title>/;
  $title = $1;

  # could preprocess these out for speed boost
  next if $title =~ /Main Page/;
  next if $title =~ /Classification/;
  next if $title =~ /:/; # skip Wiki pages

  while ($line = <>) {
    last if ($line =~ /<\/page>|Distribution/); # ignore maps, although since we're getting the HTML
                                                # we'll have to deal with them again later...

    $imageSuff = "(jpg|jpeg|png|gif|svg)"; # use with case insensitive
    if ($line =~ /^ *(<text xml:space="preserve">)?(\[\[|{{)(image|file).*\.$imageSuff/i) {

      # title can have spaces, parens, and any other number of nasties
      # luckily the quoted argument to curl is fairly flexible (except with spaces)
      # & and ( work easy
      $title =~ s/ /_/g; # these are the same as far a wiki is concerned; can't figure out right way to curl with spaces
      $title =~ s/&amp;/&/g; # argument to curl apparently don't need to backslash

      $filename = &cleanFilename($title); # remove any nasties from title, but keep parens (escaped for shell)
      $filenameSys = $filename;
      $filenameSys =~ s/\(/\\(/g;
      $filenameSys =~ s/\)/\\)/g;

      if (not -e "HTML/$filename") { # (not backslashed)
        system "curl \"http://species.wikimedia.org/wiki/$title\" > HTML/$filenameSys";
        select(undef, undef, undef, rand(0.1)); # usleep wasn't working for some reason
      }
    }

    # if ($line =~ /<text xml:space="preserve">\[\[[A-Za-z]*:([^|]*)\|/) {
    #   $filename = $1;
    #   $filename =~ s/ /\\ /g;
    #   $filename =~ s/\(/\\(/g;
    #   $filename =~ s/\)/\\)/g;
    #   system "curl http://species.wikimedia.org/wiki/File:$filename > Images/$filename";
    #   select(undef, undef, undef, rand(0.3)); # usleep wasn't working for some reason
    # }

  }
}
