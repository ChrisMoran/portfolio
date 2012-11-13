#!/usr/bin/perl -w

use Data::Dumper;
use lib "/home/lsk250/myperllib";
use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use JSON;
use Finance::QuoteHist;
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
$#ARGV>=0 or die "usage: quote.pl  SYMBOL+\n";
use stock_data_access;

my @symbols=@ARGV;

my $q = Finance::QuoteHist->new
     (
      symbols    => [qw(MSFT)],
      start_date => '07/03/2006', # or '1 year ago', see Date::Manip
      end_date   => 'today',
     );
	 
foreach my $row ($q->quotes()) {
    print @$row,"\n";
	(my $symbol, my $date, my $open, my $high, my $low, my $close, my $volume) = @$row;
	#print $symbol, $date,$open,$high;
	my $timestamp = parsedate($date);
	ExecStockSQL("2D","insert into NEWSTOCKSDAILY (symbol,timestamp,open,high,low,close,volume) values (?,?,?,?,?,?,?)",$symbol,$timestamp,$open,$high,$low,$close,$volume);
  }


