#!/usr/bin/perl

##-Author: Xu Cai
##-Bug report: caixu0518@163.com

use warnings;
use strict;
use Getopt::Long;

##-Usage-----------------------------------------

my $usage=<<USAGE;
   
   Usage: perl $0 -fasta <scaffolds file> -breakpoint <breakpoint file>  -binsize <bin size>  -gap [Gap information] -gene [gene coordinate sorted file]

   -fasta	[required] Scaffolds file (fasta format).
   -breakpoint	[required] Breakpoint information (generated by the first step).
   
   -gap  	[optional] Gap information in scaffolds.
   -gene        [optional] Gene coordinate file (sorted results).

USAGE

##--Initialize input parameters-------------------

my ($in0, $in1, $in2, $in3);

GetOptions(

	"fasta:s"=>\$in0,
	"breakpoint:s"=>\$in1,
	"gap:s"=>\$in2,
	"gene:s"=>\$in3,
);

die $usage, if (!defined $in0 || !defined $in1);
my $out = "corrected.breakpoints.list";

##-main process-------------------------------------
    
   &main;
sub main {
  ##- read scaffolds fasta file
  my %scf2seq = (); 
     &readFasta($in0, \%scf2seq);

  ##- read breakpoint information
  my %misjoin_bin = ();
     &read_misjoin_bin($in1, \%misjoin_bin);

  ##- read gap information
  my %gap_info = ();
     &read_gap($in2, \%gap_info), if(defined $in2);
  
  ##- correct breakpoints
  my %breakpoint = ();
     &check_bread_point(\%misjoin_bin, \%gap_info, $in3, \%breakpoint);
  #   &check_bread_point(\%misjoin_bin, \%gap_info, $in3, \%breakpoint),   if(defined $in2 && defined $in3);
  #   &check_bread_point(\%misjoin_bin, \%gap_info, \%breakpoint),         if(defined $in2 && not defined $in3);
  #   &check_bread_point(\%misjoin_bin, $in3, \%breakpoint),               if(not defined $in2 && defined $in3);
  #   &check_bread_point(\%misjoin_bin, \%breakpoint),                     if(not defined $in2 && not defined $in3);

  &output(\%breakpoint, $out);
}

##-all subs-----------------------------------------
sub output {
  my ($breakpoint, $out) = @_;

  open OUT, ">$out"; 
  print OUT $_, "\t", $breakpoint ->{$_}, "\n", for(sort keys %{$breakpoint});
  close OUT;

}

