#!/usr/bin/perl -w

use Time::ParseDate;
use Getopt::Long;

use stock_data_access;

$count=1;
$mindays=0;
$from=0;
$to=0;
&GetOptions("count=i"=>\$count, "mindays=i"=>\$mindays, "from=s"=>\$from, "to=s"=>\$to);


#$usage = "usage: get_random_symbol.pl [--count=i] [--mindays=i] [--from=time] [--to=time]\n";

if ($ENV{PORTF_DBMS} eq "mysql") {
  $sql="select symbol from ".GetStockPrefix()."StocksSymbols where count > $mindays";
  if ($from) {
    $sql .= " and first <= " . parsedate($from);
  }
  if ($to) {
    $sql .= " and last >= " . parsedate($to);
  }
  $sql .= " order by rand() limit $count";
} elsif ($ENV{PORTF_DBMS} eq "oracle") {
  $sql="select * from (select symbol from ".GetStockPrefix()."StocksSymbols where count > $mindays";
  if ($from) {
    $sql .= " and first <= " . parsedate($from);
  }
  if ($to) {
    $sql .= " and last >= " . parsedate($to);
  }
  $sql .= " order by dbms_random.value) where rownum <= $count";
  
} else {
  print "get_random_symbol.pl not supported on \"".$ENV{PORTF_DBMS}."\"\n";
  exit -1;
}

print ExecStockSQL("TEXT",$sql);
