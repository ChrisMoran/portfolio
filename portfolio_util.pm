package portfolio_util;

require Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(ValidUser UserExists AddUser CreatePortfolio PortfolioInfo);


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
