#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;
use Primer;
  use Bio::Tools::CodonTable;
 my $myCodonTable   = Bio::Tools::CodonTable->new();
 

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($FFF,$RRR,$forward,$reverse,$infile,$outfile,$which_tech,$listfile,$protein,$junk);
my (@expressions,@indices,@towhichresidue,@junk);
my $howmany = 100000 ;
my $verbose = 1 ;
my $TEMP = 78 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "towhichresidue=s"=>\@towhichresidue ,
            #"idx=i"=>\$idx ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "indices=i"=>\@indices,
            "howmany=i"=>\$howmany ,
            "forward=s"=>\$forward ,
            "reverse=s"=>\$reverse ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
util_CmdLine("outfile",$outfile);

my @sortindices = sort { $a <=> $b} @indices ; 
die "Need to specifiy indices " if(@indices == 0);
die "Need to to which residues indices " if(@towhichresidue == 0);
my $l1 = @sortindices -1 ;
my $l2 = @towhichresidue -1 ;
die " Give equal number of indices and to which residues" if($l1 != $l2);

foreach my $i (0..$l1){
	my $a = $indices[$i];
	my $b = $sortindices[$i];
	die "Please give sorted indices $a $b" if($a != $b);
}

my $minidx = ($indices[0]) *3 - 10 ;
my $maxidx = ($indices[$l1]*3) + 11 + 3 ; 

print" $minidx = ($indices[0] ) *3 - 10 ;\n";
print" $maxidx = ($indices[$l1]*3) + 11 ; \n";


print "Reading $infile\n";
my $ofh = util_write($outfile);
my ($line,$len,@l) = ReadSeq($infile,1);
if(defined $forward){
   ($FFF,$junk,@junk) = ReadSeq($forward,1);
   ($RRR,$junk,@junk) = ReadSeq($reverse,1);
}

## make index to start from 1 
my @junk = qw ( JJJ  );
my @origSeq = (  @junk , @l );

$len = @origSeq -1 ;

my $ccc = 0 ; 
foreach my $idx (1..$len){
	  my $i = $origSeq[$idx] or die "$idx index not found";
      my  $aaName = $myCodonTable->translate($i);
	  print "$aaName";
	  print $ofh "$aaName";
	  print $ofh "," if($ccc++%8 == 0);
}
	  print "\n";
print $ofh "\n";
$ccc = 0 ; 
foreach my $i (@origSeq){
	  next if($ccc++ == 0);
	  print $ofh "$i";
	  print $ofh "," if($ccc%4 == 0);
}
print $ofh "\n";

print @origSeq, "\n";


my $cnt = @indices - 1 ;
my $seq = \@origSeq ;
my @sequences = ( $seq, 0) ;
foreach my $i (0..$cnt){
	  my $idx = $indices[$i];
      my $from = $origSeq[$idx];
      my  $aaName = $myCodonTable->translate($from);
	  my $to = $towhichresidue[$i]; 
	  PrintInfo($idx,$from,$to,$seq,$len,$myCodonTable,$ofh) ; 
}


foreach my $i (0..$cnt){
	  my $idx = $indices[$i];
      my $from = $origSeq[$idx];
      my  $aaName = $myCodonTable->translate($from);
	  my $to = $towhichresidue[$i]; 

	  print $ofh "Info:Need to change $aaName to $to \n";

	  my @thisroundseq ; 
	  while($seq = shift @sequences){
	      my $score =  shift @sequences;
	      my @singleAAseqs = ReplaceSingleAA($idx,$from,$to,$seq,$score,$len,$myCodonTable,$ofh) ; 
		  push @thisroundseq, @singleAAseqs ;
	  }
	  @sequences = @thisroundseq ; 
}


my $codon2Changes = {};
$, = " , " ;
my $width = 30 ; 
my $counter = 0 ; 


