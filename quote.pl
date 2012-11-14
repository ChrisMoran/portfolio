#!/usr/bin/perl -w

use Data::Dumper;
use CGI qw(:standard);
use Finance::Quote;


use portfolio_util;

use stock_data_access;

#declare subroutine trim
sub trim($);

my $portfolio = param('id');
my $userCookie = cookie('portSession');
if(defined($userCookie) && defined($portfolio)) {
    my ($userLogin,$password) = split(/\//, $userCookie);
    if(ValidUser($userLogin, $password)) {
	my @info=("date","time","high","low","close","open","volume");
	my @symbols = ExecStockSQL('COL',"SELECT symbol FROM Holdings WHERE portfolio=?", $portfolio);
	my $con=Finance::Quote->new();

	$con->timeout(60);

	my %quotes = $con->fetch("usa",@symbols);
	print "Content-type: text/html\n\n";
	print "<td><a href=\"newtrade.pl?act=newtrade&id=$portfolio\">BUY A NEW STOCK</a></td><br>";
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
		@shares = ExecStockSQL('COL',"SELECT shares FROM Holdings WHERE portfolio = ? AND symbol = rpad(?, 16)", $portfolio, $symbol);
		print "<td>",$shares[0],"</td>";
		print "<td><a href=\"newtrade.pl?act=newtrade&id=$portfolio&stock=$symbol\">New Trade</a></td>";
		print "<td><button>Add Price</button></td>;
	    }
		
	    print "</tr>";
	}

	print "</table><br/>";
	print "<a href=\"userHome.pl\">Return to home</a>";
    }
}

#trim($)
#to remove space at the beginning and the end;
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
