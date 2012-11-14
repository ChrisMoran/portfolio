#!/usr/bin/perl -w

use lib "/home/lsk250/myperllib";
use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use HTML::Template;
#use stock_data_access;

my $symbol = param('symbol');
if (!defined($symbol)) { 
	
}
print "Content-type: text/html\n\n";
# open the html template(with javascript,etc)
  my $template = HTML::Template->new(filename => 'prediction.tmpl');

  # fill in some parameters
$template->param(SYMBOL=> $symbol);
#$template->param(PATH => $ENV{PATH});
# send the obligatory Content-Type and print the template output
  print $template->output;