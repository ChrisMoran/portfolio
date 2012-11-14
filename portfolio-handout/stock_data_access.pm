package stock_data_access;

use Data::Dumper;

require Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(ExecStockSQL GetStockPrefix);



my ($dbms,$user,$pass,$db);

use DBI;

sub GetStockPrefix { 
  if ($dbms eq "oracle" || $dbms eq "mysql") { 
    return "$db.";
  }
  if ($dbms eq "cassandra") { 
    return "";
  }
}

#
# @list or $string = ExecStockSQL($type, $querystring @fill);
#
# Executes a SQL statement given in $querystring
#
# $type is "ROW" => returns first row in list
# $type is "COL" => returns first column in list
# $type is "2D" or undef => returns list of row lists (list of listrefs)
# $type is "TEXT" => Returns string output, rows delimited by \n, cols by \t
#
# @fill are the fillers for positional parameters in $querystring
#
# ExecStockSQL executes "die" on failure.
#
sub ExecStockSQL {
  my ($type, $querystring, @fill) = @_;

  my $dbh;

  if ($dbms eq "oracle") { 
    $dbh = DBI->connect("DBI:Oracle:",$user,$pass);
  } elsif ($dbms eq "mysql") { 
    $dbh = DBI->connect("DBI:mysql:$db",$user,$pass);
  } elsif ($dbms eq "cassandra") {
    return ExecStockCQL(@_);
  } else {
    die "Unknown DBMS \"$dbms\"\n";
  }
  
  if (not $dbh) { 
    die "Can't connect to database because of ".$DBI::errstr;
  }

  my $sth = $dbh->prepare($querystring);

  if (not $sth) { 
    my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }

  if (not $sth->execute(@fill)) { 
    my $errstr="Can't execute $querystring with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }

  my @data;

  # One row of output
  if (defined $type and $type eq "ROW") { 
    @data=$sth->fetchrow_array();
    $sth->finish();
    $dbh->disconnect();
    return @data;
  }

  my @ret;
  
  # multirow or single column output or strings
  while (@data=$sth->fetchrow_array()) {
    push @ret, [@data];
  }

  # single column
  if (defined $type and $type eq "COL") { 
    @data = map {$_->[0]} @ret;
    $sth->finish();
    $dbh->disconnect();
    return @data;
  }

  $sth->finish();
  $dbh->disconnect();
  
  # TEXT
  if (defined $type and $type eq "TEXT") { 
    return join("\n", 
		map {join("\t",@{$_}) } @ret )."\n";
  }

  if (!defined $type or $type eq "2D") { 
    return @ret;
  }
  
  die "Unknown type \"$type\" requested\n";
}


#
# @list = ExecStockCQL($type, $querystring);
#
# Executes a CQL statement given in $querystring
#
# $type is "ROW" => returns first row in list
# $type is "COL" => returns first column in list
# $type is "2D" or undef => returns list of row lists (list of listrefs)
# $type is "TEXT" => Returns output, rows delimited by \n, cols by \t
#
# ExecStockCQL executes "die" on failure.
#
sub ExecStockCQL {
  my ($type, $querystring, @fill) = @_;

  die "Cassandra Queuries Not Currently Supported\n";
}



BEGIN {
  $dbms = $ENV{'PORTF_DBMS'};
  $user = $ENV{'PORTF_DBUSER'};
  $pass = $ENV{'PORTF_DBPASS'};
  $db   = $ENV{'PORTF_DB'};

  (defined $db and defined $user and defined $pass and defined $dbms) or die "Environment variables (PORTF_DBMS, PORTF_DBUSER, PORTF_DBPASS, PORTF_DB) not set properly\n";
  
  if (!($dbms eq "oracle") && !($dbms  eq "mysql")) { 
    die "Database \"$dbms\" is not currently support\n";
  }

  if ($dbms eq "oracle") { 
    unless ($ENV{BEGIN_BLOCK}) {
      # Let the insanity roll... 
      use Cwd;
      $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
      $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
      $ENV{ORACLE_SID}="CS339";
      $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
      $ENV{BEGIN_BLOCK} = 1;
      if ($0 =~ /\//) {
          #path given...
          exec $0,@ARGV;
      } else {
          # not a path, use env to find it
          exec "env", $0, @ARGV;
      }
    }
  }
}
