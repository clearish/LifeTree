#!/usr/bin/perl -w

use List::Util qw(min max);
use Time::HiRes qw(usleep);

# use utf8;
# binmode STDIN, ':utf8';
# binmode STDOUT, ':utf8';

%dead = ();

while ($line = <>) {
  $line =~ /^(.*) -> (.*)$/;
  $head = $1;
  $tailsString = $2;
  $headBare = $head;
  $headBare =~ s/†//g;
  $headBare =~ s/ /_/g; # XXX
  $dead{$headBare} = 1 if $head =~ /†/;
  foreach $tail ($tailsString =~ m/{([^}]*)}/g) {
    next if $tail eq $head;
    $tailBare = $tail;
    $tailBare =~ s/†//g;
    $tailBare =~ s/ /_/g; # XXX
    $dead{$tailBare} = 1 if $tail =~ /†/;
    push @{$tails{$headBare}}, $tailBare;
    push @{$heads{$tailBare}}, $headBare;
    # $fromTo{$headBare}{$tailBare} = 1;
  }
}

# for $key (keys %tails) { foreach $tail ( @{$tails{$key}} ) { print "DEBUG $key: $tail\n"; } }

%depth = ();

sub calcDepths {
  my ($node, $depth) = ($_[0], $_[1]);
  # my $node = $_[0];
  # my $depth = $_[1];
  # print "Called calcDepths: $node, $depth\n";
  return if exists $depth{$node};
  $depth{$node} = $depth;
  foreach $daughter ( @{$tails{$node}} ) { &calcDepths($daughter, $depth+1); }
}

&calcDepths("Biota", 0);

# foreach $head (keys %tails) { print "$head: ($depth{$head})\n"; }

# FIND NODES WITH > 1 MOTHER (and remove them by hand...)
# foreach $tail (keys %heads) {
#   next if @{$heads{$tail}} < 2;
#   print "$tail ($depth{$tail}) <-";
#   @sorted = sort { $depth{$b} <=> $depth{$a} } @{$heads{$tail}}; # sort by decreasing depth
#   foreach $head (@sorted) { print " $head ($depth{$head}),"; }
#   print "\n";
# }

%contains = ();

sub contains {
  my ($root, $target) = ($_[0], $_[1]);
  # foreach $tail (@{$tails{$root}}) { print STDERR "$tail, " if $DEBUG; }
  if (exists $contains{$root}{$target}) {
    # print STDERR "Skipping contains($root, $target); loop!\n" if $DEBUG and $contains{$root}{$target} == -1;
    return 0 if $contains{$root}{$target} == -1; # break loops
    return $contains{$root}{$target};
  }
  $contains{$root}{$target} = -1; # mark that we've started searching
  return $contains{$root}{$target} = 1 if $root eq $target;
  foreach $tail (@{$tails{$root}}) {
    return $contains{$root}{$target} = 1 if &contains($tail, $target);
  }
  return $contains{$root}{$target} = 0;
}

# prune tails with >1 mother to the deepest mother (skip long branches),
# but ignore branches that loop
# XXX: There seems to be a bug here, whereby a mother with undefined depth
#      is preferred.  E.g. Dictyozoa ends up mother to Bikonta.
foreach $tail (keys %heads) {
  @heads = @{$heads{$tail}};
  next if @heads < 2;

  # remove loops!
  for (my $i = $#heads; $i >= 0; --$i) {
    splice @heads, $i, 1 if &contains($tail, $heads[$i]);
  }

  # sort by decreasing depth (depends on undefined values, but works??)
  @sorted = sort { $depth{$b} <=> $depth{$a} } @heads; 

  if (@sorted > 2) {
    print STDERR "Warning: $tail ($depth{$tail}) has moms "; 
    foreach $mom (@sorted) {
      print STDERR "$mom ($depth{$mom}), ";
      if ($depth{$mom} > $depth{$tail}) {
        print STDERR "Mom is baby!!"; 
        # if (&contains("Plantae", $tail) and &contains("Animalia", $mom)) { print STDERR "Animal->Plant!!"; }
        # if (&contains("Animalia", $tail) and &contains("Plantae", $mom)) { print STDERR "Plant->Animal!!"; }
      }
    }
    print STDERR "\n";
  }

  splice @sorted, 1; # truncate to shortest edge
  @{$heads{$tail}} = @sorted;
}

foreach $tail (keys %heads) {
  foreach $head (@{$heads{$tail}}) {
    # print "†" if (exists $dead{$head});
    print "$head -> ";
    # print "†" if (exists $dead{$tail});
    print "$tail\n";
  }
}

open DEAD, ">DEAD.txt"; 
foreach $key (keys %dead) { print DEAD "$key\n"; }

# print "DEBUG Eukaryota contains Suina? " . &contains("Eukaryota", "Suina") . "\n";
