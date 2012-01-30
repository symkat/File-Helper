package File::Helper;
use warnings;
use strict;
use File::Copy;
use 5.008_008;
$|++;

our $VERSION = "000102"; # 0.1.2;
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

Simple non-nested if statements may be used.

[% IF NAME %]Hello, [% NAME %][% ENDIF %]

[% IF USER %]
Hello [% USER %],

Welcome to the jungle!
[% ENDIF %]

Tokens that are not recognized will be removed,
if statements that do not match will not leave
behind new lines.

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
    my $content = do { local $/; <$lf> };
    close $lf;
    
    pos($content) = 0;
    my $str;

    MAIN: while ( pos($content) != length($content) ) {
        if ( $content =~ /\G\[% IF (.*?) %\]\n?/gc ) {
            my ( $name )  = $1;
            if ( exists $config->{$name} ) {
                while ( pos($content) != length( $content )) {
                    if ( $content =~ /\G\[% ENDIF %\]/gc ) {
                        last;
                    } elsif ( $content =~ /\G\n\[% ENDIF %\]/gc ) {
                        $str .= "\n";
                        last;
                    } elsif ( $content =~ /\G\[% (.*?) %\]/gc) {
                        my ( $name )  = $1;
                        if ( exists $config->{$name} ) {
                            $str .= $config->{$name};
                        } 
                    } elsif ( $content =~ /\G(.*?)\[%/sgc ) {
                        pos($content) = (pos($content) - 2); # Rewind so [% matches later.
                        my ( $token ) = ( $1 );
                        $str .= $token;
                    } else {
                        parser_error( $content, pos($content), $str );
                    }
                }
            } else {
                $content =~ /\G.*?\[% ENDIF %\]\n?/sgc;
                chomp $str if $str; # Remove the newline added by the origional failing if.
            }
        } elsif ( $content =~ /\G\[% (.*?) %\]/gc) {
            my ( $name )  = $1;
            if ( exists $config->{$name} ) {
                $str .= $config->{$name};
            }
        } elsif ( $content =~ /\G(.*?)\[%/sgc ) {
            pos($content) = (pos($content) - 2); # Rewind so [% matches later.
            $str .= $1;
        } elsif ( $content =~ /\G(.*?)/sgc ) {
            $str .= $1; # Content until the end of the file.
        } else {
            parser_error( $content, pos($content), $str );
        }
    }
    return $str;
}

sub parser_error {
    my ( $content, $position, $str ) = @_;
    die "Parser error:\n" .
        "Next 10 chars to parse: " . substr( $content, $position, 10 ) . "\n" .
        "Prev 10 chars parsed  : " . substr( $content, ($position - 10), 10 ) . "\n" .
        "String constructed to this point: " . ( defined $str ? $str : "*NONE*" );
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
