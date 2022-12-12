package Poland::Weather;

#
# This module generate a statistic from public API https://danepubliczne.imgw.pl/api/data/synop
# Have only one method, return full hash with all data from API, multi city, no one city
#

use warnings;
use strict;
use Carp;

use LWP::Simple;
use JSON::XS;

my $_GetRequestToServer = sub
{
    my $self            	= shift;  
	my $contentInJSON;
	my $decodedHashJSON;

	eval
	{
		$contentInJSON = get($self->{_url});
		$decodedHashJSON  = decode_json $contentInJSON;
	};

	if ($@)
	{
		carp $@;
		$decodedHashJSON = 0;
	}

    return $decodedHashJSON;
};

sub new 
{
	my $class 				= shift;
	my $self;

	$self = 
	{
		_url 	=> 'https://danepubliczne.imgw.pl/api/data/synop',
	};

	bless $self => $class;

	return $self;
}

sub getListAvaiableCity
{
    my $self            		= shift;
	my $decodedHashJSON;
	my $tableWithCityAndID		= [];

	$decodedHashJSON = $self->$_GetRequestToServer();

	if (!$decodedHashJSON)
	{
		return;
	}

	return $decodedHashJSON;
}

1;
__END__