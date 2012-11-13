#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);
use portfolio_util;

my $cookieVal = cookie("portSession");
if(defined($cookieVal)) {
    my ($user, $password) = split(/\//, $cookieVal);
    if(ValidUser($user, $password)) {
	my ($fromId, $toId, $amount) = (param("from"), param("to"), param("amount"));
	if(defined($fromId) && defined($toId) && defined($amount) && $amount =~ /^\d+\.?\d*$/) {
	    my $balance = PortfolioCashBalance($user, $fromId);
	    if(($balance - $amount) >= 0) {
		TransferPortfolios($user, $fromId, $toId, $amount);
		print header(-expires=>'now', -location=>'userHome.pl');
	    } else {
		print header(-expires=>'now', -location=>'userHome.pl?error=transfer'); 
	    }
	} else {
	    print header(-expires=>'now', -location=>'userHome.pl?error=transfer'); 
	}
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}
