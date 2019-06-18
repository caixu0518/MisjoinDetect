#!/usr/bin/perl

##-Author: Xu Cai
##-Bug report: caixu0518@163.com

use warnings;
use strict;
use Getopt::Long;

##-Usage-----------------------------------------

my $usage=<<USAGE;
   
   Usage: perl $0 -s <output file of SynOrths> -m <min gene number>
   -s		[required] output file of SynOrths
   -m	  	[optional] Minimum fragment length (gene number: default: 5) 

USAGE

##--Initialize input parameters-------------------
my ($in0, $minGeneNum);
GetOptions(
    "s:s"=>\$in0,
    "m:s"=>\$minGeneNum,
);

die $usage, if (!defined $in0);
$minGeneNum = 5, if(!defined $minGeneNum);


##-main process-------------------------------------
    &process();

sub process {
   
    my $scf2Chr = "scaffolds.to.chrs.list"; 
    my $misjoins = "candidate.misjoins.list";
    &readSynOrth($in0, $minGeneNum, $scf2Chr, $misjoins);
}


sub readSynOrth {

    my ($SynOrth, $minGeneNum, $scf2Chr, $misjoins) = @_;

    ##- sort SynOrth results
    `sort -k6,6 -k7,7n  $SynOrth > $SynOrth.sort`;

    my %chrIndex = ();
    my %chr2scf = ();
    my %chr2scfInfo = ();
    my $count = 0;
    open IN0, "$SynOrth.sort";
    while(<IN0>){
      chomp;
      my @temp = split(/\t/, $_);
      if(not exists $chrIndex{$temp[5]}){
         $chrIndex{$temp[5]} = "Y";
         $count = 0;
      }

      if(not exists $chr2scf{$temp[5]}{$temp[1]}){
         $chr2scf{$temp[5]}{$temp[1]} = "Y";
         $count += 1;
      }
     
      if(not exists $chr2scfInfo{$temp[5]}{$count}{$temp[1]}){
         $chr2scfInfo{$temp[5]}{$count}{$temp[1]} = "$temp[0]:$temp[2]:$temp[3]";
      }

      if(exists $chr2scfInfo{$temp[5]}{$count}{$temp[1]}){
         $chr2scfInfo{$temp[5]}{$count}{$temp[1]} .= "\t"."$temp[0]:$temp[2]:$temp[3]";
      }
    }
    close IN0;
  
    ##- generate scaffolds to chrs list 
    open OUT0, ">$scf2Chr";
    for my $key1(sort keys %chr2scfInfo){
        for my $key2(sort {$a<=>$b} keys %{$chr2scfInfo{$key1}}){
            for my $key3(keys %{$chr2scfInfo{$key1}{$key2}}){
                my @info = split(/\t/, $chr2scfInfo{$key1}{$key2}{$key3});
                my @geneinfo1 = split(/:/, $info[0]);
                my @geneinfo2 = split(/:/, $info[-1]);
                my ($strand, $start, $end, $geneS, $geneE) = ("NA", "NA", "NA", "NA", "NA");
               
                my $geneNum = 0; 
                if($geneinfo1[1] < $geneinfo2[1]){
                   $strand = '+';
                   ($start, $end) = ($geneinfo1[1], $geneinfo2[2]);
                   ($geneS, $geneE) = ($geneinfo1[0], $geneinfo2[0]);
                }
                if($geneinfo1[1] > $geneinfo2[1]){
                   $strand = '-';
                   ($start, $end) = ($geneinfo2[1], $geneinfo1[2]); 
                   ($geneS, $geneE) = ($geneinfo2[0], $geneinfo1[0]);
                }
                if($geneinfo1[1] == $geneinfo2[1]){
                   ($start, $end) = ($geneinfo1[1], $geneinfo1[2]);
                   ($geneS, $geneE) = ($geneinfo1[0], $geneinfo2[0]);
                }
                $geneNum = scalar(@info);
                $geneNum = scalar(@info) - 1, if($geneinfo1[1] == $geneinfo2[1]);
                print OUT0  join("\t", $key1, $key2, $key3, $strand, $geneNum, "$geneS-$geneE", "$start-$end"), "\n";
            }
        }
    }
    close OUT0;

    ##- generate candidate misjoins list 
    my %scf2chr = ();
    open IN1, $scf2Chr;
    while(<IN1>){
      chomp;
      my @temp = split(/\t/, $_);
      next, if($temp[4] <= $minGeneNum);
      if(not exists $scf2chr{$temp[2]}){
         $scf2chr{$temp[2]} = $temp[6];
      }
      else{
         $scf2chr{$temp[2]} .= "\t".$temp[6];
      }
    }
    close IN1;
    
    open OUT1, ">$misjoins"; 
    for my $key(sort keys %scf2chr){
        my @info = split(/\t/, $scf2chr{$key});
        my %sort = ();
        if(scalar(@info) >= 2){
           for my $element(@info){
               if($element =~ /(\S+?)-(\S+)/){
                  my $mid = ($1+$2)/2;
                     $sort{$mid} = $element;
               }
           }
           my @sortCoords = ();
           for my $key1(sort {$a<=>$b} keys %sort) {
               push(@sortCoords, $sort{$key1});
           } 
           print OUT1 join("\t", $key, @sortCoords), "\n", if(scalar(@info) >= 2);
        }
    }
    close OUT1; 

}

__END__
