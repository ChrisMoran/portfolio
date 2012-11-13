#!/usr/bin/perl -w

use lib "/home/lsk250/myperllib";
use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use JSON;

BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="cs339";
  $ENV{PORTF_DBUSER}="lsk250";
  $ENV{PORTF_DBPASS}="z50uWdjGo";

  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
};

use stock_data_access;
my $symbol = param('symbol');
my $interval = param('interval');
 if (!defined($interval)) { 
    $interval="week";
  }
my $num_rows=5;
if ($interval eq "week") {$num_rows=5;}
elsif ($interval eq "month") {$num_rows=20;}
elsif ($interval eq "quarter") {$num_rows=62;}
elsif ($interval eq "year") {$num_rows=250;}
elsif ($interval eq "5year") {$num_rows=1250;}

#select * from (select * from cs339.stocksdaily where SYMBOL='AAPL' and TIMESTAMP<1113800400 ORDER BY TIMESTAMP ASC) where ROWNUM <=5;
#my @rows = ExecStockSQL("2D","SELECT * FROM ((SELECT timestamp, close FROM ".GetStockPrefix()."StocksDaily WHERE symbol=rpad(?,16) ) UNION (SELECT timestamp, close FROM NEWSTOCKSDAILY WHERE symbol=rpad(?,16) )) WHERE ROWNUM <= ?",$symbol,$symbol,$num_rows);
#print "Content-type: text/html\n\n";
print header('application/json');
my @rows = ExecStockSQL("2D","SELECT * FROM (SELECT timestamp, close FROM all_stockdailys WHERE symbol=rpad(?,16) ORDER BY TIMESTAMP DESC )  WHERE ROWNUM <= ?",$symbol,$num_rows);
my @entries=([1,1],[2,4],[3,2]);
my $json->{"plot_data"} = \@rows;
$json->{"symbol"} = $symbol;
$json->{"interval"} = $interval;
my $json_text = to_json($json);

print $json_text;
