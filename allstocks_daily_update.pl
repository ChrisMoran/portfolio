#!/usr/bin/perl -w

use Data::Dumper;
use Finance::Quote;

use Time::ParseDate;
use lib "/home/lsk250/www/portfolio/";
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
my @symbols=ExecStockSQL('COL',"SELECT DISTINCT symbol FROM holdings");

#my @symbols=("AAPL","AMZN");
foreach my $symbol (@symbols){
$symbol=rtrim($symbol);
$con=Finance::Quote->new();
$con->timeout(180);
%quotes = $con->fetch("usa",$symbol);
my $timestamp = parsedate($quotes{$symbol,"date"});
my $open = $quotes{$symbol,"open"};
my $high = $quotes{$symbol,"high"};
my $low = $quotes{$symbol,"low"};
my $close = $quotes{$symbol,"close"};
my $volume = $quotes{$symbol,"volume"};
eval{
ExecStockSQL("NOTHING","INSERT INTO newstocksdaily(symbol,timestamp,open,high,low,close,volume) VALUES (?,?,?,?,?,?,?)", $symbol,$timestamp,$open,$high,$low,$close,$volume);
};
};



#helper to remove trailing whitespaces
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}
