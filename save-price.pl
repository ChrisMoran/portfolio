#!/usr/bin/perl -w
use CGI qw(:standard);
use Finance::Quote;

use portfolio_util;
use stock_data_access;

my $symbol = param('symbol');
my $timestamp = param('timestamp');
my $open = param('open');
my $high = param('high');
my $low = param('low');
my $close = param('close');
my $volume = param('volume');


ExecStockSQL(undef,"INSERT INTO newstocksdaily(symbol,timestamp,open,high,low,close,volume) VALUES (?,?,?)", $symbol,$timestamp,$open,$high,$low,$close,$volume);
