#!/usr/bin/perl -w


use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;

BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="cs339";
  $ENV{PORTF_DBUSER}="pdinda";
  $ENV{PORTF_DBPASS}="pdinda";

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

my $type = param('type');
my $symbol = param('symbol');

if (!defined($type) || $type eq "text" || !($type eq "plot") ) { 
  print header(-type => 'text/html', -expires => '-1h' );
  
  print "<html>";
  print "<head>";
  print "<title>Stock Data</title>";
  print "</head>";

  print "<body>";

  if (!defined($type) || !($type eq "text") ) { 
    $type = "text";
    print "<p>You should give type=text or type=plot - I'm assuming you mean text</p>";
  }
  if (!defined($symbol)) { 
    $symbol = "AAPL";
    print "<p>You should give symbol=symbolname - I'm just giving you AAPL now </p>";
  }
} elsif ($type eq "plot") { 
  print header(-type => 'image/png', -expires => '-1h' );
  if (!defined($symbol)) { 
    $symbol = 'AAPL'; # default
  }
}


my @rows = ExecStockSQL("2D","select timestamp, close from ".GetStockPrefix()."StocksDaily where symbol=rpad(?,16)",$symbol);

if ($type eq "text") { 
  print "<pre>";
  foreach my $r (@rows) {
    print $r->[0], "\t", $r->[1], "\n";
  }
  print "</pre>";
  

  print "</body>";
  print "</html>";

} elsif ($type eq "plot") {
#
# This is how to drive gnuplot to produce a plot
# The basic idea is that we are going to send it commands and data
# at stdin, and it will print the graph for us to stdout
#
#
  open(GNUPLOT,"| gnuplot") or die "Cannot run gnuplot";
  
  print GNUPLOT "set term png\n";           # we want it to produce a PNG
  print GNUPLOT "set output\n";             # output the PNG to stdout
  print GNUPLOT "plot '-' using 1:2 with linespoints\n"; # feed it data to plot
  foreach my $r (@rows) {
    print GNUPLOT $r->[0], "\t", $r->[1], "\n";
  }
  print GNUPLOT "e\n"; # end of data

  #
  # Here gnuplot will print the image content
  #

  close(GNUPLOT);
}



