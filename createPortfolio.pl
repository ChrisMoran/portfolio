#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);

use portfolio_util;

my $cookieVal = cookie('portSession');
if(defined($cookieVal)) {
    my ($user, $pass) = split(/\//, $cookieVal);
    if(ValidUser($user, $pass)) {
	my $portfolio_name = param("portfolio_name");
	my $cash_amount = int(param("cash_amount"));
	if(defined($cash_amount) && $cash_amount =~ /^-?\d+\.?\d*$/ && defined($portfolio_name)) {
	    CreatePortfolio($user, $portfolio_name, $cash_amount);
	    print header(-expires=>'now', -location=>'userHome.pl');
	} else {
	    print header(-expires=>'now', -location=>'userHome.pl');
	}
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}



