#!/usr/bin/perl -w
use strict;

my @file = @ARGV;        ##- coorected point files
my $in0 = shift(@ARGV);  ##- 50kb bin size

    
    &main();
sub main {
 
    ##- read main bin file
    my %scf2points = ();
       &read_mainBin($in0, \%scf2points);

    ##- read supplymentary file
    my $out = $in0.".add";
       &add($in0, \@file, \%scf2points, $out); 

}


sub add {

    my ($mainBin, $files, $scf2point, $out) = @_;

    for my $file(@{$files}){
        open IN1, $file;
        while(<IN1>){
           chomp;
           my @temp = split(/\t/, $_);
           my $scf = shift(@temp);
           if(not exists $scf2point ->{$scf}){
              $scf2point ->{$scf} = \@temp;
           }
           else{
              next;
           }
        }
        close IN1;
    }
   
    open OUT0, ">$out";
    my %mainscf = ();
    open IN2, $mainBin;
    while(<IN2>){
      print OUT0 $_;
      chomp;
      my @temp = split(/\t/, $_);
      my $scf = shift(@temp);
         $mainscf{$scf} = "Y";
    }
    close IN2;    


    for my $key(sort keys %{$scf2point}){
        print OUT0 join("\t", $key, @{$scf2point ->{$key}}), "\n", if(not exists $mainscf{$key});
    }
    close OUT0;

}


sub read_mainBin {

    my ($mainBin, $scf2point) = @_;
  
    open IN0, $mainBin;
    while(<IN0>){
      chomp;
      my @temp = split(/\t/, $_);
      my $scf = shift(@temp);
      $scf2point ->{$scf} = \@temp;
    }
    close IN0;

}
