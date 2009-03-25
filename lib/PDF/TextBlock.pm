package PDF::TextBlock;

use strict;
use warnings;
use Carp qw( croak );
use File::Temp qw(mktemp);
use Class::Accessor::Fast;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( pdf text fonts x y w h lead parspace align hang flindent fpindent indent ));

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

=head2 apply

The original version of this method was text_block(), which is © Rick Measham, 2004-2007. 
The latest version of text_block() can be found in the tutorial located at http://rick.measham.id.au/pdf-api2/
text_block() is released under the LGPL v2.1.

=cut

sub apply {
   my ($self, %args) = @_;

   my $text = $self->text;
   my $pdf  = $self->pdf;
   croak "text attribute required" unless ($text);
   unless (ref $pdf eq "PDF::API2") {
      croak "pdf attribute (a PDF::API2 object) required";
   }

   $self->_apply_defaults();

   my %fonts = (
      Helvetica => {
         Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
         Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
         Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
      },
      #Gotham => {
      #   Bold  => $pdf->ttfont('Gotham-Bold.ttf', -encode => 'latin1'),
      #   Roman => $pdf->ttfont('Gotham-Light.otf', -encode => 'latin1'),
      #},
   );

   my $page = $pdf->page;
   my $content_text      = $page->text;     # PDF::API2::Content::Text obj
   my $content_text_bold = $page->text;     # PDF::API2::Content::Text obj
   $content_text->font(      $fonts{Helvetica}{Roman},   18 / pt );
   $content_text_bold->font( $fonts{Helvetica}{Bold},    18 / pt );


   $content_text->fillcolor('black');
   $content_text->translate(95 / mm, 131 / mm);
   $content_text->text_right('BLAHgers');
   return 1;

   my ($endw, $ypos);

   # Get the text in paragraphs
   my @paragraphs = split( /\n/, $text );

   # calculate width of all words
   my $space_width = $content_text->advancewidth(' ');

   my @words = split( /\s+/, $text );
   my %width = ();
   foreach (@words) {
      next if exists $width{$_};
      $width{$_} = $content_text->advancewidth($_);
   }

   $ypos = $self->y;
   my @paragraph = split( / /, shift(@paragraphs) );

   my $first_line      = 1;
   my $first_paragraph = 1;

   # while we can add another line

   while ( $ypos >= $self->y - $self->h + $self->lead ) {

      unless (@paragraph) {
         last unless scalar @paragraphs;

         @paragraph = split( / /, shift(@paragraphs) );

         $ypos -= $self->parspace if $self->parspace;
         last unless $ypos >= $self->y - $self->h;

         $first_line      = 1;
         $first_paragraph = 0;
      }

      my $xpos = $self->x;

      # while there's room on the line, add another word
      my @line = ();

      my $line_width = 0;
      if ( $first_line && defined $self->hang ) {
         my $hang_width = $content_text->advancewidth( $self->hang );

         $content_text->translate( $xpos, $ypos );
         $content_text->text( $self->hang );

         $xpos       += $hang_width;
         $line_width += $hang_width;
         $self->indent($self->indent + $hang_width) if $first_paragraph;
      } elsif ( $first_line && defined $self->flindent ) {
         $xpos       += $self->flindent;
         $line_width += $self->flindent;
      } elsif ( $first_paragraph && defined $self->fpindent ) {
         $xpos       += $self->fpindent;
         $line_width += $self->fpindent;
      } elsif ( defined $self->indent ) {
         $xpos       += $self->indent;
         $line_width += $self->indent;
      }

      while ( 
         @paragraph and 
            $line_width + 
            ( scalar(@line) * $space_width ) +
            $width{ $paragraph[0] } 
            < $self->w
      ) {
         $line_width += $width{ $paragraph[0] };
         push( @line, shift(@paragraph) );
      }

      # calculate the space width
      my ( $wordspace, $align );
      if ( $self->align eq 'fulljustify'
         or ( $self->align eq 'justify' and @paragraph ) 
      ) {
         if ( scalar(@line) == 1 ) {
            @line = split( //, $line[0] );
         }
         $wordspace = ( $self->w - $line_width ) / ( scalar(@line) - 1 );
         $align = 'justify';
      } else {
         $align = ( $self->align eq 'justify' ) ? 'left' : $self->align;
         $wordspace = $space_width;
      }
      $line_width += $wordspace * ( scalar(@line) - 1 );

      if ( $align eq 'justify' ) {
         foreach my $word (@line) {
            if ($word =~ /<b>/) {
               $word =~ s/<.*?>//g;
               _debug("BOLD 1", $xpos, $ypos, $word);
               $content_text_bold->translate( $xpos, $ypos );
               $content_text_bold->text($word);
            } else {
               _debug("normal 1", $xpos, $ypos, $word);
               $content_text->translate( $xpos, $ypos );
               $content_text->text($word);
            }
            $xpos += ( $width{$word} + $wordspace ) if (@line);
         }
         $endw = $self->w;
      } else {
         # calculate the left hand position of the line
         if ( $align eq 'right' ) {
            $xpos += $self->w - $line_width;
         } elsif ( $align eq 'center' ) {
            $xpos += ( $self->w / 2 ) - ( $line_width / 2 );
         }
         # render the line
         _debug("normal 2", $xpos, $ypos, @line);
         $content_text->translate( $xpos, $ypos );
         $endw = $content_text->text( join( ' ', @line ) );
      }
      $ypos -= $self->lead;
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


=head2 _apply_defaults

Applies defaults for you wherever you didn't explicitly set a different value.

=cut

sub _apply_defaults {
   my ($self) = @_;
   my %defaults = (
      x        => 20 / mm,
      y        => 238 / mm,
      w        => 170 / mm,
      h        => 220 / mm,
      lead     => 15 / pt,
      parspace => 0 / pt,
      align    => 'justify',
   );
   foreach my $att (keys %defaults) {
      $self->$att($defaults{$att}) unless defined $self->$att;
   }
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

This module started from, and has grown on top of, Rick Measham's (aka Woosta) 
"Using PDF::API2" tutorial: http://rick.measham.id.au/pdf-api2/

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jay Hannah, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of PDF::TextBlock
