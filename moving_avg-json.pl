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
my $n = 50; #default
$n = param('n');
my $num_rows = 62;
if ($interval eq "week") {$num_rows=5;}
elsif ($interval eq "month") {$num_rows=20;}
elsif ($interval eq "quarter") {$num_rows=62;}
elsif ($interval eq "year") {$num_rows=250;}
elsif ($interval eq "5year") {$num_rows=1250;}


print header('application/json');
my @rows = ExecStockSQL("2D","SELECT * FROM (SELECT symbol, timestamp, avg(close) OVER (partition by symbol ORDER BY timestamp ASC ROWS BETWEEN ? PRECEDING AND CURRENT ROW) movingavg FROM all_stockdailys WHERE symbol=rpad(?,16) ORDER BY TIMESTAMP DESC) WHERE ROWNUM < ?
",$n,$symbol,$num_rows);
my $json->{"plot_data"} = \@rows;
$json->{"symbol"} = $symbol;
#$json->{"interval"} = $interval;
my $json_text = to_json($json);

print $json_text;
