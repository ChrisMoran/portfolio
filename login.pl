#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use portfolio_util;

my ($user, $password) = (param('username'),param('password'));
if(ValidUser($user, $password)) {
    my $cookieValue = join('/', $user, $password);
    my $cookie = cookie(-name=>'portSession',
			-value=>$cookieValue,
			-expires=>'+1h');
    # change location to user home page once that works
    print header(-expires=>'now', -location=>'userHome.pl', -cookie=>$cookie);
} else {
    #have some error message about login failing, no big deal now
    print header(-expires=>'now', -location=>'login.html');
}


