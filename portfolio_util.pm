package portfolio_util;

require Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(ValidUser UserExists AddUser CreatePortfolio PortfolioInfo TransferPortfolios PortfolioCashBalance HoldingsValue CorrelationMatrix IndividualStatsTable CovAndCorrTables);


BEGIN {
    $ENV{'PORTF_DBMS'}='oracle';
    $ENV{'PORTF_DB'}='CS339';
    $ENV{'PORTF_DBUSER'}='lsk250';
    $ENV{'PORTF_DBPASS'}='z50uWdjGo';


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

sub trim {
    my ($str) = @_;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub HistoricalTimeRange {
    my ($symbol) = @_;
    @time = ExecStockSQL('ROW', 'select first, last from CS339.stockssymbols where symbol=rpad(?,16)', $symbol);

    return @time;
}

sub NewTimeRange {
    my ($symbol) = @_;
    my ($count) = ExecStockSQL('COL', 'select count(*) from newstocksdaily where symbol=rpad(?,16)', $symbol);
    if($count > 0) {
	my ($min, $max) = ExecStockSQL('ROW', 'select min(timestamp), max(timestamp) from newstocksdaily where symbol=rpad(?,16)', $symbol);
	return ($min, $max);
    } else {
	return (undef, undef);
    }
}

sub AllTimeRange {
    my ($symbol) = @_;
    my ($histMin, $histMax) = HistoricalTimeRange($symbol);
    my ($newMin, $newMax) = NewTimeRange($symbol);
    if(defined($newMin) && defined($newMax) && defined($histMax) && defined($histMax)) {
	$histMin = ($histMin < $newMin) ? $histMin : $newMin;
	$histMax = ($histMax > $newMax) ? $histMax : $newMax;
	return ($histMin, $histMax);
    } elsif (defined($histMin) && defined($histMax)) {
	return ($histMin, $histMax);
    } else {
	$newMin = 0 if !defined($newMin);
	$newMax = 0 if !defined($newMax);
	return ($newMin, $newMax);
    }
}

sub CacheBeta {
    my ($symbol, $beta, $field, $from, $to) = @_;
    ExecStockSQL(undef, 'insert into CacheBeta (symbol, beta, field, startTime, endTime) values (rpad(?,16),?,?,?,?)', $symbol, $beta, $field, $from, $to);
}

sub CacheCoeffVar {
    my ($symbol, $coeffvar, $field, $from, $to) = @_;
    ExecStockSQL(undef, 'insert into CacheCoeffVar (symbol, coeffvar, field, startTime, endTime) values (rpad(?,16),?,?,?,?)', $symbol, $coeffvar, $field, $from, $to);
}

sub ComputeCoeffVar {
    my ($symbol, $field, $from, $to) = @_;
    my $sql = "select avg($field), stddev($field) from all_stockdailys where symbol=rpad('$symbol',16)";
    $sql.= " and timestamp>=$from";
    $sql.= " and timestamp<=$to";

    my ($mean,$std) = ExecStockSQL("ROW",$sql);
    my $coeffvar = ($mean != 0) ? $std/$mean : 0;
    CacheCoeffVar($symbol, $coeffvar, $field, $from, $to);
    return $coeffvar;
}

sub CoeffVar {
    my ($symbol, $field, $from, $to) = @_;
    $field = "close" if !defined($field);
    my ($minTime, $maxTime) = AllTimeRange($symbol);

    $from = $minTime if !defined($from);
    $from = 0 if !defined($from);

    $to = $maxTime if !defined($to);
    $to = 0 if !defined($to);
    
    my ($coeff) = ExecStockSQL('ROW', 'select coeffvar from CacheCoeffVar where symbol=rpad(?,16) and field=? and startTime=? and endTime=?', $symbol, $field, $from, $to);
    if(defined($coeff)) {
	return $coeff;
    } else {
	return ComputeCoeffVar($symbol, $field, $from, $to);
    }
}

sub ComputeBeta {
    my ($symbol, $field, $from, $to) = @_;
    $sql = "select CORR(a, b) from (select avg($field) as a, timestamp from CS339.stocksdaily sample(10) where timestamp >=$from and timestamp<=$to group by timestamp union all select avg($field) as a, timestamp from newstocksdaily sample(10) where timestamp >=$from and timestamp<=$to group by timestamp) natural join (select $field as b, timestamp from all_stockdailys where symbol=rpad('$symbol', 16) and timestamp >= $from and timestamp<=$to)";
   

    my ($beta) = ExecStockSQL("ROW",$sql);
    if(defined($beta)) {
	CacheBeta($symbol, $beta, $field, $from, $to);
    }
    return $beta;
}

sub Beta {
    my ($symbol, $field, $from, $to) = @_;
    $field = "close" if !defined($field);
    my ($minTime, $maxTime) = AllTimeRange($symbol);

    $from = $minTime if !defined($from);
    $from = 0 if !defined($from);

    $to = $maxTime if !defined($to);
    $to = 0 if !defined($to);
    
    my ($beta) = ExecStockSQL('ROW', 'select beta from CacheBeta where symbol=rpad(?,16) and field=? and startTime=? and endTime=?', $symbol, $field, $from, $to);
    if(defined($beta)) {
	return $beta;
    } else {
	return ComputeBeta($symbol, $field, $from, $to);
    }
}

sub IndividualStats {
    my ($portfolio, $field, $from, $to) = @_;
    $field = "close" if !defined $field;
    my @retVal = ();

    my @symbols = ExecStockSQL('COL', 'select symbol from holdings where portfolio=?', $portfolio);

    for(my $i = 0; $i <= $#symbols; $i++) {
	my $symbol = $symbols[$i];

	my $coeffVar = CoeffVar($symbol, $field, $from, $to);
	
	# can't do a sample on a view so split between old and new
	# new only has limited view of market, so it will be skewed anyway, so split beta into new and old
	my $beta = Beta($symbol, $field, $from, $to);


	my @temp = [$symbol, $coeffVar, $beta];
	push(@retVal, @temp);
  
    }

    return \@retVal;
}


sub IndividualStatsTable {
    my ($portfolio, $field, $from, $to) = @_;
    my ($stats_ref) = IndividualStats($portfolio, $field, $from, $to);
    my @indStats = @$stats_ref;

    my $indTable = "<h4>Individual Stock Stats</h4><table class=\"table table-bordered\"><thead><tr>";
    $indTable .= "<th>Symbol</th><th>Coeff. of Variation</th><th>Beta</th></tr><tbody>";
    for(my $i = 0; $i <= $#indStats; $i++) {
	$indTable .= "<tr><td>" . trim($indStats[$i][0]) . "</td><td>" . sprintf('%1.4f', $indStats[$i][1]) . "</td>";
	$indTable .= "<td>" . sprintf('%1.4f', $indStats[$i][2]) . "</td></tr>";
    }
    $indTable .= "</tbody></table><br/>";
    return $indTable;
}

sub CacheCovAndCorr {
    my ($symbol1, $symbol2, $cov, $corr, $field1, $field2, $start, $end) = @_;
    ExecStockSQL(undef, 'insert into cachecovarience (symbol1, symbol2, cov, corr, field1, field2, startTime, endTime) values (rpad(?,16), rpad(?,16), ?, ?, ?, ?, ?, ?)', $symbol1, $symbol2, $cov, $corr ,$field1, $field2, $start, $end);
}

sub ComputeCovAndCorr {
    my ($s1, $s2, $field1, $field2, $from, $to) = @_;
    my $sql = "select count(*),avg(l.$field1),stddev(l.$field1),avg(r.$field1),stddev(r.$field2) from all_stockdailys l join all_stockdailys r on l.timestamp= r.timestamp where l.symbol=rpad('$s1', 16) and r.symbol=rpad('$s2', 16)";
    $sql.= " and l.timestamp>=$from";
    $sql.= " and l.timestamp<=$to";
    
    my ($count, $mean_f1,$std_f1, $mean_f2, $std_f2) = ExecStockSQL("ROW", $sql);
    
    #skip this pair if there isn't enough data
    
    if ($count<30) { # not enough data
	CacheCovarience($s1, $s2, 0, 0, $field1, $field2, $from, $to);
	return (0, 0);
    } else {
	$sql = "select avg((l.$field1 - $mean_f1)*(r.$field2 - $mean_f2)) from all_stockdailys l join all_stockdailys r on  l.timestamp=r.timestamp where l.symbol=rpad('$s1', 16) and r.symbol=rpad('$s2', 16)";
	$sql.= " and l.timestamp>= $from";
	$sql.= " and l.timestamp<= $to";
	
	my ($covar) = ExecStockSQL("ROW",$sql);
	my $corrcoeff = $covar/($std_f1*$std_f2);
	CacheCovAndCorr($s1, $s2, $covar, $corrcoeff, $field1, $field2, $from, $to);

	return ($covar, $corrcoeff);    
    }
}

sub CovAndCorr {
    my ($s1, $s2, $field1, $field2, $from, $to) = @_;
    my ($start, $end) = AllTimeRange($s1);

    $from = $start if !defined($from);
    $from = 0 if !defined($from);

    $to = $end if !defined($to);
    $to = 0 if !defined($to);
    
    my ($cov, $corr) = ExecStockSQL('ROW', 'select cov, corr from cachecovarience where symbol1=rpad(?,16) and symbol2=rpad(?,16) and field1=? and field2=? and startTime=? and endTime=?', $s1, $s2, $field1, $field2, $from, $to);

    if(defined($cov) && defined($corr)) {
	return ($cov, $corr);
    } else {
	return ComputeCovAndCorr($s1, $s2, $field1, $field2, $from, $to);
    }
    
}

sub CorrelationMatrix {
    my ($portfolio, $field1, $field2, $from, $to) = @_;
   
    $field1 = "close" if !defined $field1;
    $field2 = "close" if !defined $field2;

    
    use Data::Dumper;

    my @symbols = ExecStockSQL('COL', 'select symbol from holdings where portfolio=?', $portfolio);

    
    my (%covar, %corrcoeff) = ((), ());

    for (my $i=0;$i<=$#symbols;$i++) {
	$s1=$symbols[$i];
	$covar{$s1} = ();
	$corrcoeff{$s1} = ();
	for (my $j=$i; $j<=$#symbols; $j++) {
	    $s2=$symbols[$j];
	    my ($cov, $corr) = CovAndCorr($s1, $s2, $field1, $field2, $from, $to);
		
	    $covar{$s1}{$s2} = $cov;
	    $corrcoeff{$s1}{$s2} = $corr;
	
	}
    }

    return (\@symbols, \%covar, \%corrcoeff);
}
    
sub CovAndCorrTables {
    my ($portfolio, $field1, $field2, $from, $to) = @_;
    my ($sym_ref, $cov_ref, $corr_ref) = CorrelationMatrix($portfolio, $field1, $field2, $from, $to);
    my @allSymbols = @$sym_ref;
    my %covar = %$cov_ref;
    my %corrcoeff = %$corr_ref;

    my ($covTable, $corrTable) = ("", "");
    $covTable .= "<h4>Covarience</h4><table class=\"table table-bordered\"><thead><tr><th>Symbol</th>";
    $corrTable .= "<h4>Correlation</h4><table class=\"table table-bordered\"><thead><tr><th>Symbol</th>";

    for(my $k =0; $k <= $#allSymbols; $k++) {
	my $trimmed = trim($allSymbols[$k]);
	$covTable .= "<th>" . $trimmed . "</th>";
	$corrTable .= "<th>". $trimmed . "</th>";
    }
    $covTable .= "</tr></thead><tbody>";
    $corrTable .= "</tr></thead><tbody>";
    for(my $i=0; $i <= $#allSymbols; $i++) {
	$s1 = $allSymbols[$i];
	$covTable .= "<tr><td>$s1</td>";
	$corrTable .= "<tr><td>$s1</td>";
	for(my $j=0; $j <= $#allSymbols; $j++) {
	    if($i > $j) {
		$covTable .= "<td>.</td>";
		$corrTable .= "<td>.</td>";
	    } else {
		$s2 = $allSymbols[$j];
		$covTable .= "<td>" . ($covar{$s1}{$s2} eq "NODAT" ? "NODAT" : sprintf('%3.2f',$covar{$s1}{$s2})) . "</td>";
		$corrTable .= "<td>" . ($corrcoeff{$s1}{$s2} eq "NODAT" ? "NODAT" : sprintf('%3.2f',$corrcoeff{$s1}{$s2})) . "</td>";
		}
	}
	$covTable .= "</tr>";
	$corrTable .= "</tr>";
    }
    $covTable .= "</tbody></table><br/>";
    $corrTable .= "</tbody></table><br/>";
    return ($covTable, $corrTable);
}

sub ValidUser {
    my ($user, $pass) = @_;
    my @result = ExecStockSQL('COL', 'select count(*) from Users where name=? and password=?', $user, $pass);
    return $result[0];
}

sub UserExists {
    my ($user) = @_;
    my @result = ExecStockSQL('COL', 'select count(*) from Users where name=?', $user);
    return $result[0] == 1;
}

sub AddUser {
    my ($user, $pass) = @_;
    ExecStockSQL(undef, 'insert into users (name, password) values (?, ?)', $user, $pass);
}

sub PortfolioInfo {
    my ($user) = @_;
    my @results = ExecStockSQL(undef, 'select id, portfolio_name, assets from Portfolios where user_name=?', $user);
    return @results;
}

sub CreatePortfolio {
    my ($user, $portfolio_name, $cash_amount) = @_;
    ExecStockSQL(undef, 'insert into portfolios (user_name, assets, portfolio_name) values (?, ?, ?)', $user, $cash_amount, $portfolio_name);
}

sub PortfolioCashBalance {
    my ($user, $id) = @_;
    my @results = ExecStockSQL('COL', 'select assets from portfolios where user_name=? and id=?', $user, $id);
    return $results[0];
}

sub HoldingsValue {
    my ($portfolio) = @_;
    my @holdings = ExecStockSQL('COL', 'select symbol from holdings where portfolio=?', $portfolio);
    if(scalar(@holdings) <= 0) {
	return 0;
    } 
    my $inOp = substr(('rpad(?,16),') x scalar(@holdings), 0, -1);

    push(@holdings, $portfolio);

    my @results = ExecStockSQL('COL', "select SUM(shares * close) from (select symbol, close from  all_stockdailys natural join ( select symbol, max(timestamp) as timestamp from all_stockdailys where symbol in ($inOp) group by symbol ) ) natural join (select symbol, shares from holdings where portfolio=?)", @holdings);

    return $results[0];
    
}

# assumes value have been checked already
sub TransferPortfolios {
    my ($user, $fromId, $toId, $amount) = @_;
    $toId = int($toId);
    $fromId = int($fromId);
    ExecStockSQL(undef, 
		 'update portfolios set assets = case id when to_number(?) then (select assets from portfolios where user_name=? and id=?) - ? when to_number(?) then (select assets from portfolios where user_name=? and id=?) + ? end where id in (?, ?) and user_name=?', 
		 $fromId, 
		 $user,
		 $fromId, 
		 $amount, 
		 $toId, 
		 $user, 
		 $toId, 
		 $amount, 
		 $toId, 
		 $fromId, 
		 $user);
}
