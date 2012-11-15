#!/usr/bin/perl -w
use strict;

use CGI qw(:standard);
use HTML::Template;
use portfolio_util;

my $userCookie = cookie("portSession");
if(defined($userCookie)) {
    my ($user,$password) = split(/\//, $userCookie);
    if(ValidUser($user, $password)) {
	
	my @portfolios = PortfolioInfo($user);
	my @templPorts;
	for(my $i = 0; $i <= $#portfolios; $i++) {
	    my $estimatedValue = HoldingsValue($portfolios[$i][0]);
	    my $total = $estimatedValue + $portfolios[$i][2];
	    push(@templPorts, {ID=>$portfolios[$i][0],
			       NAME=>$portfolios[$i][1],
			       CASH=>$portfolios[$i][2],
			       VALUE=>$estimatedValue,
		               TOTAL=>$total});
	}
	
	my $template = HTML::Template->new(filename => 'userHome.tmpl');
	$template->param(PORTFOLIOS => \@templPorts);
	print header(-expires=>'now');
	
	print $template->output;
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}
