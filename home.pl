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
use DBI;
use Time::ParseDate;
my $dbuser="lsk250";
my $dbpasswd="z50uWdjGo";
print "Content-type: text/html\n\n";
print "hello";
