use Test::More tests => 10;

use PDF::API2;
use PDF::TextBlock;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

ok(my $pdf = PDF::API2->new( -file => "demo.pdf" ),   "PDF::API2->new()");
ok(my $tb  = PDF::TextBlock->new(
   pdf  => $pdf,
   text => 'blah blah blah...',
),                                                    "PDF::TextBlock->new()");


$pdf->save;    # Doesn't return true, even when it succeeds. -sigh-
$pdf->end;     # Doesn't return true, even when it succeeds. -sigh-
ok(-r "demo.pdf",                                     "demo.pdf created");

diag( "Testing PDF::TextBlock $PDF::TextBlock::VERSION, Perl $], $^X" );
