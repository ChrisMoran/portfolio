package portfolio_util;

require Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(ValidUser UserExists AddUser CreatePortfolio PortfolioInfo TransferPortfolios PortfolioCashBalance);


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
