package PDF::TextBlock;

use warnings;
use strict;
use Carp qw( croak );

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

=head1 NAME

PDF::TextBlock - Easier creation of text blocks when using PDF::API2

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    will copy from t/ once working

=head1 DESCRIPTION

Neither Rick Measham's excellent tutorial nor PDF::FromHTML are able to cope with
wanting a single word (words) bolded inside a text block. This module makes that
trivial to do.

=head1 METHODS

=head2 new

uh...

=cut

sub new {
   my ($package, %args) = @_;

   croak "text argument required" unless ($args{text});
   unless (ref $args{pdf} eq "PDF::API2") {
      croak "pdf argument (a PDF::API2 object) required";
   }
   my $text = $args{text};
   my $pdf = $args{pdf};

   my $self = {
      text => $text,
      pdf  => $pdf,
   };

   my %font = (
       Helvetica => {
           Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
           Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
           Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
       },
       #Gotham => {
       #    Bold  => $pdf->ttfont('Gotham-Bold.ttf', -encode => 'latin1'),
       #    Roman => $pdf->ttfont('Gotham-Light.otf', -encode => 'latin1'),
       #},
   );

   my $page = $pdf->page;
   $page->mediabox('letter');
   my $text_obj = $page->text;
   $text_obj->font($font{Helvetica}{Roman}, 8 / pt);
   $text_obj->translate( 100, 100 );
   $text_obj->text($text);

   return bless $self;
}


=head2 apply

This method began life as text_block() in Rick Measham (aka Woosta) 
"Using PDF::API2" tutorial (http://rick.measham.id.au/pdf-api2/). 

=cut

sub apply {
    my ($text_object, $text_object_bold, $text, %arg) = @_;

    my ($endw, $ypos);

    # Get the text in paragraphs
    my @paragraphs = split( /\n/, $text );

    # calculate width of all words
    my $space_width = $text_object->advancewidth(' ');

    my @words = split( /\s+/, $text );
    my %width = ();
    foreach (@words) {
        next if exists $width{$_};
        $width{$_} = $text_object->advancewidth($_);
    }

    $ypos = $arg{'-y'};
    my @paragraph = split( / /, shift(@paragraphs) );

    my $first_line      = 1;
    my $first_paragraph = 1;

    # while we can add another line

    while ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) {

        unless (@paragraph) {
            last unless scalar @paragraphs;

            @paragraph = split( / /, shift(@paragraphs) );

            $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
            last unless $ypos >= $arg{'-y'} - $arg{'-h'};

            $first_line      = 1;
            $first_paragraph = 0;
        }

        my $xpos = $arg{'-x'};

        # while there's room on the line, add another word
        my @line = ();

        my $line_width = 0;
        if ( $first_line && exists $arg{'-hang'} ) {

            my $hang_width = $text_object->advancewidth( $arg{'-hang'} );

            $text_object->translate( $xpos, $ypos );
            $text_object->text( $arg{'-hang'} );

            $xpos       += $hang_width;
            $line_width += $hang_width;
            $arg{'-indent'} += $hang_width if $first_paragraph;

        }
        elsif ( $first_line && exists $arg{'-flindent'} ) {

            $xpos       += $arg{'-flindent'};
            $line_width += $arg{'-flindent'};

        }
        elsif ( $first_paragraph && exists $arg{'-fpindent'} ) {

            $xpos       += $arg{'-fpindent'};
            $line_width += $arg{'-fpindent'};

        }
        elsif ( exists $arg{'-indent'} ) {

            $xpos       += $arg{'-indent'};
            $line_width += $arg{'-indent'};

        }

        while ( @paragraph
            and $line_width + ( scalar(@line) * $space_width ) +
            $width{ $paragraph[0] } < $arg{'-w'} )
        {

            $line_width += $width{ $paragraph[0] };
            push( @line, shift(@paragraph) );

        }

        # calculate the space width
        my ( $wordspace, $align );
        if ( $arg{'-align'} eq 'fulljustify'
            or ( $arg{'-align'} eq 'justify' and @paragraph ) )
        {

            if ( scalar(@line) == 1 ) {
                @line = split( //, $line[0] );

            }
            $wordspace = ( $arg{'-w'} - $line_width ) / ( scalar(@line) - 1 );

            $align = 'justify';
        }
        else {
            $align = ( $arg{'-align'} eq 'justify' ) ? 'left' : $arg{'-align'};

            $wordspace = $space_width;
        }
        $line_width += $wordspace * ( scalar(@line) - 1 );

        if ( $align eq 'justify' ) {
            foreach my $word (@line) {

                if ($word =~ /<b>/) {
                   $word =~ s/<.*?>//g;
                   _debug("BOLD 1", $xpos, $ypos, $word);
                   $text_object_bold->translate( $xpos, $ypos );
                   $text_object_bold->text($word);
                } else {
                   _debug("normal 1", $xpos, $ypos, $word);
                   $text_object->translate( $xpos, $ypos );
                   $text_object->text($word);
                }

                $xpos += ( $width{$word} + $wordspace ) if (@line);

            }
            $endw = $arg{'-w'};
        }
        else {

            # calculate the left hand position of the line
            if ( $align eq 'right' ) {
                $xpos += $arg{'-w'} - $line_width;

            }
            elsif ( $align eq 'center' ) {
                $xpos += ( $arg{'-w'} / 2 ) - ( $line_width / 2 );

            }

            # render the line
            _debug("normal 2", $xpos, $ypos, @line);
            $text_object->translate( $xpos, $ypos );
            $endw = $text_object->text( join( ' ', @line ) );

        }
        $ypos -= $arg{'-lead'};
        $first_line = 0;

    }
    unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);

    return ( $endw, $ypos, join( "\n", @paragraphs ) )
}


sub _debug{
   my ($msg, $xpos, $ypos, @line) = @_;
   print "[$msg $xpos, $ypos] ";
   print join ' ', @line;
   print "\n";
}



=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pdf-textblock at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDF-TextBlock>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDF::TextBlock

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PDF-TextBlock>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PDF-TextBlock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PDF-TextBlock>

=item * Search CPAN

L<http://search.cpan.org/dist/PDF-TextBlock>

=item * Version control

L<http://github.com/jhannah/pdf-textblock/tree/master>

=back


=head1 ACKNOWLEDGEMENTS

This module started from, and has grown on top of Rick Measham's (aka Woosta) 
"Using PDF::API2" tutorial: http://rick.measham.id.au/pdf-api2/

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jay Hannah, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of PDF::TextBlock
