package Database;

use warnings;
use strict;
use Carp;

use DBI;
use Time::Piece;
use feature qw( say );

use lib '/home/damian/GT234SF/lib/';

sub new
{
	my $class	= shift;
	my $self;

	$self = 
	{
		_host		=>	shift,
		_port		=>	shift,
		_username	=>	shift,
		_password	=>	shift,
		_namebase	=>	shift,
	};

	for (keys % { $self })
	{ 
		$self->{ $_ } or croak "@{ [ $_ ] } is required."; 
	}

	bless $self => $class;

	return $self;
}

sub ConfigureModuleDatabase
{
	my $self 	= shift;

	$self->{_databaseModule} = DBI->connect
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
	say "[" . localtime->hms . "] Available tables: " . join( " " , $self->{ _databaseModule }->tables() );

	return;
}

sub InsertDataToLogPrivmsg
{
	my $self    			= shift;
	my $rawFullStructure 	= shift;
	my $sth;

	$sth = $self->{ _databaseModule }->prepare("INSERT INTO `log_privmsg` (`id`, `nick`, `message`, `ircname`, `host`, `channel`) VALUES (NULL, ?, ?, ?, ?, ?);");
	$sth->execute( 	$rawFullStructure->{ _nickFromRaw }, 
					$rawFullStructure->{ _msgFromRaw }, 
					$rawFullStructure->{ _ircnameFromRaw }, 
					$rawFullStructure->{ _hostFromRaw }, 
					$rawFullStructure->{ _channelFromRaw });
	$sth->finish();

	return;
}

sub SelectAdminListFromDataBase
{
	my $self			= shift;
	my $referenceToCore	= shift;
	my $sth;

	$sth = $self->{ _databaseModule }->prepare("SELECT `nick` FROM `admin_list`");
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

	# my @tablice = $self->{ _databaseModule }->tables();

	# $sth = $self->{ _databaseModule }->table_info('', '%', '');
	# my $schemas = $self->{ _databaseModule }->selectcol_arrayref($sth, {Columns => [2]});
	# print "Schemas: ", join ', ', @$schemas;

	return;
}

1;
__END__