package Database;

use warnings;
use strict;
use Carp;

use DBI;
use Time::Piece;
use feature qw( say );

use lib '/home/gt234sf/GT234SF/lib/';

sub new
{
	my $class	= shift(@_);
	my $self;

	$self = 
	{
		_host		=>	shift(@_),
		_port		=>	shift(@_),
		_username	=>	shift(@_),
		_password	=>	shift(@_),
		_namebase	=>	shift(@_),
	};

	for (keys % { $self })
	{ 
		$self->{ $_ } or croak "@{ [ $_ ] } is required."; 
	}

	bless $self => $class;

	return $self;
}

sub ConnectDatabaseMySQL
{
	my $self 	= shift(@_);

	$self->{_databaseHandShake} = DBI->connect
	(
		"DBI:mysql:database=" . $self->{ _namebase } . ";host=" . $self->{ _host } . ":" . $self->{ _port },
		$self->{ _username },
		$self->{ _password },
		{
			PrintError 				=> 1,
			RaiseError 				=> 0,
			AutoCommit 				=> 1,
			mysql_enable_utf8		=> 1,
			mysql_auto_reconnect 	=> 1,
		}
	) or die "Problem with DBI connect: ".$!;

	say "[" . localtime->hms . "] Available DBI drivers: " . join( " " , DBI->available_drivers() );
	say "[" . localtime->hms . "] Available tables: " . join( " " , $self->{ _databaseHandShake }->tables() );

	return;
}

sub InsertDataToLogPrivmsg
{
	my $self    			= shift(@_);
	my $messageStructure 	= shift(@_);
	my $sth;

	$sth = $self->{ _databaseHandShake }->prepare("INSERT INTO `log_privmsg` (`id`, `nick`, `message`, `ircname`, `host`, `channel`) VALUES (NULL, ?, ?, ?, ?, ?);");
	$sth->execute( 	$messageStructure->{ _nickFromRaw }, 
					$messageStructure->{ _msgFromRaw }, 
					$messageStructure->{ _ircnameFromRaw }, 
					$messageStructure->{ _hostFromRaw }, 
					$messageStructure->{ _channelFromRaw });
	$sth->finish();

	return;
}

sub SelectAdminListFromDataBase
{
	my $self			= shift(@_);
	my $referenceToCore	= shift(@_);
	my $sth;

	$sth = $self->{ _databaseHandShake }->prepare("SELECT `nick` FROM `admin_list`");
	$sth->execute();

	while (my ($nick) = $sth->fetchrow_array())
	{
		push(@{ $referenceToCore->{ _admin }->{ _adminList } }, $nick);
	}

	$sth->finish();

	return;
}

sub DebugQueryToDatabase
{
	# print "".$DBI::err."\r\n";
	# print "".$DBI::errstr."\r\n";
	# print "".$DBI::state."\r\n";

	# DBI->trace(1);
	# DBI->trace(2);

	# my $sth = $dbh->prepare("SELECT * FROM table");
	# $sth->execute();
	# $sth->dump_results();

	# my @tablice = $self->{ _databaseHandShake }->tables();

	# $sth = $self->{ _databaseHandShake }->table_info('', '%', '');
	# my $schemas = $self->{ _databaseHandShake }->selectcol_arrayref($sth, {Columns => [2]});
	# print "Schemas: ", join ', ', @$schemas;

	return 0;
}

1;

__END__

