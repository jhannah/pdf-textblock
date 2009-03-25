use Test::More tests => 10;

# Reproduction of http://rick.measham.id.au/pdf-api2/
# Using PDF::TextBlock this time

use strict;
use warnings;
use PDF::API2;
use PDF::TextBlock;
use PDF::TextBlock::Font;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

ok(my $pdf = PDF::API2->new( -file => "20-demo.pdf" ),   "PDF::API2->new()");
my $page = $pdf->page;
$page->mediabox( 105/mm, 148/mm );
#$page->bleedbox(  5/mm,   5/mm,  100/mm,  143/mm);
$page->cropbox( 7.5/mm, 7.5/mm, 97.5/mm, 140.5/mm );
#$page->artbox  ( 10/mm,  10/mm,   95/mm,  138/mm);

my $blue_box = $page->gfx;
$blue_box->fillcolor('darkblue');
$blue_box->rect( 5/mm, 125/mm, 95/mm, 18/mm );
$blue_box->fill;

my $red_line = $page->gfx;
$red_line->strokecolor('red');
$red_line->move( 5/mm, 125/mm );
$red_line->line( 100/mm, 125/mm );
$red_line->stroke;

# headline_text   (Shorter to use the original demo for 'text_right'... -grin-)
ok(my $tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   text  => 'Using PDF::TextBlock',
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         fillcolor => 'white',
         size      => 18/pt,
      }),
   },
   x     => 95/mm, 
   y     => 131/mm,
   align => 'text_right',
}),                                                   "new()");
ok($tb->apply(),                                      "apply()");

my $background = $page->gfx;
$background->strokecolor('lightgrey');
$background->circle( 20/mm, 45/mm, 45/mm );
$background->circle( 18/mm, 48/mm, 43/mm );
$background->circle( 19/mm, 40/mm, 46/mm );
$background->stroke;

# left_column_text1
ok($tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         size      => 6/pt,
      }),
   },
   x     => 10/mm, 
   y     => 119/mm, 
   w     => 41.5/mm,
   h     => 110/mm - 7/pt,
   lead  => 7/pt,
}),                                                   "new() left_column_text1");
my ($endw, $ypos, $paragraph);
ok(($endw, $ypos, $paragraph) = $tb->apply(),         "apply()");

# left_column_text - blue bold line
ok($tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   text  => 'Big Blue Line ' x 5,
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         size      => 6/pt,
         fillcolor => 'darkblue',
      }),
   },
   x     => 10/mm, 
   y     => $ypos - 7/pt,   # Dynamic from end of last TextBlock
   w     => 41.5/mm,
   h     => 110/mm - ( 119/mm - $ypos ),
   lead  => 7/pt,
   align => 'center',
}),                                                   "new() left_column_text2 - blue bold line");
ok(($endw, $ypos, $paragraph) = $tb->apply(),         "apply()");

# left_column_text3
ok($tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         size      => 6/pt,
      }),
   },
   x     => 10/mm, 
   y     => $ypos - 7/pt,   # Dynamic from end of last TextBlock
   w     => 41.5/mm,
   h     => 110/mm - ( 119/mm - $ypos ),
   lead  => 7/pt,
}),                                                   "new() left_column_text3");
ok(($endw, $ypos, $paragraph) = $tb->apply(),         "apply()");



$pdf->save;    # Doesn't return true, even when it succeeds. -sigh-
$pdf->end;     # Doesn't return true, even when it succeeds. -sigh-
ok(-r "20-demo.pdf",                                     "20-demo.pdf created");

diag( "Testing PDF::TextBlock $PDF::TextBlock::VERSION, Perl $], $^X" );
