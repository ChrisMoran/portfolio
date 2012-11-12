#!/usr/bin/perl -w

use lib "/home/lsk250/myperllib";
use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use JSON


print "Content-type: text/html\n\n";
print header('application/json');
@entries=(1,2,3)
my $json->{"entries"} = \@entries;
my $json_text = to_json($json);
print $json_text;