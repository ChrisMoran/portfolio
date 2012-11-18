#!/usr/bin/perl -w
use CGI qw(:standard);
use Finance::Quote;
use Time::ParseDate;
use portfolio_util;
use stock_data_access;
my $symbol = param('symbol');
my $con=Finance::Quote->new();
$con->timeout(60);
my %quotes = $con->fetch("usa",$symbol);

my $timestamp = parsedate($quotes{$symbol,"date"});
my $open = $quotes{$symbol,"open"};
my $high = $quotes{$symbol,"high"};
my $low = $quotes{$symbol,"low"};
my $close = $quotes{$symbol,"close"};
my $volume = $quotes{$symbol,"volume"};
if(defined($timestamp)&&defined($open)&&defined($high)&&defined($low)&&defined($close)&&defined($volume)&&defined($symbol)){

eval{
ExecStockSQL("NOTHING","INSERT INTO newstocksdaily(symbol,timestamp,open,high,low,close,volume) VALUES (?,?,?,?,?,?,?)", $symbol,$timestamp,$open,$high,$low,$close,$volume);
};
print header(-expires=>'now');
if ($@) { 
			    print "Failed to store price.";
			} else {
			    print "Succesfully stored price.";
			}
			}