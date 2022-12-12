package Command;

use warnings;
use strict;
use Carp;

use DBI;
use feature qw( say );
use Encode 'encode';

use lib '/home/damian/GT234SF/lib/';
use Database;
use Poland::Weather;

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
	my $self                    = shift;
    my $rawFullStructure        = shift;

    $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . 
                                        " :Available commands: !join [channel] / !part [channer] / !hop [channel] / !weather [city]\r\n");

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

my $_Command004 = sub
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

my $_Command005 = sub
{
	my $self                        = shift;
    my $rawFullStructure            = shift;
    my $paramsCommandFromRaw;
    my $hashWithWeatherListCity;
    my $swichInForeachNotFound      = 0;

    $paramsCommandFromRaw = (split(/\s/,$rawFullStructure->{ _msgFromRaw },2))[1];

    if ($paramsCommandFromRaw)
    {
        $hashWithWeatherListCity = $self->{ _polandWeatherModule }->getListAvaiableCity();

        if ($hashWithWeatherListCity)
        {
            foreach (@{$hashWithWeatherListCity}) 
            {
                if ($paramsCommandFromRaw eq encode('UTF-8', $_->{stacja}))
                {
                    $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :" .
                        "Date " . $_->{data_pomiaru} . " / " .
                        "Time of measurement " . $_->{godzina_pomiaru} . ":00 / " .
                        "Temperature " . $_->{temperatura} . " C / " .
                        "Wind speed " . $_->{predkosc_wiatru} . " km/h / " .
                        "Humidity " . $_->{wilgotnosc_wzgledna} . " % / " .
                        "Total precipitation " . $_->{suma_opadu} . " mm / " .
                        "Atmospheric pressure " . $_->{cisnienie} . " hPa" .
                        "\r\n"
                    );
                    $swichInForeachNotFound = 1;
                }
            }
            if (!$swichInForeachNotFound)
            {
                $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :Statistics for the given city do not exist\r\n");
            }
        }
        else
        {
            $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :Error while download API page\r\n");
        }
    }
    else
    {
        $self->{ _destinationServer }->send("PRIVMSG " . $rawFullStructure->{ _channelFromRaw } . " :You must get a param to make this action\r\n");
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
    $self->{ _polandWeatherModule } = new Poland::Weather();

    return;
}

sub RunCoreCommand
{
    my $self                            = shift;
    my $rawFullStructure                = shift;
    my $actionClientDefinedByCommand;

	$actionClientDefinedByCommand = 
	{
        '!commands'     => sub {$self->$_Command001($rawFullStructure)},
        '!join' 		=> sub {$self->$_Command002($rawFullStructure)},
        '!part' 		=> sub {$self->$_Command003($rawFullStructure)},
        '!hop' 			=> sub {$self->$_Command004($rawFullStructure)},
        '!weather'      => sub {$self->$_Command005($rawFullStructure)},
	};
    
	if (defined $actionClientDefinedByCommand->{(split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[0]})
	{
		$actionClientDefinedByCommand->{(split(/\s/ , $rawFullStructure->{ _msgFromRaw }))[0]}->($rawFullStructure);
	}

    return;
}

1;
__END__