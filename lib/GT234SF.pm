package GT234SF;

use warnings;
use strict;
use Carp;

use IO::Socket::INET;
use YAML::XS;
use String::Trim;
use Time::Piece;
use feature qw( say );

use lib '/home/damian/Projects/GT234SF/lib/';
use Database;
use Command;

my $_Raw001 = sub 
{
	my $self					= shift;
	my $fullRawFromServer		= shift;

	$self->{ _paramConnectedServer }->{ serverName } =  substr((split(/\s/, $fullRawFromServer))[0], 1);
	say "[" . localtime->hms . "] Connected to server " . $self->{ _paramConnectedServer }->{ serverName };

	$self->{ _destinationServer }->send(
										"PRIVMSG NickServ :IDENTIFY " . 
										$self->{ _yamlFileConfig }->{ credentials }->{ password } . "\r\n") 
										if $self->{ _yamlFileConfig }->{ credentials }->{ password };

	$self->{ _destinationServer }->send(
										"JOIN " . 
										$self->{ _yamlFileConfig }->{ config }->{ rooms } . "\r\n") 
										if ($self->{ _yamlFileConfig }->{ config }->{ autojoin });

	$self->{ _commandModule } = new Command($self->{ _destinationServer }, $self->{ _databaseModule });
	$self->{ _commandModule }->ConfigureModuleCommand();

	# use Data::Dumper;
	# print Dumper($self);
	return;
};

my $_RawPRIVMSG = sub 
{
	my $self					= shift;
	my $fullRawFromServer		= shift;
	my $rawFullStructure 		= {};

	$rawFullStructure->{ _channelFromRaw } 		= (split(/\s/, $fullRawFromServer, 4))[2];
	$rawFullStructure->{ _msgFromRaw } 			= substr((split(/\s/, $fullRawFromServer, 4))[3], 1);
	$rawFullStructure->{ _nickFromRaw } 		= substr((split(/\!/, (split(/\s/, $fullRawFromServer, 4))[0]))[0], 1);
	$rawFullStructure->{ _ircnameFromRaw } 		= (split(/\@/,(split(/\!/, (split(/\s/, $fullRawFromServer, 4))[0]))[1]))[0];
	$rawFullStructure->{ _hostFromRaw } 		= (split(/\@/, (split(/\s/, $fullRawFromServer, 4))[0]))[1];

	$rawFullStructure->{ _msgFromRaw } =~ s/%C.*?%//g;
	$rawFullStructure->{ _msgFromRaw } =~ s/%I(.*?)%/<$1>/g;
	$rawFullStructure->{ _msgFromRaw } =~ s/%F.*?%//g;

	$self->{ _commandModule }->RunCoreCommand($rawFullStructure);
	$self->{ _databaseModule }->InsertDataToLogPrivmsg($rawFullStructure);

	return;
};

my $_AnalyzeRawFromServer = sub 
{
	my $self								= shift;
	my $fullRawFromServer					= shift;
	my $actionClientDefinedByRawServer;

	$actionClientDefinedByRawServer = 
	{
		'001' 			=> sub {$self->$_Raw001( $fullRawFromServer )},
		'PRIVMSG' 		=> sub {$self->$_RawPRIVMSG( $fullRawFromServer )},
	};

	if (defined $actionClientDefinedByRawServer->{(split(/\s/, $fullRawFromServer))[1]})
	{
		$actionClientDefinedByRawServer->{(split(/\s/, $fullRawFromServer))[1]}->($fullRawFromServer);
	}
	else
	{
		if ((split(/\s/, $fullRawFromServer))[0] eq 'PING')
		{
			$self->{ _destinationServer }->send("PONG :" . $self->{ _paramConnectedServer }->{ serverName });
		}
	}

	return;
};

sub new 
{
	my $class 				= shift;
	my $self 				= {};

	bless $self => $class;

	return $self;
}

sub ConnectToDestinationServer 
{
    my $self 				= shift;
	my $dataFromSocket;

	$self->{ _yamlFileConfig } = YAML::XS::LoadFile('config.yml') or die "Problem with YAML file: ".$!;

	$self->{ _databaseModule } = new Database(	$self->{ _yamlFileConfig }->{ database }->{ host }, 
													$self->{ _yamlFileConfig }->{ database }->{ port }, 
													$self->{ _yamlFileConfig }->{ database }->{ username }, 
													$self->{ _yamlFileConfig }->{ database }->{ password }, 
													$self->{ _yamlFileConfig }->{ database }->{ namebase });
	$self->{ _databaseModule }->ConfigureModuleDatabase();

	$self->{ _destinationServer } = IO::Socket::INET->new
	(
		PeerAddr => $self->{ _yamlFileConfig }->{ host }->{ server },
		PeerPort => $self->{ _yamlFileConfig }->{ host }->{ port },
		Proto    => 'tcp',
    ) or die "Socket problem: ".$!;

	$self->{ _destinationServer }->autoflush( 1 );

    $self->{ _destinationServer }->send("NICK " . $self->{_yamlFileConfig}->{credentials}->{nick} . "\r\n");
    $self->{ _destinationServer }->send("USER "
							.$self->{ _yamlFileConfig }->{ credentials }->{ username }." "
							.$self->{ _yamlFileConfig }->{ host }->{ server }." * :"
							.$self->{ _yamlFileConfig }->{ credentials }->{ realname }." "
							.$self->{ _yamlFileConfig }->{ build }->{ version }."\r\n");

	$dataFromSocket = $self->{ _destinationServer };
    while(my $fullRawFromServer = <$dataFromSocket>)
    {
		trim($fullRawFromServer);
        $self->$_AnalyzeRawFromServer($fullRawFromServer);
		say $fullRawFromServer;
    }
}

1;
__END__