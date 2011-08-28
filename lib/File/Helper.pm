package File::Helper;
use warnings;
use strict;
use File::Copy;
use 5.008_008;

our $VERSION = "000100"; # 0.1.0;
$VERSION = eval $VERSION;

=head1 NAME

File::Helper - A Simple File Helper

=head1 VERSION

000100 ( 0.1.1 )

=head1 SYNOPSIS


    my $file = File::Helper->new( "/some/file" );
    my $content = $file->slurp;

    $file->write( { content => "New Content" } );
    
    $file->regex_replace( sub { s/New/Old/ } );

    $file->slurp; # Old Content

    $file->write( { content => "Hello [% NAME %]" } );
    $file->template_slurp( { NAME => "World" } ); # Hello World

=head1 DESCRIPTION

This class provices a simple way of interacting with files,
and encapsulates functions I regularly use on files.

No effort has been taken to ensure this works on WIN32 systems.

=head1 METHODS

The following methods are used.

=cut

sub new {
    my ($class, $filename) = @_;
    my $self = bless {}, $class;
    $self->filename($filename);
    return $self;
}

=head2 filename

An accessor for the filename.

=cut

sub filename {
    my $self = shift;
    $self->{_filename} = shift if @_;
    return $self->{_filename};
}

=head2 write 

Write content to the file, either in append or truncate
mode.  Defaults to truncate mode.

$file->write( { content => "Hello World" } );
$file->write( { content => "Hello World", mode => "append" } );

=cut

sub write {
    my ( $self, $opts ) = @_;

    my $mode = ">";
    $mode = ">>" if exists $opts->{mode} and $opts->{mode} eq 'append';

    open my $fh, $mode , $self->filename
        or die "Failed to open " . $self->filename . " for writing: $!";
    print $fh $opts->{content};
    close $fh;

    return $self;
}

=head2 slurp

Return the contents of the file.  This should not be done
on large files, as the entire file's contents are stored in
memory.

my $content = $file->slurp;

=cut

sub slurp {
    my ( $self ) = @_;
    
    open my $fh, "<", $self->filename
        or die "Failed to open " . $self->filename . " for writing: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;
}

=head2 regex_replace

Given one or more regular expressions in an anonymous
subroutine, run the regular expressions on the file
one line at a time, replacing the file's contents.

$file->regex_replace( sub { s/foo/bar/gi, s/blee/baz/g } );

=cut

sub regex_replace {
    my ( $self, $re ) = @_;

    my $file = $self->filename;

    open my $lf, "<", $file
        or die "Failed to read $file: $!";
    open my $sf, ">", "$file.re_file"
        or die "Failed to write $file.re_file: $!";

    while ( my $line = <$lf> ) {
        print $sf map { $re->() ; $_ } $line;
    }
    close $sf;
    close $lf;
    move("$file.re_file", $file);
    return $self;
}

=head2 regex_slurp 

Similar to regex_replace, however the contents of
the file are returned, and no changes to the actual
file are done.

This will return the file contents, so you may not
want to run this on large files.

=cut

sub regex_slurp {
    my ( $self, $re ) = @_;

    my @return;
    
    for my $line ( split /\n/, $self->slurp ) {
        push @return, map { $re->(); $_ } $line;
    }

    return join( "", @return );
}

=head2 template_slurp 

Process a file as a template.  For a file, 
[% KEY %] will be replaced with the value of
the key, as given in the argument.

my $content = $file->template_slurp(
    {
        ACCOUNT => 102044,
        NAME    => "The Doctor",
        BALANCE => "$105.99",
    }
);

=cut

sub template_slurp {
    my ( $self, $config ) = @_;

    my @return;

    open my $lf, "<", $self->filename
        or die "Failed to read " . $self->filename . ": $!";

    while ( my $line = <$lf> ) {
        $line =~ s/\[% (.*?) %\]/$config->{$1}/g;
        push @return, $line;    
    }
    close $lf;
    return join "", @return;
}

=head1 AUTHOR

SymKat I<E<lt>symkat@symkat.comE<gt>>

=head1 COPYRIGHT AND LICENSE

This is free software licensed under a I<BSD-Style> License.  Please see the 
LICENSE file included in this package for more detailed information.

=head1 AVAILABILITY

The latest version of this software is available through GitHub at
https://github.com/symkat/file-helper/

=cut

1;
