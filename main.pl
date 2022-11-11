#!/usr/bin/perl
#
# Perl BOT GT234SF with AI.
# Version 0.0.1
#

use warnings;
use strict;

use lib '/home/gt234sf/GT234SF/lib/';
use GT234SF;

sub main () 
{
    my $GT234SF;

    eval 
    {
        $GT234SF = new GT234SF();
        $GT234SF->ConnectToDestinationServer();
    }; warn $@ if $@;

    return;
}

main();

