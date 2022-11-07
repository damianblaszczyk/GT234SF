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
    my $self            = shift(@_);
    my $nickFromRaw     = shift(@_);    

	foreach (@{$self->{ _admin }->{ _adminList }})
	{
		if ($nickFromRaw eq $_)
        {
            return 1;
        }
	}

    return 0;
};

my $_Command001 = sub
{
	my $self                = shift(@_);
    my $fullRawFromServer   = shift(@_);
    my $paramsCommandFromRaw;

    $paramsCommandFromRaw = (split(/\s/,$fullRawFromServer->{ _msgFromRaw }))[1];

    if ($self->$_CheckUserIsAdmin($fullRawFromServer->{ _nickFromRaw }))
    {
        if ($paramsCommandFromRaw)
        {
            $self->{ _destinationServer }->send("PART " . $paramsCommandFromRaw . "\r\n");
            $self->{ _destinationServer }->send("JOIN " . $paramsCommandFromRaw . "\r\n");
        }
    }

    return 0;
};

my $_Command002 = sub
{
	my $self                = shift(@_);
    my $fullRawFromServer   = shift(@_);
    my $paramsCommandFromRaw;

    $paramsCommandFromRaw = (split(/\s/ , $fullRawFromServer->{ _msgFromRaw }))[1];

    if ($self->$_CheckUserIsAdmin($fullRawFromServer->{ _nickFromRaw }))
    {
        if ($paramsCommandFromRaw)
        {
            $self->{ _destinationServer }->send("JOIN " . $paramsCommandFromRaw . "\r\n");
        }
    }

    return 0;
};

my $_Command003 = sub
{
	my $self                = shift(@_);
    my $fullRawFromServer   = shift(@_);
    my $paramsCommandFromRaw;

    $paramsCommandFromRaw = (split(/\s/ , $fullRawFromServer->{ _msgFromRaw }))[1];

    if ($self->$_CheckUserIsAdmin($fullRawFromServer->{ _nickFromRaw }))
    {
        if ($paramsCommandFromRaw)
        {
            $self->{ _destinationServer }->send("PART " . $paramsCommandFromRaw . "\r\n");
        }
    }

    return 0;
};

sub new
{
	my $class       = shift(@_);
	my $self;

	$self = 
	{
		_destinationServer      => shift(@_),
        _databaseHandShake      => shift(@_),
	};

	for (keys % { $self })
	{ $self->{$_} or croak "@{ [ $_ ] } is required."; }

	bless $self => $class;

	return $self;
}

sub ConfigureCoreCommand
{
    my $self    = shift(@_);

    $self->{ _databaseHandShake }->SelectAdminListFromDataBase($self);

    return 0;
}

sub RunCoreCommand
{
    my $self                            = shift(@_);
    my $fullRawFromServer               = shift(@_);
    my $actionClientDefinedByCommand;

	$actionClientDefinedByCommand = 
	{
        '!hop' 			=> sub {$self->$_Command001($fullRawFromServer)},
        '!join' 		=> sub {$self->$_Command002($fullRawFromServer)},
        '!part' 		=> sub {$self->$_Command003($fullRawFromServer)},
	};
	if (defined $actionClientDefinedByCommand->{(split(/\s/ , $fullRawFromServer->{ _msgFromRaw }))[0]})
	{
		$actionClientDefinedByCommand->{(split(/\s/ , $fullRawFromServer->{ _msgFromRaw }))[0]}->($fullRawFromServer);
	}

    say ((split(/\s/ , $fullRawFromServer->{ _msgFromRaw }))[0]);

    return 0;
}

1;
__END__
