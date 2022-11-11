package Command;

use warnings;
use strict;
use Carp;

use DBI;
use feature qw( say );

use lib '/home/gt234sf/GT234SF/lib/';
use Database;

my $_CheckUserIsAdmin = sub
{
    my $self            = shift;
    my $nickFromRaw     = shift;    

	foreach my $nickFromListDataBase (@{$self->{ _admin }->{ _adminList }})
	{
		if ($nickFromRaw eq $nickFromListDataBase)
        {
            return 1;
        }
	}

    return;
};

my $_Command001 = sub
{
	my $self                = shift;
    my $rawFullStructure    = shift;
    my $paramsCommandFromRaw;

    $paramsCommandFromRaw = (split(/\s/,$rawFullStructure->{ _msgFromRaw }))[1];

    if ($self->$_CheckUserIsAdmin($rawFullStructure->{ _nickFromRaw }))
    {
        if ($paramsCommandFromRaw)
        {
            $self->{ _destinationServer }->send("PART " . $paramsCommandFromRaw . "\r\n");
            $self->{ _destinationServer }->send("JOIN " . $paramsCommandFromRaw . "\r\n");
        }
        else
        {
            $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :You must get a param to make this action\r\n");
        }
    }

    return;
};

my $_Command002 = sub
{
	my $self                = shift;
    my $rawFullStructure    = shift;
    my $paramsCommandFromRaw;

    $paramsCommandFromRaw = (split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[1];

    if ($self->$_CheckUserIsAdmin($rawFullStructure->{ _nickFromRaw }))
    {
        if ($paramsCommandFromRaw)
        {
            $self->{ _destinationServer }->send("JOIN " . $paramsCommandFromRaw . "\r\n");
        }
        else
        {
            $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :You must get a param to make this action\r\n");
        }        
    }

    return;
};

my $_Command003 = sub
{
	my $self                    = shift;
    my $rawFullStructure        = shift;
    my $paramsCommandFromRaw;

    $paramsCommandFromRaw = (split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[1];

    if ($self->$_CheckUserIsAdmin($rawFullStructure->{ _nickFromRaw }))
    {
        if ($paramsCommandFromRaw)
        {
            $self->{ _destinationServer }->send("PART " . $paramsCommandFromRaw . "\r\n");
        }
        else
        {
            $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :You must get a param to make this action\r\n");
        }        
    }

    return;
};

sub new
{
	my $class   = shift;
	my $self;

	$self = 
	{
		_destinationServer  => shift,
        _databaseModule     => shift,
	};

	for (keys % { $self }) 
    { 
        $self->{$_} or croak "@{ [ $_ ] } is required."; 
    }

	bless $self => $class;

	return $self;
}

sub ConfigureModuleCommand
{
    my $self    = shift;

    $self->{ _databaseModule }->SelectAdminListFromDataBase($self);

    return;
}

sub RunCoreCommand
{
    my $self                            = shift;
    my $rawFullStructure                = shift;
    my $actionClientDefinedByCommand;

	$actionClientDefinedByCommand = 
	{
        '!hop' 			=> sub {$self->$_Command001($rawFullStructure)},
        '!join' 		=> sub {$self->$_Command002($rawFullStructure)},
        '!part' 		=> sub {$self->$_Command003($rawFullStructure)},
	};
	if (defined $actionClientDefinedByCommand->{(split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[0]})
	{
		$actionClientDefinedByCommand->{(split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[0]}->($rawFullStructure);
	}

    say ((split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[0]);

    return;
}

1;
__END__
