#!/usr/bin/perl

##- Author: Xu Cai
##- Bug report: caixu0518@163.com

use warnings;
use strict;
use Getopt::Long;

##-Usage-----------------------------------------

my $usage=<<USAGE;

   Usage: perl $0  -fasta <raw scaffolds in fasta format> -breakpoint <corrected breakpoints list> -out [corrected scaffolds in fasta format]

   -fasta        [required] The original scaffolds in fasta format (including misjoin scaffolds).
   -breakpoint   [required] Breakpoints information.

   -out          [optional] Corrected scaffolds in fasta format.

USAGE

#--Initialize input data-------------------------

my ($in0, $in1, $out);

GetOptions(
	"fasta:s"=>\$in0,
	"breakpoint:s"=>\$in1,
	"out:s"=>\$out,
);

die $usage, if (!defined $in0 || !defined $in1);
$out ||= $in0.".corrected.fa";

##-Process------------------------------------------------

    &main();

sub main {

  my %id2seq = ();
     &readFasta($in0, \%id2seq);

  my %corrected_scf = ();
     &break_scf($in1, \%id2seq, \%corrected_scf);

  ##- generate the corrected scaffolds
  &output(\%corrected_scf, $out);

}


##-all subs------------------------------------------------

sub output {
  my ($corrected_scf, $out) = @_;
  
  open OUT, ">$out";
  print OUT  ">", $_, "\n", $corrected_scf ->{$_}, "\n", for(sort keys %{$corrected_scf});
  close OUT;

}

sub break_scf {

  my ($breakpointFile, $id2seq, $corrected_scf) = @_;
  
  my %misScf = ();
  open IN0, $breakpointFile;
  while(<IN0>){
    chomp;
    my @temp = split(/\t/, $_);
    my $id = shift(@temp);
    my $mis_pos = join("\t", @temp);
       $misScf{$id} = $mis_pos;
  }
  close IN0;

  for my $key(sort keys %{$id2seq}){
    if(not exists $misScf{$key}){
       $corrected_scf ->{$key} = $id2seq ->{$key};
    }
    else{ 
       ##- break scaffold
       my @coords;
       push(@coords, 1);
       my @element = split(/\t/, $misScf{$key}); ##- get multi-breakpoints
       # print join("\t", @element), "\n"; 
       push(@coords, sort {$a<=>$b} @element);
       push(@coords, length($id2seq ->{$key}));
      
       my $fragment_Num = 0;
       for(my $n=0; $n<$#coords; $n++){
           my ($start, $end, $tempSeq);
              ($start, $end) = ($coords[$n], $coords[$n+1] - 1);
              ($start, $end) = ($coords[$n], $coords[$n+1]), if($n == $#coords -1);
               $tempSeq = substr($id2seq ->{$key}, $start -1, $end - $start +1);
               $tempSeq =~ s/^(N+)//; 
               $tempSeq =~ s/(N+)$//;        
  
           if($tempSeq =~ /[AGTC]/){
              $fragment_Num += 1;
              my $new_id = $key."_$fragment_Num";
              $corrected_scf ->{$new_id} = $tempSeq, if(not exists $corrected_scf ->{$new_id});
           }
           else{
              next;
           }
       }
    }
  }

}

sub readFasta {

   my ($in0, $id2seq) = @_;

   open IN0, $in0;
   my $id = "";
   while(<IN0>){
   chomp;
     if(/^>(\S+)/){
        $id = $1;
        if(not exists $id2seq ->{$id}){
           $id2seq ->{$id} = "";
        }
     }
     else{
        $id2seq ->{$id} .= $_; 
     }
   }
   close IN0;

}

__END__
