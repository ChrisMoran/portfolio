#!/usr/bin/perl -w 
use CGI qw(:standard);
use Switch;
use FileHandle;
BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="lsk250";
  $ENV{PORTF_DBUSER}="lsk250";
  $ENV{PORTF_DBPASS}="z50uWdjGo";
  #$ENV{PATH} = '$ENV{PATH}:/home/lsk250/www/portfolio';

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

my $strat;
my $stock;
my $run = 0;
if (defined(param('strategy'))) {
    $strat=param('strategy');
} else {
     $strat='sr';
}

if (defined(param("run"))) { 
	$run=param('run');
} 

if (defined(param("stock"))) { 
	$stock=param("stock");
} else {
  print h2("Error: undefined stock.");
}
 
if (defined($stock)) {
        my %trading_strat_label = ('sr'=>'Shannon-ratchet');
        my @trading_strat=('sr'); 
        print start_form(-name=>'autotrading'), h2('Automated Trading Strategy');
		print "INIT CASH",textfield(-name=>'initial_cash'),p,
		"TRADE COST",textfield(-name=>'tradecost'),p,
		"TRADING STRAT",popup_menu(
			-name    => 'strategy',
			-values  => \@trading_strat,
			-labels  => \%trading_strat_label,
			-default => 'sr'
			),p,
                  radio_group( -name=>'timeframe', 
                               -values=>['Past week', 'Past month','Past quarter','Past year','Past 5 years','Past 10 years'], 
                               -default=>'Past week'),p,
		hidden(-name=>'run',-default=>['1']),
		hidden(-name=>'stock',-default=>[$stock]),
		submit,
		end_form;
}

if (($run==1) && (defined($stock))) {

if ($strat eq 'sr') {
my $initialcash;
my $tradecost;
my $timeframe;

$initialcash = param('initial_cash');
$tradecost=param('tradecost');
$timeframe=param('timeframe');

if (defined($initialcash) && defined($tradecost) && defined($timeframe)) {
  
my $numrows;
switch ($timeframe) {
  case "Past week" {$numrows=5;}
  case "Past month" {$numrows=21;}
  case "Past quarter" {$numrows=63;}
  case "Past year" {$numrows=252;}
  case "Past 5 years" {$numrows=1260;}
  case "Past 10 years" {$numrows=2520;}
}

eval {
  $rows = ExecStockSQL("TEXT","SELECT * FROM (SELECT timestamp, close FROM all_stockdailys WHERE symbol=rpad(?,16) ORDER BY TIMESTAMP DESC)  WHERE ROWNUM <= ?",$stock,$numrows);
};

$lastcash=$initialcash;
$laststock=0;
$lasttotal=$lastcash;
$lasttotalaftertradecost=$lasttotal;

open(STOCK, "<",\$rows) or die "Could not open STOCK";

$cash=0;
$stock=0;
$total=0;
$totalaftertradecost=0;

$day=0;



while (<STOCK>) { 
  chomp;
  @data=split;
  $stockprice=$data[1];

  $currenttotal=$lastcash+$laststock*$stockprice;
  if ($currenttotal<=0) {
    exit;
  }
  
  $fractioncash=$lastcash/$currenttotal;
  $fractionstock=($laststock*$stockprice)/$currenttotal;
  $thistradecost=0;
  if ($fractioncash >= 0.5 ) {
    $redistcash=($fractioncash-0.5)*$currenttotal;
    if ($redistcash>0) {
      $cash=$lastcash-$redistcash;
      $stock=$laststock+$redistcash/$stockprice;
      $thistradecost=$tradecost;
    } else {
      $cash=$lastcash;
      $stock=$laststock;
    } 
  }  else {
    $redistcash=($fractionstock-0.5)*$currenttotal;
    if ($redistcash>0) {
      $cash=$lastcash+$redistcash;
      $stock=$laststock-$redistcash/$stockprice;
      $thistradecost=$tradecost;
    }
  }
  
  $total=$cash+$stock*$stockprice;
  $totalaftertradecost=($lasttotalaftertradecost-$lasttotal) - $thistradecost + $total; 
  $lastcash=$cash;
  $laststock=$stock;
  $lasttotal=$total;
  $lasttotalaftertradecost=$totalaftertradecost;

  $day++;
  

#  print STDERR "$day\t$stockprice\t$cash\t".($stock*$stockprice)."\t$stock\t$total\t$totalaftertradecost\n";
}

close(STOCK);

$roi = 100.0*($lasttotal-$initialcash)/$initialcash;
$roi_annual = $roi/($day/365.0);

$roi_at = 100.0*($lasttotalaftertradecost-$initialcash)/$initialcash;
$roi_at_annual = $roi_at/($day/365.0);


#print "$symbol\t$day\t$roi\t$roi_annual\n";

		
print "Invested:                        \t$initialcash\n",p,
"Days:                            \t$day\n",p,
"Total:                           \t$lasttotal (ROI=$roi % ROI-annual = $roi_annual %)\n",p,
"Total-after \$$tradecost/day trade costs: \t$lasttotalaftertradecost (ROI=$roi_at % ROI-annual = $roi_at_annual %)\n";} 
else {
    print h2('Error: undefined information');
}
} else {
    print h2('Error: unidentified trading strategy');
}
}

print p,"<a href=\"quote.pl\">Return to your portfolio</a>";
		