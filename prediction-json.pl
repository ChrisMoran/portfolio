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
	#$ENV{'PATH'} = "/pdinda/339/HANDOUT/portfolio";
	$ENV{PATH} = "$ENV{PATH}:/home/lsk250/www/portfolio/portfolio-handout";
    exec 'env',cwd().'/'.$0,@ARGV;
  }
};
my $symbol = param('symbol');
print header('application/json');

#use stock_data_access;
my $symbol = param('symbol');
my $length = param('length');
my $cmd = "./portfolio-handout/time_series_symbol_project.pl $symbol $length AWAIT 300 ARIMA 2 1 2 | tail -$length";

system $cmd;

