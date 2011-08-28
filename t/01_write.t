#!/usr/bin/perl
use warnings;
use strict;
use File::Helper;
use Test::More;

ok my $file = File::Helper->new( "t/files/write" );

ok $file->write( { content => "Hello World" });

is( get_contents($file), "Hello World", "Write works." );

ok $file->write( { content => "Goodbye World" } );

is( get_contents($file), "Goodbye World", "Write after write works." );

ok $file->write( { mode => 'append', content => "\nHello World" } );

is( get_contents($file), "Goodbye World\nHello World", "Append after write works." );

unlink( 't/files/write' );

done_testing();

sub get_contents {
    my ( $file ) = @_;
    open my $lf, "<", $file->filename 
        or die "Failed to read " . $file->filename . ": $!";
    my $content = do { local $/; <$lf> };
    close $lf;
    return $content;
}
