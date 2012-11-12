#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use portfolio_util;

my ($user, $password) = (param('username'),param('password'));
if(defined($user) && defined($password)) {
    if(!UserExists($user)) { # don't already have user taken
	AddUser($user, $password);
	my $cookieValue = join('/', $user, $password);
	my $cookie = cookie(-name=>'portSession',
			    -value=>$cookieValue,
			    -expires=>'+1h');
	print header(-expires=>'now', -location=>'success.html', -cookie=>$cookie);
    } else {
	print header(-expires=>'now', -location=>'login.html');
    }
} else {
    print header(-expires=>'now', -location=>'login.html');
}
