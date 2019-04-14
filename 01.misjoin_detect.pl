#!/usr/bin/perl

##-Author: Xu Cai
##-Bug report: caixu0518@163.com

use warnings;
use strict;
use Getopt::Long;

##-Usage-----------------------------------------

my $usage=<<USAGE;

    Usage: perl $0 -matrix <matrix file> -bed <bed file> -Scfsizes <scaffolds sizes> -binsize <bin size> -R1 [Ratio1] -R2 [Ratio2]

    -matrix     [required]  contain the whole genome contact information (HIC-PRO output file).
    -bed        [required]  A list of genomic intervals related to the specified resolution (HIC-PRO output file).
    -Scfsizes   [required]  Length of each scaffold. two columns(scaffold id,  scaffold length).
    -binsize    [required]  Resolution size.

    -R1         [optional]  This parameter is used to find breakpoints.
    -R2         [optional]  This parameter is used to find breakpoints.

USAGE

##-input data------------------------------
my ($in0,$in1,$in2,$binsize, $NearbyRatio, $NearbySumRatio);

GetOptions(
	"matrix:s"=>\$in0,
	"bed:s"=>\$in1,
	"Scfsizes:s"=>\$in2,
	"binsize:s"=>\$binsize,
        "R1:s"=>\$NearbyRatio,
        "R2:s"=>\$NearbySumRatio,

);

die $usage if (!defined $in0 || !defined $in1 || !defined $in2 || !defined $binsize);
    $NearbyRatio = 10, if(!defined $NearbyRatio);
    $NearbySumRatio = 15,  if(!defined $NearbySumRatio);


##-main process----------------------------------------   
    &main;
sub main {
  my %bin2bin = ();
  my $binNum = 0;
     &read_matrix($in0, \$binNum, \%bin2bin);

  my @candidateScf = ();
     &read_scf($in2, \@candidateScf);   
     print "There are ", scalar(@candidateScf)," scaffolds need to be checked.\n";

  my $out = "misjoin.bin.list";
     &output(\@candidateScf, $in1, \%bin2bin, $out);
  
  my $misScf = "misjoin_scfs.list";
     &outStat($out, $misScf);
  print "the detection of scaffolds misjoin is over. Please check $misScf for details.\n";

}

##-all subs-------------------------------------------------------------------------------------------------------------
sub outStat {
  my ($out, $misScf) = @_;
   
  open OUT, ">$misScf";
  my %scfs = ();
  my ($numScfs, $numBreakpoints) = (0,0);
  open IN, $out;
  while(<IN>){
    chomp;
    $numBreakpoints += 1;
    my $scf = (split(/\t/, $_))[0];
    if(not exists $scfs{$scf}){
       $scfs{$scf} = "Y";
       $numScfs += 1;
       print OUT $scf, "\n";
    }
    else{
       next;
    }
  }
  close IN;
  close OUT;
  print "Number of breakpoints: $numBreakpoints\n";
  print "Number pf misjoin scaffolds: $numScfs\n";

}


sub output {
  my ($candidateScf, $bedFile, $bin2bin, $out) = @_;

  my $numScf = scalar(@{$candidateScf});
  for(my $i=0; $i<= ($numScf - 1); $i+=1){
      &read_each_scf($candidateScf ->[$i], $bedFile, $bin2bin);
  }
  
  system("rm $out") if(-f $out);
  my $allScfs = "each_scf.all";
  system("rm -r $allScfs") if(-e $allScfs);
  system("mkdir $allScfs");

  for(my $i=0; $i<= ($numScf - 1); $i+=1){
      my $breakFile = $candidateScf ->[$i];
      my $allfile = $candidateScf ->[$i].".all";
      system("cat $breakFile >> $out");
      system("mv  $breakFile  $allfile  $allScfs");
  }

}

