#!/usr/bin/perl -w
use strict;

##-Author: Xu Cai
##-Bug report: caixu0518@163.com

my $in0 = $ARGV[0]; ##- candidate.misjoins.list
my $in1 = $ARGV[1]; ##- mismatch_narrow.bed.35kb.breakpoints
my $out = 'merged.breakpoints.list';

my %index = ();
my %indexScf = ();
open IN0, $in0;
while(<IN0>){
  chomp; 
  my @temp = split(/\t/, $_);
  my @coords = ();
  for(my $m=1; $m<=$#temp; $m++){
      my @links = split("-", $temp[$m]);
      push(@coords, @links);
  } 
 
  for(my $n=1; $n <$#coords; $n++){
      print  join("\t", $temp[0], $coords[$n], $coords[$n+1]), "\n", if($n%2 == 1);
      if($n%2 == 1){
         $index{$temp[0]}{$coords[$n]}{$coords[$n+1]} = "Y";
         $indexScf{$temp[0]} = "Y";
      }
  } 

}
close IN0;

##- detect overlap
my %overlap = ();
open IN1, $in1;
open OUT, ">$out";
while(<IN1>){
  chomp;
  my ($id, $start, $end) = (split(/\t/, $_))[0,1,2];
  if(exists $indexScf{$id}){
     for my $key1(sort keys %{$index{$id}}){
         for my $key2(sort keys %{$index{$id}{$key1}}){
             ##- detect overlap
             if(($start > $key1 && $end < $key2) || ($end > $key1 && $end < $key2)){
                 print OUT join("\t", $id, $start, $end), "\n";
                 $overlap{$id}{$key1}{$key2} = 'Y';
             }
         }
     }
  }
  else{
     print OUT join("\t", $id, $start, $end), "\n";
  }
}
close IN1;

for my $scf (keys %index){
    for my $s1(keys %{$index{$scf}}){
        for my $e1(keys %{$index{$scf}{$s1}}){
               print OUT join("\t", $scf, $s1, $e1), "\n", if(not exists $overlap{$scf}{$s1}{$e1});
        }
    }
}
close OUT;
