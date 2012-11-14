#!/usr/bin/perl -w
use CGI qw(:standard);
use Finance::Quote;

use portfolio_util;
use stock_data_access;

my $portfolio = param('id');
my $userCookie = cookie('portSession');
if(defined($userCookie) && defined($portfolio)) {
    my ($userLogin,$password) = split(/\//, $userCookie);
    if(ValidUser($userLogin, $password)) {

	print "Content-type: text/html\n\n";

	my $stock = undef;
	my $action = undef;
	my $run = 0;

	if (defined(param("act"))) { 
	    $action=param("act");
	} else {
	    $action="newtrade";
	}

	if (defined(param("stock"))) { 
	    $stock=param("stock");
	}

	if (defined(param("run"))) { 
	    $run=1;
	} 

	my @trade = ('Buy', 'Sell');

	if (($action eq "newtrade") && (defined($portfolio)) && ($run==0)) {
	    print start_form(-name=>'newtrade'), h2('New Trade');
	    if (defined($stock)) {
		print "SYMBOL",textfield(-name=>'stock',default=>[$stock]),p;
	    } else {
		print "SYMBOL",textfield(-name=>'stock'),p;
	    }
	    print "AMNT",textfield(-name=>'amount'),p,
	    "TRADE",popup_menu(
		-name    => 'trade',
		-values  => \@trade,
		-default => 'Buy'
		),p,
		hidden(-name=>'id',default=>[$portfolio]),
		hidden(-name=>'run',-default=>['1']),
		submit,
		end_form;
		print "<a href=\"quote.pl?id=$portfolio\">Return to your portfolio</a>";
	}

	if (($action eq "newtrade") && (defined($portfolio)) && $run) {	
	
	    $con=Finance::Quote->new();	
	    $con->timeout(60);
	    %quotes = $con->fetch("usa",$stock);
	    my $closePrice = $quotes{$stock,"close"};
	    
	    my $shares  = param("amount");
	    my $direction = param("trade");
	    
	    my $transact_amt= $closePrice*$shares;
	
	# print "transaction",$transact_amt,p;
	# print "closePrice",$closePrice,p;
	# print "Shares",$shares,p;
	# print "Action",$direction,p;
	
	    @exist= ExecStockSQL('COL',"SELECT count(*) FROM Holdings WHERE portfolio = ? AND symbol = rpad(?, 16)", $portfolio, $stock);
	    if ($exist[0]) {
		if ($direction eq "Sell") {
			@curr_shares = ExecStockSQL('COL',"SELECT shares FROM Holdings WHERE portfolio=? AND symbol=rpad(?, 16)", $portfolio, $stock);
			if ($shares>$curr_shares[0]) {
					print h2("Transaction failure: not enough shares.");
			} else {
			    my $shares_left = $curr_shares[0]-$shares;
			    eval {
				ExecStockSQL(undef,"UPDATE Portfolios SET assets=assets+? WHERE id=?", $transact_amt, $portfolio);
				ExecStockSQL(undef,"COMMIT");
				ExecStockSQL(undef,"UPDATE Holdings SET shares=? WHERE portfolio=? AND symbol=rpad(?, 16)", $shares_left, $portfolio, $stock);
				if ($shares_left==0) {
				    ExecStockSQL(undef,"DELETE FROM Holdings WHERE portfolio=? AND symbol=rpad(?, 16)", $portfolio, $stock);
				}
			    };
			    if ($@) { 
				print h2("Transaction failure");
			    } else {
				print h2("Transaction successful");
			    }
			}
			
		} elsif ($direction eq "Buy") {
		    @asset = ExecStockSQL('COL',"SELECT assets FROM Portfolios WHERE id=?", $portfolio);
		    if ($transact_amt>$asset[0]) {
			print h2("Transaction failure: not enough cash.");
		    } else {
			my $asset_left = $asset[0]-$transact_amt;
			eval {
			    ExecStockSQL(undef,"UPDATE Portfolios SET assets=? WHERE id=?", $asset_left, $portfolio);
			    ExecStockSQL(undef,"UPDATE Holdings SET shares=shares+? WHERE portfolio=? AND symbol=rpad(?, 16)", $shares, $portfolio, $stock);
			    ExecStockSQL(undef,"COMMIT");};
			if ($@) { 
			    print $@,p;
			    print h2("Transaction failure");
			} else {
			    print h2("Transaction successful");
			}
		    }
		    
		} else {
		    print h2("Transaction failure: unknown trade action.");
		}
		
	    } else {
		if ($direction eq "Sell") {
		    print h2("You do not own stock $stock");
		} elsif ($direction eq "Buy") {

		    @asset = ExecStockSQL('COL',"SELECT assets FROM Portfolios WHERE id=?", $portfolio);
		    if ($transact_amt>$asset[0]) {
			print h2("Transaction failure: not enough cash.");
		    } else {
			my $asset_left = $asset[0]-$transact_amt;
			eval{
			    ExecStockSQL(undef,"UPDATE Portfolios SET assets=? WHERE id=?", $asset_left, $portfolio);
			    ExecStockSQL(undef,"INSERT INTO Holdings(portfolio,symbol,shares) VALUES (?,?,?)", $portfolio, $stock, $shares);};
			if ($@) { 
			    print h2("Transaction failure");
			} else {
			    print h2("Transaction successful");
			}
		    }
		    
		} else {
		    print h2("Transaction failure: unknown trade action.");
		}
	    }
	    print "<a href=\"quote.pl?id=$portfolio\">Return to your portfolio</a>";
	}
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}