sub read_each_scf{
  my ($scfname, $bedFile, $bin2bin) = @_;

  my %bin2region = ();
  open IN1, $bedFile;
  while(<IN1>){
    chomp;
    my @temp = split("\t", $_);
       $bin2region{$temp[3]} = $temp[0]."\t".$temp[1]."\t".$temp[2], if($temp[0] eq $scfname);
  }
  close IN1;

   my %binValue = ();
   my %filledValue = ();
   my %filledNum = ();
   my @binBed = sort {$a<=>$b} keys %bin2region; 
   my @bin = ($binBed[0]..$binBed[-1]);
   my @binSearch = @bin;
   for my $first_bin(@bin){
     shift(@binSearch);
     for(my $n=1; $n<=$#binSearch; $n++){
         if((exists $bin2bin ->{$first_bin} ->{$binSearch[$n -1]}) || (exists $bin2bin ->{$first_bin} ->{$binSearch[$n]})){

           ##- record filled and missing bin (exists bin and missing last bin)
           if((exists $bin2bin ->{$first_bin} ->{$binSearch[$n - 1]}) && (not exists $bin2bin ->{$first_bin} ->{$binSearch[$n]})){

              ##- record filled bin and missing bin info
              if(not exists $filledValue{$binSearch[$n -1]} || not exists $filledNum{$binSearch[$n -1]}){
                 $filledValue{$binSearch[$n -1]} = $bin2bin ->{$first_bin} ->{$binSearch[$n - 1]}, if(not exists $filledValue{$binSearch[$n -1]});
                 $filledNum{$binSearch[$n -1]} =1, if(not exists $filledNum{$binSearch[$n -1]});
              }
              else{
                 $filledValue{$binSearch[$n -1]} += $bin2bin ->{$first_bin} ->{$binSearch[$n - 1]};
                 $filledNum{$binSearch[$n -1]} += 1;
              }
           }

           ##- record filled and missing bin (exists last bin and missing bin)
           elsif((not exists $bin2bin ->{$first_bin} ->{$binSearch[$n - 1]}) && (exists $bin2bin ->{$first_bin} ->{$binSearch[$n]})){

              ##- record filled bin and missing bin info
              if(not exists $filledValue{$binSearch[$n]} || not exists $filledNum{$binSearch[$n]}){
                 $filledValue{$binSearch[$n]} = $bin2bin ->{$first_bin} ->{$binSearch[$n]}, if(not exists $filledValue{$binSearch[$n]});
                 $filledNum{$binSearch[$n]} = 1, if(not exists $filledNum{$binSearch[$n]});
              }
              else{
                    $filledValue{$binSearch[$n]} += $bin2bin ->{$first_bin} ->{$binSearch[$n]};
                    $filledNum{$binSearch[$n]} += 1;
              }
           }
           ##------------------------------------------------------------------------------------------------------------------
           else{
=pop
              if(not exists $filledValue{$binSearch[$n -1]} && not exists $filledNum{$binSearch[$n -1]}){
                 $filledValue{$binSearch[$n -1]} = $bin2bin ->{$first_bin} ->{$binSearch[$n - 1]};
                 $filledNum{$binSearch[$n -1]} = 1;
              }
              else{
                 $filledValue{$binSearch[$n -1]} += $bin2bin ->{$first_bin} ->{$binSearch[$n - 1]};
                 $filledNum{$binSearch[$n -1]} += 1;
              }
=cut
              ##-----------------------------------------------------------------------------------------------------------
              if(($bin2bin ->{$first_bin} ->{$binSearch[$n]} == 0) || ($bin2bin ->{$first_bin} ->{$binSearch[$n -1]} == 0)){
                 next;
              }
              else{
                 my $result = ($bin2bin ->{$first_bin} ->{$binSearch[$n -1]})/($bin2bin ->{$first_bin} ->{$binSearch[$n]});
                 if(not exists $binValue{$n -1}{$n}){
                    $binValue{$binSearch[$n -1]}{$binSearch[$n]} = $result;
                 }
                 else{
                    $binValue{$binSearch[$n -1]}{$binSearch[$n]} .= ";".$result;
                 }
              }
           }
           ##-------------------------------------------------------------------------------------------------------------------------
         }
         else{
           next;  ##- skip all blank bin...
         }
     }    
   }

   ##- print outliers
   open OUT, ">$scfname";
   open OUT1, ">$scfname.all";
   for(my $n=1; $n<=$#bin; $n++){
       my ($key1, $key2) = ($bin[$n -1], $bin[$n]);
       my ($avg, $filledRatio) = (0, 0);
       my @first = split("\t", $bin2region{$key1});
       my @second = split("\t", $bin2region{$key2});

       if(exists $binValue{$key1}{$key2}){
          my @temp = split(/;/, $binValue{$key1}{$key2});
             &average(\@temp, \$avg); 
         
          ##-------------------------------------------------------------
          if(exists $filledValue{$key1} && exists $filledValue{$key2}){
             $filledRatio = $filledValue{$key1}/$filledValue{$key2};
          }elsif(exists $filledValue{$key1} && exists $filledNum{$key1} && $filledNum{$key1} >= 10 && not exists $filledValue{$key2}){ ##- it depends___
             $filledRatio = 0; ##- blank and reliable bin __false positive
          }else{
             $filledRatio = 0;
          }
          $filledValue{$key1} = "NA", if(not defined $filledValue{$key1});
          #$filledValue{$key2} = "NA", if(not defined $filledValue{$key2});

          ##-------------------------------------------------------------
          print OUT1 join("\t", $first[0], $first[1], $first[2], $second[2], $avg, $filledRatio), "\n";
          if($avg >= $NearbyRatio  || $filledRatio >= $NearbySumRatio){
             print OUT join("\t", $first[0], $first[1], $first[2], $second[2], $avg, $filledRatio), "\n";
          }
       }
       else{
          if(exists $filledValue{$key1} && exists $filledValue{$key2}){
             $filledRatio = $filledValue{$key1}/$filledValue{$key2};
          }elsif(exists $filledValue{$key1} && $filledNum{$key1} >= 20 && not exists $filledValue{$key2}){ ##- it depends___
             next, if($key2 == $bin[-1]);
             $filledRatio = 1000; 
          }else{
             $filledRatio = 0;
          }            
          print OUT1 join("\t", $first[0], $first[1], $first[2], $second[2], $avg, $filledRatio), "\n";
          if($filledRatio >= $NearbySumRatio){
             print OUT join("\t", $first[0], $first[1], $first[2], $second[2], "NA", $filledRatio), "\n";
          }
       }        
   }   
   close OUT;
   close OUT1;

}

sub read_scf {
  my($scf, $candidateScf) = @_;
  
  open IN2, $scf;
  while(<IN2>){
    chomp;
    my @temp = split("\t", $_);
    push(@{$candidateScf}, $temp[0]), if($temp[1] >= 2*$binsize);
  }
  close IN2;

}

sub average {
  my ($array, $avg) = @_;

  my ($num, $sum);
  for my $element(@{$array}){
    if($element =~ /^[0-9]/){
       $num += 1;
       $sum += $element;
    }
    else{
       next;
    }
  }
  $$avg = $sum/$num;

}

sub read_matrix {
  my ($matrixFile, $binNum, $bin2bin) = @_;
  
  open IN0, $matrixFile;
  while(<IN0>){
    chomp;
    my @temp = split("\t", $_);
    if(not exists $bin2bin ->{$temp[0]} ->{$temp[1]}){
       $bin2bin ->{$temp[0]} ->{$temp[1]} = $temp[2];
    }
    else{
       die "Error: $temp[0] to $temp[1] have been detected.\n";
    }
  }
  close IN0;

}

__END__