foreach my $width (25..50){
     my $modWidth = $width - 3 ; 
     my @copyseq = @sequences ;
     while($seq = shift @copyseq){
	       my $score =  shift @copyseq;
	       my @ss = @{$seq};
	       print " score = $score\n";
	       my $idx = $indices[0];
	       my $l = 10;
	       my $r = $modWidth - 10 ;
	       while($l < ($modWidth - 10)){
		      $counter++;
	          my ($window,$pre,$mid,$post,$L,$R) = GetWindowNucleotide($idx,$l,$r,@{$seq});
		      #warn "found" if($window eq "cgtgagcggataaaatcaaaattaagggcggcgttccaaccc");
	 	      print "===== New Sequence ========\n";
		      if($L > $minidx || $R < $maxidx ){
		 	     print "ignored $L > $minidx || $R < $maxidx \n";
		      }
		      else{
		           if(defined $window){
		               if(0 && ($pre =~ /^(a|t)/i || $pre =~ /^.(a|t)/i || $post =~ /(a|t)$/i || $post =~ /^(a|t).$/i)  ){
			 	          print "Ignored due to at in begining or end\n";
			           }
			           else{
		                  my $GCCount_percent = GetGCCountPercent($window,$width); 
		                  my $mismatchpercent = util_format_float(($score * 100)/$width,3) ;
		                  my $temp  = GetTemperature($GCCount_percent,$mismatchpercent,$width);
				          if($temp > $TEMP){
     
				              my $beginwith = GetHowManyToBeginWith($pre);
				              my $revpost = reverse($post);
				              my $endwith = GetHowManyToBeginWith($revpost);
	                          print "\t\t $pre $mid $post temp = $temp begin = $beginwith end = $endwith rev post $revpost  \n";
	                          print "$window,$pre,$mid,$post,$L , $R, $minidx , $maxidx\n";
			                  my @ret = SplitPostIntoPieces($post,@indices);
			                  print " RET = " , @ret , " \n";
					          print "width = $width , numberofchanges =$score GCCount_percent = $GCCount_percent , mismatchpercent = $mismatchpercent \n";
              
					          my $full = $pre . $mid . $post ;
					          my $revStr = reverse($window);
					          my $rev = GetComplementary($revStr);
         
	                          $codon2Changes->{$counter}->{WIDTH} = $width;
	                          $codon2Changes->{$counter}->{SCORE} = $score;
	                          $codon2Changes->{$counter}->{TEMP} = $temp;
	                          $codon2Changes->{$counter}->{GCCOUNT} = $GCCount_percent;
	                          $codon2Changes->{$counter}->{MISMATCHPERCENT} = $mismatchpercent;
	                          $codon2Changes->{$counter}->{PRE} = $pre;
	                          $codon2Changes->{$counter}->{MID} = $mid;
	                          $codon2Changes->{$counter}->{POST} = \@ret ; 
	                          $codon2Changes->{$counter}->{GCBEGIN} = $beginwith;
	                          $codon2Changes->{$counter}->{GCEND} = $endwith;
	                          $codon2Changes->{$counter}->{WINDOW} = $window;
	                          $codon2Changes->{$counter}->{REV} = $rev;
    
						      ## check for a given primer 
						      if(defined $forward){
							  	 die "Need reverse too" if(!defined $reverse);
		                         if($window eq $FFF){
							  	    die "reverse doesnt match" if($RRR ne $rev);
									print "Info: Primer found. Hence quitting\n";
									exit ;
								 }
						      }
				          }
				          else{
			 	            print "Ignored due to temp $temp which is less than $TEMP\n";
				          }
     
     
			      }
		      }
		      }
		      #die "found" if($window eq "cgtgagcggataaaatcaaaattaagggcggcgttccaaccc");
	          $l++;
	          $r--;
	      }
     }
}

if(defined $forward){
	# you should not be getting here 
	die "Primer $forward not found" ;
}


	print $ofh "WIDTH,   number of changes , TEMP, GCCOUNT , MISMATCHPERCENT , GC in begin , GC in end,  seq , revseq, seq till 1st mutation, 1st mutation  \n";
foreach my $counter (sort  { $a <=> $b } keys %{$codon2Changes}){

	print $ofh "$codon2Changes->{$counter}->{WIDTH},   $codon2Changes->{$counter}->{SCORE} , $codon2Changes->{$counter}->{TEMP} , $codon2Changes->{$counter}->{GCCOUNT} , $codon2Changes->{$counter}->{MISMATCHPERCENT} , $codon2Changes->{$counter}->{GCBEGIN} , $codon2Changes->{$counter}->{GCEND},  $codon2Changes->{$counter}->{WINDOW} , $codon2Changes->{$counter}->{REV}, $codon2Changes->{$counter}->{PRE}, $codon2Changes->{$counter}->{MID}  \n";

}



sub SplitPostIntoPieces{
	my ($post,@indices) = @_ ; 
	my $len = length($post);
	my $initial = shift @indices ; 
	my @ret ;
	my $start = 0 ; 
	foreach my $i (@indices){
		my $d = $i - $initial; 
		my $reald = $d - 1;  ## think about it - 13 and 14 should start with a null string
		my $end = $reald *3 ; 
		my $s1 =  substr($post,$start,$end);
		#print " $start $end $d $reald \n" ;;;
		$start = $start + $end;
		$end = 3 ;
		#print " $start $end $d $reald \n" ;;;
		my $s2 =  substr($post,$start,$end);
		$start = $start + $end;
		#print "$s1 $s2 $start \n";

		push @ret , $s1 ;
		push @ret , $s2 ;
	}
	if($start < $len){
		my $end = $len - $start ; 
		my $s2 =  substr($post,$start,$end);
		push @ret , $s2 ;

	}
	return @ret ; 
}



