#!/usr/bin/perl

use Getopt::Long;
use Time::ParseDate;
use FileHandle;

use stock_data_access;

$close=1;

$field1='close';
$field2='close';

&GetOptions( "field1=s" => \$field1,
	     "field2=s" => \$field2,
	     "from=s"   => \$from,
	     "to=s"     => \$to,
             "simple"   => \$simple,
	     "corrcoeff"=>\$docorrcoeff);

if (defined $from) { $from=parsedate($from);}
if (defined $to) { $to=parsedate($to); }


$usage = "usage: get_covar.pl [--field1=field] [--field2=field] [--from=time] [--to=time] [--simple (two symbols only)] [--corrcoeff] SYMBOL SYMBOL+\n";
$#ARGV>=1 or die $usage;


@symbols=@ARGV;


for ($i=0;$i<=$#symbols;$i++) {
  $s1=$symbols[$i];
  for ($j=$i; $j<=$#symbols; $j++) {
    $s2=$symbols[$j];
    
#first, get means and vars for the individual columns that match
    
    $sql = "select count(*),avg(l.$field1),stddev(l.$field1),avg(r.$field2),stddev(r.$field2) from ".GetStockPrefix()."StocksDaily l join ".GetStockPrefix()."StocksDaily r on l.timestamp= r.timestamp where l.symbol='$s1' and r.symbol='$s2'";
    $sql.= " and l.timestamp>=$from" if $from;
    $sql.= " and l.timestamp<=$to" if $to;
    
    ($count, $mean_f1,$std_f1, $mean_f2, $std_f2) = ExecStockSQL("ROW",$sql);
    
    #skip this pair if there isn't enough data

    if ($count<30) { # not enough data
      $covar{$s1}{$s2}='NODAT';
      $corrcoeff{$s1}{$s2}='NODAT';
    } else {
      
      #otherwise get the covariance

      $sql = "select avg((l.$field1 - $mean_f1)*(r.$field2 - $mean_f2)) from ".GetStockPrefix()."StocksDaily l join ".GetStockPrefix()."StocksDaily r on  l.timestamp=r.timestamp where l.symbol='$s1' and r.symbol='$s2'";
      $sql.= " and l.timestamp>= $from" if $from;
      $sql.= " and l.timsetamp<= $to" if $to;

      ($covar{$s1}{$s2}) = ExecStockSQL("ROW",$sql);

#and the correlationcoeff

      $corrcoeff{$s1}{$s2} = $covar{$s1}{$s2}/($std_f1*$std_f2);
    }
  }
}

if ($simple && $#symbols==1) {
  $s1=$symbols[0];
  $s2=$symbols[1];
  if ($docorrcoeff) {
    print $corrcoeff{$s1}{$s2} eq "NODAT" ? "NODAT" : sprintf('%3.2f',$corrcoeff{$s1}{$s2});
  } else {
    print $covar{$s1}{$s2} eq "NODAT" ? "NODAT" : sprintf('%3.2f',$covar{$s1}{$s2});
  }
  print "\n";
} else {
  if ($docorrcoeff) {
    print "Correlation Coefficient Matrix\n";
  } else {
    print "Covariance Matrix\n";
  }
  print "Rows: $field1\nCols: $field2\n\n";
  
  print join("\t","-----",@symbols),"\n";
  
  for ($i=0;$i<=$#symbols;$i++) {
    $s1=$symbols[$i];
    print $s1;
    for ($j=0; $j<=$#symbols;$j++) {
      if ($i>$j) {
        print "\t.";
      } else {
        $s2=$symbols[$j];
	if ($docorrcoeff) {
	  print "\t", $corrcoeff{$s1}{$s2} eq "NODAT" ? "NODAT" : sprintf('%3.2f',$corrcoeff{$s1}{$s2});
	} else {
	  print "\t", $covar{$s1}{$s2} eq "NODAT" ? "NODAT" : sprintf('%3.2f',$covar{$s1}{$s2});
	}
      }
    }
    print "\n";
  }
}


