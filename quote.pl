#!/usr/bin/perl -w

use Data::Dumper;
use CGI qw(:standard);
use Finance::Quote;

BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="lsk250";
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
#declare subroutine trim
sub trim($);

#need to change later
$portfolio = 1;

@info=("date","time","high","low","close","open","volume");

@symbols = ExecStockSQL('COL',"SELECT symbol FROM lsk250.Holdings WHERE portfolio=$portfolio");
$con=Finance::Quote->new();

$con->timeout(60);

%quotes = $con->fetch("usa",@symbols);
print "Content-type: text/html\n\n";
print "<td><a href=\"newtrade.pl?act=newtrade&portfolio=$portfolio\">BUY A NEW STOCK</a></td><br>";
print "<table>";
print "<tr><th>Symbol</th><th>Date</th><th>Time</th><th>High</th><th>Low</th><th>Close</th><th>Open</th><th>Volume</th><th>Shares</th><th>Action</th></tr>";
foreach $symbol (@symbols) {
    $symbol = trim($symbol);
    print "<tr>";
    print "<td>",$symbol,"</td>";
    if (!defined($quotes{$symbol,"success"})) { 
	print "<td colspan=\"7\">No Data</td>";
    } else {

	foreach $key (@info) {
	    if (defined($quotes{$symbol,$key})) {
		print "<td>",$quotes{$symbol,$key},"</td>";
	    }
	}
	@shares = ExecStockSQL('COL',"SELECT shares FROM lsk250.Holdings WHERE portfolio = $portfolio AND symbol = \'$symbol\'");
	print "<td>",$shares[0],"</td>";
	print "<td><a href=\"newtrade.pl?act=newtrade&portfolio=$portfolio&stock=$symbol\">New Trade</a></td>";
    }
    print "</tr>";
}
print "</table>";


#trim($)
#to remove space at the beginning and the end;
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}