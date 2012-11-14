#!/usr/bin/perl -w

use Getopt::Long;
use Time::ParseDate;
use Time::CTime;
use FileHandle;

use stock_data_access;

$close=1;

$notime=0;
$open=0;
$high=0;
$low=0;
$close=0;
$vol=0;
$from=0;
$to=0;
$plot=0;

&GetOptions( "notime"=>\$notime,
             "open" => \$open,
	     "high" => \$high,
	     "low" => \$low,
	     "close" => \$close,
	     "vol" => \$vol,
	     "from=s" => \$from,
	     "to=s" => \$to, "plot" => \$plot);
	     
$usage = "usage: get_data.pl [--open] [--high] [--low] [--close] [--vol] [--from=time] [--to=time] [--plot] SYMBOL\n";

$#ARGV == 0 or die $usage;

$symbol = shift;

push @fields, "timestamp" if !$notime;
push @fields, "open" if $open;
push @fields, "high" if $high;
push @fields, "low" if $low;
push @fields, "close" if $close;
push @fields, "volume" if $vol;


my $sql;

$sql = "select " . join(",",@fields) . " from ".GetStockPrefix()."all_stockdailys";
$sql.= " where symbol = '$symbol'";
$sql.= " and timestamp >= $from" if $from;
$sql.= " and timestamp <= $to" if $to;
$sql.= " order by timestamp";

my $data = ExecStockSQL("TEXT",$sql);

if (!$plot) { 
  print $data;
} else {

  open(DATA,">_plot.in") or die "Cannot open temporary file for plotting\n";
  print DATA $data;
  close(DATA);

  open(GNUPLOT, "|gnuplot") or die "Cannot open gnuplot for plotting\n";
  GNUPLOT->autoflush(1);
  print GNUPLOT "set title '$symbol'\nset xlabel 'time'\nset ylabel 'data'\n";
  print GNUPLOT "plot '_plot.in' with linespoints;\n";
  STDIN->autoflush(1);
  <STDIN>;
}


