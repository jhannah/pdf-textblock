use Test::More tests => 4;

# Bold every other word under various alignments.

use PDF::API2;
use PDF::TextBlock;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;


ok(my $pdf = PDF::API2->new( -file => "30-demo.pdf" ),   "PDF::API2->new()");
my $fonts = { 
   b => PDF::TextBlock::Font->new({
      pdf  => $pdf,
      font => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
   }),
};

ok(my $tb  = PDF::TextBlock->new({
   pdf   => $pdf,
   fonts => $fonts,
   align => 'fulljustify',
}),                                                   "new()");

# Tag every other word with <b>.
my $text = $tb->garbledy_gook;
$text =~ s/(\w+) (\w+)/$1 <b>$2<\/b>/g;
$tb->text($text);

my ($endw, $ypos);
ok(($endw, $ypos) = $tb->apply(),                     "apply()");


$tb->y(200);
$tb->align('right');
ok(($endw, $ypos) = $tb->apply(),                     "apply()");


$pdf->save;    # Doesn't return true, even when it succeeds. -sigh-
$pdf->end;     # Doesn't return true, even when it succeeds. -sigh-
ok(-r "30-demo.pdf",                                  "30-demo.pdf created");

diag( "Testing PDF::TextBlock $PDF::TextBlock::VERSION, Perl $], $^X" );



