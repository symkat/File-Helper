#!/usr/bin/perl
use warnings;
use strict;
use File::Helper;
use Test::More;

my $file = File::Helper->new( "t/files/read" );

ok $file->write( { content => "Hello World\nThis Is A Test" } );

is $file->slurp, "Hello World\nThis Is A Test", "Reading Works.";

unlink( 't/files/read' );

done_testing;