sub check_bread_point {
  my ($misjoin_bin, $gap_info, $geneCoords, $breakpoint) = @_;  
  #   ($misjoin_bin, $gap_info, $geneCoords, $breakpoint) = @_,  if(defined $in2 && defined $in3);
  #   ($misjoin_bin, $gap_info, $breakpoint) = @_,               if(defined $in2 && not defined $in3);
  #   ($misjoin_bin, $geneCoords, $breakpoint) = @_,             if(not defined $in2 && defined $in3);
  #   ($misjoin_bin, $breakpoint) = @_,                          if(not defined $in2 && not defined $in3);

  for my $key(sort keys %{$misjoin_bin}){
    my @corrected_break_point;
    my @temp = split("\t", $misjoin_bin ->{$key});
    for my $pos(@temp){
        my ($start, $end, $new_pos);
        if($pos =~ /(\S+?):(\S+)/){
           ($start, $end) = ($1, $2);
        }
        $pos = ($start+$end)/2;
        ##- only defined gap information
        if(defined $in2 && not defined $in3){
          if($gap_info ->{$key} eq "No_gap"){ ##- this regions have no gap sequences
             $new_pos = $pos; 
          }
          else{
              my @gapCoords = split(/;/, $gap_info ->{$key});
              for my $coord(@gapCoords){
                  my @element = split(/\.\./, $coord);

                  ##- detected gap sequences in this region
                  if($element[0] >= $start && $element[1] <= $end){
                     ##- change .. link into midpoints
                     ## $new_pos = $element[0]."..".$element[1]; ##- marker gap regions
                     $new_pos = ($element[0]+$element[1])/2; ##- marker gap regions (select midpoints as breakpoints, and N will be delete by next step)
                  }
                  else{                    
                     ##- this region have no gap sequences
                     $new_pos = $pos;
                  }
              }
          }          
        }
    
        ##- only defined gene
        if(not defined $in2 && defined $in3){
           &check_gene_Coords($key, $pos, $geneCoords, \$new_pos), if(defined $geneCoords);
        }

        ##- defined gap and gene information
        if(defined $in2 && defined $in3){
           if($gap_info ->{$key} eq "No_gap"){ ##- this regions have no gap sequences
              &check_gene_Coords($key, $pos, $geneCoords, \$new_pos), if(defined $geneCoords);
           }
           else{
              my @gapCoords = split(/;/, $gap_info ->{$key}); 
              for my $coord(@gapCoords){
                my @element = split(/\.\./, $coord);
                if($element[0] >= $start && $element[1] <= $end){ 
                   ##- detected gap sequences in this region
                   ##- use midpoints to mark gap 
                   ##- $new_pos = $element[0]."..".$element[1]; ##- marker gap regions
                       $new_pos = ($element[0]+$element[1])/2; ##- marker gap regions
                }
                else{  ##- this region have no gap sequences
                   &check_gene_Coords($key, $pos, $geneCoords, \$new_pos), if(defined $geneCoords);
                }
             }
           }
        }
        
        ##- Not defined gene and gap information
        if(not defined $in2 && defined $in3){
           $new_pos = $pos;           
        }

        push(@corrected_break_point, $new_pos);
    }
    die "Error: corrected breakpoint step...\n", if(@corrected_break_point == 0);
    my $corrected_break_point = join("\t", @corrected_break_point);
    if(not exists $breakpoint ->{$key}){
       $breakpoint ->{$key} = $corrected_break_point;
    }
    else{
       $breakpoint ->{$key} .= "\t".$corrected_break_point;
    }
  }

}

sub check_gene_Coords {
  my ($scf, $pos, $geneCoord, $N_pos) = @_;
   
  $$N_pos = $pos;
  `awk '{if(\$2=="$scf") print}' $geneCoord > $scf.Coords`;
 
  ##- index gene coords
  my %geneCoordsIndex = ();
  my $LineNum = 0;
  open IN2, "$scf.Coords";
  while(<IN2>){
    chomp;
    $LineNum += 1;
    if(not exists $geneCoordsIndex{$LineNum}){
       $geneCoordsIndex{$LineNum} = $_;
    }
    else{
       next;
    }
  }
  close IN2;
  system("rm $scf.Coords");

  for my $key(sort {$a <=> $b} keys %geneCoordsIndex){
    my @temp = split("\t", $geneCoordsIndex{$key});
    if($pos >= $temp[2] && $pos <= $temp[3]){
       if(exists $geneCoordsIndex{$key - 1}){
          my @element = split("\t", $geneCoordsIndex{$key - 1});
          $$N_pos = int(($element[3] + $temp[2])/2);  ##- use mid-point as breakpoint
       }
       else{
          $$N_pos = $temp[2] - 2000;
       }
    }
    last, if($pos < $temp[2]);
  }

}

sub read_gap {
  my ($gapFile, $gap_info) = @_;
  
  open IN1, $gapFile;
  while(<IN1>){
    chomp;
    my @temp = split("\t", $_);
    $gap_info ->{$temp[0]} = $temp[1];
  }  
  close IN1;

}

sub read_misjoin_bin {
  my ($misjoinFile, $misjoin_bin) = @_;

  open IN0, $misjoinFile;
  while(<IN0>){
    chomp;
    my @temp = split("\t", $_);
    if(not exists $misjoin_bin ->{$temp[0]}){
       $misjoin_bin ->{$temp[0]} = $temp[1].":".$temp[2];
    }
    else{
       $misjoin_bin ->{$temp[0]} .= "\t".$temp[1].":".$temp[2];
    } 
  }
  close IN0;

}

sub readFasta {
   my ($in0, $id2seq) = @_;
   open IN0, $in0;
   my $id = "";
   while(<IN0>){
   chomp;
     if(/^(>\S+)/ && not exists $id2seq ->{$id}){
        $id = $1;
        $id2seq ->{$id} = "";
     }
     else{
        $id2seq ->{$id} .= $_;
     }
   }   
   close IN0;

}


__END__
