#!/usr/bin/perl -w
use strict;

use CGI qw(:standard);
use HTML::Template;
use portfolio_util;

my $userCookie = cookie("portSession");
my $portfolio = param('id');
if(defined($userCookie) && defined($portfolio)) {
    my ($user,$password) = split(/\//, $userCookie);
    if(ValidUser($user, $password)) {
	my $template = HTML::Template->new(filename => 'stats.tmpl');
	$template->param(PORTFOLIO=>$portfolio);
	print header(-expires=>'now');
	
	print $template->output;
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}
