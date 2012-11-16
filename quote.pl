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
	print header(-expires=>"now");
	print "<html><head>";
	print "<script type=\"text/javascript\" src=\"//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js\"></script>";
	print "<link href=\"bootstrap/css/bootstrap.min.css\" rel=\"stylesheet\" media=\"screen\"/>";
	print "<script type=\"text/javascript\" src=\"bootstrap/js/bootstrap.min.js\"></script>";
	print "<link href=\"common.css\" rel=\"stylesheet\" media=\"screen\"/>";
	print "</head>";
	print "<body>";
	print "<div class=\"container\"><div class=\"pageRoot\">";
	print "<h2>Current Holdings</h2>";
	print "<table class=\"table table-bordered\">";
	print "<tr><th>Symbol</th><th>Date</th><th>Time</th><th>High</th><th>Low</th><th>Close</th><th>Open</th><th>Volume</th><th>Shares</th><th>Action</th><th>Store</th></tr>";
	foreach $symbol (@symbols) {
	    $symbol = trim($symbol);
	    print "<tr>";
	    print "<td><div class=\"btn-group\"><a class=\"btn dropdown-toggle\" data-toggle=\"dropdown\" href=\"#\">$symbol<span class=\"caret\"></span></a><ul class=\"dropdown-menu\"><li><a href=\"historical.pl?symbol=$symbol\">Historical</a></li><li><a href=\"prediction.pl?symbol=$symbol\">Prediction</a></li><li><a href=\"autotrading.pl?stock=$symbol\">Auto Trading</a></li></ul></div></td>";
		
	    if (!defined($quotes{$symbol,"success"})) { 
		print "<td colspan=\"7\">No Data</td>";
	    } else {
		
		
		($symbol, my $date, my $open, my $high, my $low, my $close, my $volume) = @info;
		foreach $key (@info) {
		    if (defined($quotes{$symbol,$key})) {
			print "<td>",$quotes{$symbol,$key},"</td>";
		    }
		}
		
		print"<td>$symbol</td><td>$date</td><td>$open</td><td>$high</td><td>$low</td><td>$close</td><td>$volume</td>";
		@shares = ExecStockSQL('COL',"SELECT shares FROM Holdings WHERE portfolio = ? AND symbol = rpad(?, 16)", $portfolio, $symbol);
		print "<td>",$shares[0],"</td>";
		print "<td><a href=\"newtrade.pl?act=newtrade&id=$portfolio&stock=$symbol\">New Trade</a></td>";
		print "<td><button class=\"btn\">Add Price</button></td>";
	    }
		
	    print "</tr>";
	}

	print "</table><br/><a href=\"newtrade.pl?act=newtrade&id=$portfolio\" class=\"btn btn-primary\">Buy a New Stock</a><br/><br/>";
	print "<a href=\"userHome.pl\"><strong>Return to home</strong></a>";
	print "</div></div></body></html>";
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
