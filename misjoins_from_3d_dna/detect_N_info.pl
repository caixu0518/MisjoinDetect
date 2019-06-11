#!/usr/bin/perl -w
##- Xu Cai
use strict;

my $in0 = $ARGV[0]; ##- scaffolds fasta  file
 
   &main;
sub main {

my %id2seq = ();
   &readFasta($in0, \%id2seq);

my $output = "Gap_info.list";
   &output(\%id2seq, $output);

}


sub output {
  my($id2seq, $out) =@_;
  
  my %gapinfo = ();
  for my $key(sort keys %{$id2seq}){
    &N_pos(\$key, $id2seq ->{$key}, \%gapinfo);
  }
   
  open OUT1, ">$out";
  for my $key1(sort keys %gapinfo){ 
    print OUT1 $key1, "\t", $gapinfo{$key1}, "\n";
  }
  close OUT1;

}

sub N_pos {
  my ($stingName, $string, $gapinfo) = @_;   #-string name, string sequence and gap infor ##- print N information in this string, including gap length, start posiiotn and stop position
  
  if($string =~ /N/){
    my ($N_Len, $end, $start);
    while($string =~ /(N+)/g){
      $N_Len = length($1);
      $end = pos($string);  # start position is 1
      $start = $end - $N_Len + 1;
      if(not exists $gapinfo ->{$$stingName}){
         $gapinfo ->{$$stingName} = $start."..".$end;
      }
      else{
         $gapinfo ->{$$stingName} .= ";".$start."..".$end;
      }
      #print $N_Len."\t".$start."\t".$end, "\n";
    }
  }
  else{
    $gapinfo ->{$$stingName} = "No_gap";
  }
}

sub readFasta {
  my ($in,$id2seq) = @_;
  open(my $SFR,$in);

  my $id;
  while($_=<$SFR>) {
    if(/^>([^\s^\n]+)\s*\n*/) {
      $id = $1;
      $id2seq->{$id} = "";
    }
    else {
      chomp;
      $id2seq->{$id} .= $_;
    }
  }
  close($SFR);
}
