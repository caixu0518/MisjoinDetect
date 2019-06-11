#!/usr/bin/perl -w
use strict;
##- Xu Cai

my $in0 = $ARGV[0]; ##- B9008.genome.scf.fasta.corrected.0_asm.scaffold_track.txt
my $in1 = $ARGV[1]; ##- mismatch_narrow.bed
my $out = $in1.".breakpoints";

my %Scf2info = ();
my @AsmArray = ();
   &read_asm($in0, \%Scf2info);

   &scf2info(\%Scf2info, $in1, $out);


##-----------------------------------------------------------------------

sub scf2info {

    my ($scf2info, $bed, $out) = @_;

    open OUT0, ">$out";
    open IN1, $bed;
    while(<IN1>){
      chomp;
      my @temp = split(/\t/, $_);
      for my $key1(sort {$a<=>$b} keys %{$scf2info}){
          for my $key2(keys %{$scf2info ->{$key1}}){
              if($key1 <= $temp[1]&& $key2 >= $temp[2]){
                   my ($newS, $newE) = ($temp[1], $temp[2]);
                   if($scf2info ->{$key1} ->{$key2} =~ /-/){
                      ($newS, $newE) = ($key2 - $temp[2], $key2 - $temp[1]);   
                   }
                   else{
                      ($newS, $newE) = ($temp[1]-$key1, $temp[2]-$key1);
                   }
                   my $scfId = 'NA';
                   if($scf2info ->{$key1} ->{$key2} =~ /^(\S+)/){
                      $scfId = $1;
                   }
                   print OUT0 join("\t", $scfId, $newS, $newE), "\n", if($key2 - $key1 >= 50000);  ##- filter short sequences (lower than 100000 bp)
                   last;
              }
          }
      }
    }
    close IN1;
    close OUT0;
 
}


sub read_asm {

    my ($asm, $scf2info) = @_;

    open IN0, $asm;
    <IN0>; ##- skip tile
    while(<IN0>){
      chomp;
      my ($scfinfo, $start, $end) = (split(/\t/, $_))[7, 8, 9];
      my ($scfid, $strand);
      if($scfinfo =~ /(\S)(\S+)/){
         ($scfid, $strand) = ($2, $1);
      }     
      else{
         die "code 1.\n";
      } 
      $scf2info ->{$start} ->{$end} = $scfid."\t".$strand;
    }
    close IN0;

}
