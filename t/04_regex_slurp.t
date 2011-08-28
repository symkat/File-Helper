#!/usr/bin/perl
use warnings;
use strict;
use File::Helper;
use Test::More;

ok my $file = File::Helper->new( "t/files/replace" );

ok $file->write( { content => "Hello World" } );

is $file->regex_slurp( sub { s/Hello/Goodbye/ } ),
    "Goodbye World", "Replacement Works.";

unlink( 't/files/replace' );

done_testing;
