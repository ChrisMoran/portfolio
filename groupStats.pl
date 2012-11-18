#!/usr/bin/perl -w
use strict;

use CGI qw(:standard);

use portfolio_util;

my $userCookie = cookie("portSession");
my $portfolio = param('id');

my ($from, $to, $field1, $field2) = (param('from'), param('to'), param('field1'), param('field2'));

if(defined($userCookie) && defined($portfolio)) {
    my ($user,$password) = split(/\//, $userCookie);
    if(ValidUser($user, $password)) {
	print header(-expires=>'now');
	print "<html><head>";
	print "<script type=\"text/javascript\" src=\"//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js\"></script>";
	print "<link href=\"bootstrap/css/bootstrap.min.css\" rel=\"stylesheet\" media=\"screen\"/>";
	print "<script type=\"text/javascript\" src=\"bootstrap/js/bootstrap.min.js\"></script>";
	print "<link href=\"common.css\" rel=\"stylesheet\" media=\"screen\"/>";
	print "</head>";
	print "<body>";
	print "<div class=\"navbar navbar-inverse navbar-fixed-top\" style=\"margin-bottom: 20px;\"><div class=\"navbar-inner\">";
	print "<div class=\"container\"><a class=\"brand\" href=\"#\">Portfolio Manager</a><ul class=\"nav\">";
	print "<li><a href=\"userHome.pl\">Home</a></li><li><a href=\"logout.pl\">Logout</a></li></ul></div></div></div>";
	print "<div class=\"container\"><div class=\"pageRoot\">";
	$from = undef if $from eq '';
	$to = undef if $to eq '';
	my ($covTable, $corrTable) = CovAndCorrTables($portfolio, $field1, $field2, $from, $to);

	print $covTable, $corrTable;

	print "<a href=\"quote.pl?id=$portfolio\">Return to portfolio</a>";
	print "</div></div></body></html>";
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}
