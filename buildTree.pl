#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

use utf8;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

if (not -e "Images") { system "mkdir Images"; }

PAGE: while ($line = <>) {
  next if $line !~ /<title>(.*)<\/title>/;
  $title = $1;

  # could preprocess these out for speed boost...
  next if $title =~ /Main Page/;
  next if $title =~ /Classification/;
  next if $title =~ /:/; # skip Wiki pages

  $foundSelf = 0;
  $foundCommon = 0;
  $links{$title} = "";

  # moving on after <title> tag
  while ($line = <>) {
    last if ($line =~ /<\/page>/);
    last if ($line =~ /{{disambig}}/);
    if ($line =~ /<redirect title="([^"]*)"/) {
      $links{$title} = " -- Redirect: $1"; last;
    }

    $titleRegex = $title;
    $titleRegex =~ s/\(/\\(/g;
    $titleRegex =~ s/\)/\\)/g;

    $titleFirstTwo = $titleRegex;
    $titleFirstTwo =~ s/^(..).*$/$1/;

    # HACKS to accommodate stupidity
    if ($title eq "Angiosperms") { $titleRegex = "Angiospermae"; }

    if ($line =~ /<comment>/) { while ($line !~ /<\/comment>/) { $line = <>; } }

    if ( $line =~ /^ *(<[A-Za-z: ="]*>)*:*[A-Za-z]*:* *{{([A-Za-z]*\|)?($titleRegex) *}}/i
         or $line =~ /^:*\(*[A-Za-z]+\)*[: ]+\)* *['\[]*($titleRegex)[ '\]]/i
         or ($line =~ /^{{$titleFirstTwo[^{}|]*}}$/i and $line !~ /VN|[Cc]ommons/) ) {

      $foundSelf = 1;

      # ==.[^=] is a level two or three section other than e.g. ==A==
      # (we look into tables of contents because of pages like Atriplex
      # </page> is end of page
      # Overview would filter long links, but we'll keep these and filter them later
      # (because some pages like Caninae, the Overview is the only way to get lower)
      $endCond = "^==.[^=]|<\\/page>";

      # moving on after link to self
      AFTERFOUND: while ($line = <>) {

        last if ($line =~ /$endCond/ and $line !~ /Overview/);

        next if $line =~ /{{TOC}}/;
        next if $line =~ /BASEPAGENAME/;
        # this was right!
        # next if $line =~ /(superclassis)/; # skip Sarcopterygii -> Tetrapoda

        if ($line =~ /^Synonyms/) {
          while ($line = <>) {
            last if $line =~ /^[A-Za-z]/; # end of multi-line synonyms section
            last AFTERFOUND if $line =~ /$endCond/;
          }
        }

        # remember first vernacular name
        $commonCond1 = "^({{VN.*)? *\\|en=([^|}\\]]+)";    # NOTE these are not yet RegEx's
        $commonCond2 = "^\\[\\[en:([^\\]{|]*)[^\\]{]*\\]"; # hence, double \\
        if ($foundCommon == 0 and $line =~ /$commonCond1/) { $common = $2; $foundCommon = 1; }
        if ($foundCommon == 0 and $line =~ /$commonCond2/) { $common = $1; $foundCommon = 1; }
        last AFTERFOUND if $foundCommon or $line =~ /^{{VN/; # English name or non-English VN signals end

        next if $line =~ /sources:/i;
        next if $line =~ /source:/i;
        next if $line =~ /note:/i;
        next if $line =~ /^\[[^\[]/i;
        next if $line =~ /^&lt;br \/&gt;\[[^\[]/i;

        $line =~ s/ †/†/g;
	$line =~ s/†\?/?†/g;
	$line =~ s/‎//g;

        foreach $sub ($line =~ m/(†?'*†?\[\[[^\]]*\]\])/g) {
          next if $sub =~ /:/; # pages in other languages
          $sub =~ s/\|.*$//;
          $sub =~ s/'//g;
          $sub =~ s/[\[\]]//g;
          next if $sub =~ /^$/;
          next if $sub =~ /^tobediscussed$/;
          next if $sub =~ /^environmental samples$/;
          next if $sub =~ /^commons/;
          $sub = ucfirst($sub);
          $links{$title} .= " || $sub";
        }

        foreach $sub ($line =~ m/(†?'*†?{{[^}]*}})/g) {
          next if $sub =~ /^$/;
          next if $sub =~ /\[\[/; # already dealt with it
          next if $sub =~ /:/; # pages in other languages
          next if $sub =~ /{{cite /; # citation
          next if $sub =~ /{{aut\|/; # author
          # deal with spelling abbreviations e.g. {{ssp|A|iolopus|t|halassinus|dubius}}
          # but leave {{g|... as is, e.g. {{g|Macgregoria (Paradisaeidae)|Macgregoria}}
          if ($sub =~ /{{[a-fh-z][a-z]* *\|/i) { # catches sp, ssp, sgsp, var, Var, subsp, sect, ...

            # deal with templates that insert text... (but what if MORE are created??)
            if ($sub =~ /{{f(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*)$/$1f. $2/; }
            if ($sub =~ /{{nsect(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1nothosect. $2/; }
            if ($sub =~ /{{nothosubsp(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*)$/$1nothosubsp. $2/; }
            if ($sub =~ /{{nvar(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*)$/$1nothovar. $2/; }
            if ($sub =~ /{{sect(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1sect. $2/; }
            if ($sub =~ /{{ser(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1ser. $2/; }
            if ($sub =~ /{{subgplant(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1subg. $2/; }
            if ($sub =~ /{{subsect(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1subsect. $2/; }
            if ($sub =~ /{{subser(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1subser. $2/; }
            if ($sub =~ /{{subspforma(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*\|.*\|)(.*)$/$1subsp. $2forma $3/; }
            if ($sub =~ /{{subspplant(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*)$/$1subsp. $2/; }
            if ($sub =~ /{{subspvar(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*\|.*\|)(.*)$/$1subsp. $2var. $3/; }
            if ($sub =~ /{{supersect(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|)(.*)$/$1supersect. $2/; }
            if ($sub =~ /{{var(last)*\|/i) { $sub =~ s/^(.*\|.*\|.*\|.*\|.*\|)(.*)$/$1var. $2/; }

            $sub =~ s/{{[^|]*\|/{{/; # get rid of everything up to first pipe
            while ($sub =~ /\|/) { # remaining pipes: delete, space, delete, space, ...
              $sub =~ s/\|//;
              $sub =~ s/\|/ /;
            }
          } else { $sub =~ s/{{[^|]*\|/{{/; } # get rid of everything up to first pipe
          $sub =~ s/\|[^|]*}}//; # now remove everything after the next pipe
          $sub =~ s/'//g;
          $sub =~ s/[{}]//g;
          next if $sub =~ /^$/;
          next if $sub =~ /^tobediscussed$/;
          next if $sub =~ /^environmental samples$/;
          next if $sub =~ /^commons/;
          $sub = ucfirst($sub);
          $links{$title} .= " || $sub";
        }
      }

      # continue searching for vernacular names
      while ($foundCommon == 0 and $line !~ /<\/page>/) {
        $line = <>;
        if ($line =~ /$commonCond1/) { $common = $2; $foundCommon = 1; last; }
        if ($line =~ /$commonCond2/) { $common = $1; $foundCommon = 1; last; }
      }
      if ($foundCommon == 1) {
        $common =~ s/\"/'/g;
        $common =~ s/\&amp;nbsp;//g; # don't know what the lichens people are up to
        $common =~ s/\&amp;/and/g; # e.g. Knife-fishes &amp; Electric Eels
        $common =~ s/\&quot;//g; # e.g. "Large diver" Penguins (Megadyptes)
        $common =~ s/''//g; # e.g. ''...''
        $common = join ' ', map({ucfirst()} split /\s/, $common);
        $common =~ s/ And / and /g; $common =~ s/ Or / or /g;
        $common =~ s/ Of / of /g; $common =~ s/ A / a /g;
        $common =~ s/ An / an /g; $common =~ s/ The / the /g;
        $common =~ s/ \([^)]*\)//g; # lose notes on e.g. "Abida (gastropod)"
        $common =~ s/ *\[.*$//g; # lose bracketed info e.g. "Smooth New Holland Daisy [source: ...]"
        $common =~ s/^([^;:,]*)[;:,].*$/$1/g; # take only first name of ; or , sequence, ignore : material
        $common =~ s/^.* \/ *(.*)$/$1/ig; # take only last name of / sequence
        $common =~ s/^.* or (.*)$/$1/ig; # take only last name of or sequence (Variable or Yellow-bellied Sundbird)
        $common =~ s/^ *//;
        $common =~ s/  / /g;
        $common =~ s/‎//g;
        $common =~ s/\.$//g; # remove final periods
        $common{$title} = $common;
      }
    }
    last if $foundSelf;
  }

  if (not $foundSelf) { print STDERR "No selflink on page '$title'\n"; }
}

foreach $key (sort keys %links) {
  print "$key ->";
  @links = split / \|\| /, $links{$key};
  foreach $link (@links) {
    next if $link eq "";
    $link =~ s/_/ /g;
    $link =~ s/ +/ /g; 
    # note, I believe redirects will break on names with †
    if ($links{$link} =~ /-- Redirect: (.*)$/) {
      print " {$1}"; # hopefully no redirects to redirects...
    } else { print " {$link}" unless $link =~ /-- Redirect:/; }
  }
  print "\n";
  print "$key = $common{$key}\n" if exists $common{$key} and $common{$key} ne "";
}
