#!/usr/bin/perl
use warnings;
use strict;
use File::Helper;
use Test::More;

ok my $file = File::Helper->new( "t/files/replace" );

ok $file->write( { content => "Hello World" } );
ok $file->regex_replace( sub { s/Hello/Goodbye/ } );

is $file->slurp, 'Goodbye World', "Replacement works.";

unlink( 't/files/replace' );

done_testing;
