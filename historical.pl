#!/usr/bin/perl -w


use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;

use stock_data_access;

my $symbol = param('symbol');
if (!defined($symbol)) { 
	print "<p>You should input a symbol to get historical data</p>";
}
