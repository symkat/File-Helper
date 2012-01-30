#!/usr/bin/perl
use warnings;
use strict;
use File::Helper;
use Test::More; # skip_all => "Not implimented.";

ok my $file = File::Helper->new( "t/files/template_slurp_conditional.source" );
is $file->template_slurp( { FIRST => "The", LAST => "Doctor", LINE => "Hello" } ),
    File::Helper->new( "t/files/template_slurp_conditional.result" )->slurp,
    "Conditional statements work.";

done_testing;
