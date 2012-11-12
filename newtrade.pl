#!/usr/bin/perl -w
use CGI qw(:standard);
use Finance::Quote;
BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="pzu918";
  $ENV{PORTF_DBUSER}="pzu918";
  $ENV{PORTF_DBPASS}="z00wgeGKy";

  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
};

use stock_data_access;
print "Content-type: text/html\n\n";

my $stock = undef;
my $action = undef;
my $portfolio = undef;
my $run = 0;

if (defined(param("act"))) { 
  $action=param("act");
} else {
  $action="newtrade";
}

if (defined(param("stock"))) { 
	$stock=param("stock");
}

if (defined(param("run"))) { 
	$run=1;
} 

if (defined(param("portfolio"))) { 
	$portfolio=param("portfolio");
} else {
	print h2('Cannot identify portfolio');
}

my @trade = ('Buy', 'Sell');

if (($action eq "newtrade") && (defined($portfolio)) && ($run==0)) {
	print start_form(-name=>'newtrade'), h2('New Trade');
		if (defined($stock)) {
			print "SYMBOL",textfield(-name=>'stock',default=>[$stock]),p;
			} else {
			print "SYMBOL",textfield(-name=>'stock'),p;
			}
		print "AMNT",textfield(-name=>'amount'),p,
		"TRADE",popup_menu(
			-name    => 'trade',
			-values  => \@trade,
			-default => 'Buy'
			),p,
		hidden(-name=>'portfolio',default=>[$portfolio]),
		hidden(-name=>'run',-default=>['1']),
		submit,
		end_form;
}

if (($action eq "newtrade") && (defined($portfolio)) && $run) {	
	
	$con=Finance::Quote->new();	
	$con->timeout(60);
	%quotes = $con->fetch("usa",$stock);
	my $closePrice = $quotes{$stock,"close"};
	
	my $shares  = param("amount");
	my $direction = param("trade");
	
	my $transact_amt= $closePrice*$shares;
	
	# print "transaction",$transact_amt,p;
	# print "closePrice",$closePrice,p;
	# print "Shares",$shares,p;
	# print "Action",$direction,p;
	
	@exist= ExecStockSQL('COL',"SELECT count(*) FROM PZU918.Holdings WHERE portfolio = $portfolio AND symbol = \'$stock\'");
	if ($exist[0]) {
		if ($direction eq "Sell") {
			@curr_shares = ExecStockSQL('COL',"SELECT shares FROM PZU918.Holdings WHERE portfolio=$portfolio AND symbol=\'$stock\'");
			if ($shares>$curr_shares[0]) {
					print h2("Trasaction failure: not enough shares.");
				} else {
					my $shares_left = $curr_shares[0]-$shares;
					eval {
						ExecStockSQL(undef,"UPDATE pzu918.Portfolios SET assets=assets+$transact_amt WHERE id=$portfolio");
						ExecStockSQL(undef,"COMMIT");
						ExecStockSQL(undef,"UPDATE pzu918.Holdings SET shares=$shares_left WHERE portfolio=$portfolio AND symbol=\'$stock\'");
						if ($shares_left==0) {
							ExecStockSQL(undef,"DELETE FROM pzu918.Holdings WHERE portfolio=$portfolio AND symbol=\'$stock\'");
						}
					};
					if ($@) { 
						print h2("Trasaction failure");
					} else {
						print h2("Trasaction successfully");
					}
			}
			
		} elsif ($direction eq "Buy") {
			@asset = ExecStockSQL('COL',"SELECT assets FROM PZU918.Portfolios WHERE id=$portfolio");
			if ($transact_amt>$asset[0]) {
					print h2("Trasaction failure: not enough cash.");
				} else {
					my $asset_left = $asset[0]-$transact_amt;
					eval {
						ExecStockSQL(undef,"UPDATE pzu918.Portfolios SET assets=$asset_left WHERE id=$portfolio");
						ExecStockSQL(undef,"UPDATE pzu918.Holdings SET shares=shares+$shares WHERE portfolio=$portfolio AND symbol=\'$stock\'");
						ExecStockSQL(undef,"COMMIT");};
					if ($@) { 
						print $@,p;
						print h2("Trasaction failure");
					} else {
						 print h2("Trasaction successfully");
					}
				}
			
		} else {
			print h2("Trasaction failure: unknown trade action.");
		}
		
	} else {
		if ($direction eq "Sell") {
			print h2("You do not own stock $stock");
		} elsif ($direction eq "Buy") {
			@asset = ExecStockSQL('COL',"SELECT assets FROM PZU918.Portfolios WHERE id=$portfolio");
			if ($transact_amt>$asset[0]) {
					print h2("Trade failure: not enough cash.");
				} else {
					my $asset_left = $asset[0]-$transact_amt;
					eval{
					ExecStockSQL(undef,"UPDATE pzu918.Portfolios SET assets=$asset_left WHERE id=$portfolio");
					ExecStockSQL(undef,"INSERT INTO pzu918.Holdings(portfolio,symbol,shares) VALUES ($portfolio,\'$stock\',$shares)");};
					if ($@) { 
						print h2("Transaction failure");
					} else {
						print h2("Transaction successfully");
					}
				}
			
		} else {
			print h2("Transaction failure: unknown trade action.");
		}
	}
}