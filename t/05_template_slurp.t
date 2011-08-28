#!/usr/bin/perl
use warnings;
use strict;
use File::Helper;
use Test::More;

ok my $file = File::Helper->new( "t/files/template_slurp.source" );
is $file->template_slurp( { NAME => "The Doctor", BALANCE => 105.99 } ),
    File::Helper->new( "t/files/template_slurp.result" )->slurp,
    "Template Slurping Works.";


done_testing;
