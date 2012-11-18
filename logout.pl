#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);


my $cookie = cookie(-name=>'portSession',
		    -value=>'',
		    -expires=>'-1h');
print header(-expires=>'now', -location=>'login.html', -cookie=>$cookie);

