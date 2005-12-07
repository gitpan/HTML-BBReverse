#########################

use Test::More tests => 36;
BEGIN { use_ok 'HTML::BBReverse'; }

#########################

use strict;
use warnings;

my $bbr = HTML::BBReverse->new();
isa_ok($bbr, 'HTML::BBReverse', 'default');

my @tests = (
 # [ input, parsed, reversed, name ],

## the basic tags
 [ '[i]italic[/i]', '<i>italic</i>', '[i]italic[/i]', 'italic' ],
 [ '[b]bold[/b]', '<b>bold</b>', '[b]bold[/b]', 'bold' ],
 [ '[u]underlined[/u]', '<span style="text-decoration: underline">underlined</span><!--1-->', '[u]underlined[/u]', 'underlined' ],
 [ '[img]pic.png[/img]', '<img src="pic.png" alt="" />', '[img]pic.png[/img]', 'img1'  ],
 [ '[img=pic.png]desc[/img]', '<img src="pic.png" alt="desc" title="desc" />', '[img=pic.png]desc[/img]', 'img2'  ],
 [ '[url=/file]desc[/url]', '<a href="/file">desc</a>', '[url=/file]desc[/url]','url' ],
 [ '[email]some@mail.com[/email]', '<a href="mailto: some@mail.com">some@mail.com</a>', '[email]some@mail.com[/email]', 'email'],
 [ '[size=20]text[/size]', '<span style="font-size: 20px">text</span><!--2-->', '[size=20]text[/size]',    'size' ],
 [ '[color=red]text[/color]', '<span style="color: red">text</span><!--3-->', '[color=red]text[/color]',  'color' ],
 [ '[quote]some quote[/quote]', '<span class="bbcode_quote_header">Quote: <span class="bbcode_quote_body">some quote</span></span>', '[quote]some quote[/quote]', 'quote1' ],
 [ '[quote=author]some quote[/quote]', '<span class="bbcode_quote_header">author wrote: <span class="bbcode_quote_body">some quote</span></span>', '[quote=author]some quote[/quote]', 'quote2' ],
 [ '[code]some code[/code]', '<span class="bbcode_code_header">Code: <span class="bbcode_code_body">some code</span> </span>', '[code]some code[/code]', 'code' ],
 [ "\n", "<br />\n", "\n", 'linebreak', 1 ],

## combinations and tricks
 [ '[code]some code[/code][code]more [code][/code]', '<span class="bbcode_code_header">Code: <span class="bbcode_code_body">some code</span> </span><span class="bbcode_code_header">Code: <span class="bbcode_code_body">more [code]</span> </span>', '[code]some code[/code][code]more [code][/code]', 'comp-code' ],
 [ '[u]under[b]bol[i]ital[/i]ic[/b]d[/u]lined...', '<span style="text-decoration: underline">under<b>bol<i>ital</i>ic</b>d</span><!--1-->lined...', '[u]under[b]bol[i]ital[/i]ic[/b]d[/u]lined...', 'comp-markup'],
 [ '[url=http://yorhel.nl/][img=yorhel.jpg]Welcome![/img][/url]', '<a href="http://yorhel.nl/"><img src="yorhel.jpg" alt="Welcome!" title="Welcome!" /></a>', '[url=http://yorhel.nl/][img=yorhel.jpg]Welcome![/img][/url]', 'comp-urlimg' ],
 [ "[quote=yorhel]test\r\n[quote]'who cares!'[/quote]...\n[/quote]", "<span class=\"bbcode_quote_header\">yorhel wrote: <span class=\"bbcode_quote_body\">test<br />\n<span class=\"bbcode_quote_header\">Quote: <span class=\"bbcode_quote_body\">'who cares!'</span></span>...<br />\n</span></span>", "[quote=yorhel]test\n[quote]'who cares!'[/quote]...\n[/quote]", 'comp-quotes' ],
);

foreach my $i (0..$#tests) {
  my $html = $bbr->parse($tests[$i][0]);
  my $extra = $tests[$i][4] ? '' : "\n";
  is($html, "$tests[$i][1]$extra", "$tests[$i][3]-parse");
  is($bbr->reverse($html), "$tests[$i][2]$extra", "$tests[$i][3]-reverse");
}
