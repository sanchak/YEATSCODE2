
package MyQPaper;
use Carp ;
use MyUtils ;
use POSIX ;
require Exporter;
use Algorithm::Combinatorics qw(combinations) ;
use Math::NumberCruncher;
use Math::MatrixReal;  # Not required for pure vector math as above
use Math::Geometry ; 
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors
#use Math::Trig;
#use Math::Trig ':radial';
no warnings 'redefine';
my $EPSILON = 0.01;

  local $SIG{__WARN__} = sub {};

@ISA = qw(Exporter);
@EXPORT = qw( 
QP_round2place
QP_GetNRandomNumbersBelowValue
QP_GetNRandomNumbersBelowValueBothSign
QP_GetNRandomNumbersBetweenValues
QP_GetNRandomNumbersBelowValueSorted
QP_InsertCorrectAnswer
QP_GetNRandomNumbersBetweenValues
QP_Find_N_numbers_that_addupto
CONVERTSPEED
	    );

use strict ;
use FileHandle ;
use Getopt::Long;


sub QP_round2place{
    my ($num) = (@_);
    $num = $num*100 ;

    $num = util_round($num);
    $num = $num/100.0;
    return $num ;
}

sub QP_GetNRandomNumbersBelowValue{
    my ($n1,$n2) = @_ ; 
	my @l ; 
	my $done = {};
	while($n1){
        my $a = floor($n2*rand())+1;
		next if(exists $done->{$a});
		$done->{$a} = 1 ; 
		push @l , $a ;
		$n1--;
	}
	return @l ;
}

sub QP_GetNRandomNumbersBetweenValues{
    my ($n1,$n2,$n3) = @_ ; 
	die "Please give sorted" if($n2 > $n3);
	my $diff = abs($n3 - $n2);
	my @l = QP_GetNRandomNumbersBelowValue($n1,$diff);
	my @x ; 
	foreach my $i (@l){
		my $y = $i + $n2 ; 
		push @x, $y ;
	}
	return @x ;
}

sub QP_GetNRandomNumbersBelowValueBothSign{
    my ($n1,$n2) = @_ ; 
	my @l ; 
	my $done = {};
	while($n1){
        my $a = floor($n2*rand())+1;
        my $celprob = util_round(rand());
		if($celprob){
			$a = -1 * $a ;
		}
		next if($a eq 0);
		next if($a eq 1);
		next if(exists $done->{$a});
		$done->{$a} = 1 ; 
		push @l , $a ;
		$n1--;
	}
	return @l ;
}

sub QP_GetNRandomNumbersBelowValueSorted{
    my ($n1,$n2) = @_ ; 
	my @l ; 
	my $done = {};
	while($n1){
        my $a = floor($n2*rand())+1;
		next if(exists $done->{$a});
		$done->{$a} = 1 ; 
		push @l , $a ;
		$n1--;
	}
	my @sl = sort {$a <=> $b}  @l;
	return @sl ;
}


sub QP_InsertCorrectAnswer{
	my ($ans,@WA) = @_ ; 
	my $N = @WA ;
	my $idx = floor (($N+1)*rand()) ;
	my @ANSLIST ; 
	foreach my $i (0..$N){
		if($i eq $idx){
			push @ANSLIST, $ans ;
		}
		else{
			my $x = shift @WA ;
			push @ANSLIST, $x ;
		}
	}
	#print "There were $N wrong answers.$idx is the index with the right ansewer\n";
	return (\@ANSLIST,$idx);
}
sub CONVERTSPEED  {
    my ($M1,$M2)         =  QP_GetNRandomNumbersBelowValue(2,6);
    my $x = 9 *$M1 ;
    my $a = ($x*1000)/3600; 
	
    my @WA ;
    my $question ="Convert $x km/hr to metre/sec  " ;
    my $answer = "$a metre/sec"; 
	my $WA1 = $a +10  ;
	my $WA2 = $a +5  ;
    my $hint = " Do unitary method. In 1hr (60*60 secs) distance covered is X km, therefore in 1 sec how many Kms? Then convert Km to metre.   ";
    push @WA , "$WA1 metre/sec" ;
    push @WA , "$WA2 metre/sec";
    my ($ANSLIST,$correctindex) = QP_InsertCorrectAnswer($answer,@WA);
    ($question,$answer,$hint,$ANSLIST,$correctindex);
}

sub QP_Find_N_numbers_that_addupto{
	my ($sum,$N) =@_ ; 
	my $del = $sum/($N -1);
    my @numbers;
	my $done = 0 ;
	while(!$done){
		@numbers = ();
	    my $tmpsum = 0 ; 
	    foreach my $i (1..$N-1){
            my $x = 0  ; 
			while(!$x){
			     $x = floor($del*rand()) ;
			}
		    push @numbers, $x ; 
		    $tmpsum = $tmpsum + $x ; 
	    }
		if($tmpsum < $sum){
			my $x = $sum - $tmpsum ; 
		    push @numbers, $x ; 
			$done = 1 ;
		}
	}
	return @numbers ;
}
