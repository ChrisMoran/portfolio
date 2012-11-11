#!/usr/bin/perl -w
#
# Debugging
#
# database input and output is paired into the two arrays noted
#
my $debug=0; # default - will be overriden by a form parameter or cookie
my @sqlinput=();
my @sqloutput=();

use strict;
use CGI qw(:standard);
use HTML::Template;
use DBI;
use Time::ParseDate;
my $dbuser="lsk250";
my $dbpasswd="z50uWdjGo";
print "Content-type: text/html\n\n";
# open the html template
  my $template = HTML::Template->new(filename => 'test.tmpl');

  # fill in some parameters
  $template->param(HOME => $ENV{HOME});
  $template->param(PATH => $ENV{PATH});
# send the obligatory Content-Type and print the template output
  print $template->output;