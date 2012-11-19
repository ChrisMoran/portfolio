#!/usr/bin/perl -w

BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="cs339";
  $ENV{PORTF_DBUSER}="lsk250";
  $ENV{PORTF_DBPASS}="z50uWdjGo";

  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
	#$ENV{'PATH'} = "/pdinda/339/HANDOUT/portfolio";
	$ENV{PATH} = "$ENV{PATH}:/home/lsk250/www/portfolio/portfolio-handout";
    exec 'env',cwd().'/'.$0,@ARGV;
  }
};
use Getopt::Long;

&GetOptions("simple"=>\$simple);

$#ARGV==2 or die "usage: markov_symbol.pl [--simple] symbol levels order \n";

($symbol,$levels,$order)=@ARGV;

@output=`get_data.pl --notime --close $symbol | stepify.pl $levels | markov_online.pl $order | eval_pred.pl`;

if ($simple) {
  $output[3]=~/(\d+)/;
  $numsyms=$1;
  $output[4]=~/\((\S+)/;
  $percenttried=$1;
  $output[5]=~/\((\S+)\s+\%\s+of\s+attempts,\s+(\S+)/;
  $percentcorrectofattempts=$1;
  $percentcorrectofall=$2;
  print join("\t",$symbol,$levels,$order,$numsyms,$percenttried,$percentcorrectofattempts,$percentcorrectofall),"\n";
} else {
  print @output;
}


