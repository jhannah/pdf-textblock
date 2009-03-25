use Test::More tests => 10;

# Reproduction of http://rick.measham.id.au/pdf-api2/
# Only using PDF::TextBlock this time

use PDF::API2;
use PDF::TextBlock;
use PDF::TextBlock::Font;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

ok(my $pdf = PDF::API2->new( -file => "20-demo.pdf" ),   "PDF::API2->new()");
my $page = $pdf->page;
$page->mediabox( 105 / mm, 148 / mm );
#$page->bleedbox(  5/mm,   5/mm,  100/mm,  143/mm);
$page->cropbox( 7.5 / mm, 7.5 / mm, 97.5 / mm, 140.5 / mm );
#$page->artbox  ( 10/mm,  10/mm,   95/mm,  138/mm);

my $blue_box = $page->gfx;
$blue_box->fillcolor('darkblue');
$blue_box->rect( 5 / mm, 125 / mm, 95 / mm, 18 / mm );
$blue_box->fill;

my $red_line = $page->gfx;
$red_line->strokecolor('red');
$red_line->move( 5 / mm, 125 / mm );
$red_line->line( 100 / mm, 125 / mm );
$red_line->stroke;

# Headline text
ok(my $tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   text  => 'Using PDF::TextBlock',
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         fillcolor => 'white',
         size      => 18 / pt,
      }),
   },
   x => 95 / mm, 
   y => 131 / mm,
   align => 'text_right',
}),                                                   "new()");
ok(my ($endw, $ypos, $paragraph) = $tb->apply(),      "apply()");
printf("[%s|%s|%s|%s]\n", $endw, $ypos, $paragraph, $tb->text);

$pdf->save;    # Doesn't return true, even when it succeeds. -sigh-
$pdf->end;     # Doesn't return true, even when it succeeds. -sigh-
ok(-r "20-demo.pdf",                                     "20-demo.pdf created");

diag( "Testing PDF::TextBlock $PDF::TextBlock::VERSION, Perl $], $^X" );
