#!/bin/perl

package HTML::BBReverse;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.01";

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my %args;
  %args = @_ if $#_ % 2;
  warn "Odd argument list at " . __PACKAGE__ . "::new" unless $#_ % 2;
  
  my %options = (
    allowed_tags => [ qw( b i u code url size color img quote list email ) ],
    reverse_for_edit => 1,
    in_paragraph => 0,
  );
  my $me = bless { %options, %args}, $class;
  return $me;
}


sub parse {
  my $self = shift;
  local $_ = shift;
 
  my %alwd; 
  foreach my $tag (@{$self->{allowed_tags}}) { $alwd{$tag} = 1 } 
  
  s/\&/\&amp\;/g;
  s/</\&lt\;/g;
  s/>/\&gt\;/g;
  s/\r?\n/<br \/>\n/g;
  if($alwd{code}) {
    $_ = $self->_code2html($_);
  } if($alwd{list}) {
    $_ = $self->_list2html($_);
  } if($alwd{b}) {
    s/\[b\]/<b>/g;
    s/\[\/b\]/<\/b>/g;
  } if($alwd{i}) {
    s/\[i\]/<i>/g;
    s/\[\/i\]/<\/i>/g;
  } if($alwd{u}) {
    s/\[u\]/<span style=\"text-decoration: underline\">/g;
    s/\[\/u\]/<\/span><!--1-->/g;
  } if($alwd{img}) {
    s/\[img\]([^"\[]+)\[\/img\]/<img src=\"$1\" alt=\"\" \/>/g; #"
    s/\[img=([^"\]]+)\]([^"\[]+)\[\/img\]/<img src=\"$1\" alt=\"$2\" title=\"$2\" \/>/g; #"
  } if($alwd{url}) {
    s/\[url=([^\]"]+)\]/<a href=\"$1\">/g;  #"
    s/\[\/url\]/<\/a>/g;
  } if($alwd{email}) {
    s/\[email\]([^"\[]+)\[\/email\]/<a href=\"mailto: $1\">$1<\/a>/g; #"
  } if($alwd{size}) {
    s/\[size=([0-9]{1,2})\]/<span style=\"font-size: $1px\">/g;
    s/\[\/size\]/<\/span><!--2-->/g;
  } if($alwd{color}) {
    s/\[color=([^"\]\s]+)\]/<span style=\"color: $1\">/g;  #"
    s/\[\/color\]/<\/span><!--3-->/g;
  } if($alwd{quote}) {
    s/\[quote\]/<span class=\"bbcode_quote_header\">Quote: <span class=\"bbcode_quote_body\">/g;
    s/\[quote=([^<\]]+)\]/<span class=\"bbcode_quote_header\">$1 wrote: <span class=\"bbcode_quote_body\">/g;
    s/\[\/quote\]/<\/span><\/span>/g;
  }
  s/\&#91\;/[/g;
  s/\&#93\;/]/g;
  
  return $_;
}

sub reverse {
  my $self = shift;
  local $_ = shift;
 
  my %alwd; 
  foreach my $tag (@{$self->{allowed_tags}}) { $alwd{$tag} = 1 } 
  
  if($alwd{code}) {
    $_ = $self->_code2bb($_);
  } if($alwd{list}) {
    $_ = $self->_list2bb($_);
  } if($alwd{b}) {
    s/<b>/[b]/g;
    s/<\/b>/[\/b]/g;
  } if($alwd{i}) {
    s/<i>/[i]/g;
    s/<\/i>/[\/i]/g;
  } if($alwd{u}) {
    s/<span style=\"text-decoration: underline\">/[u]/g;
    s/<\/span><!--1-->/[\/u]/g;
  } if($alwd{img}) {
    s/<img src=\"([^"\[]+)\" alt=\"\" \/>/\[img\]$1\[\/img\]/g; #" 
    s/<img src=\"([^"\[]+)\" alt=\"([^"\[]+)\" title=\"\2\" \/>/\[img=$1\]$2\[\/img\]/g; #" 
  } if($alwd{email}) {
    s/<a href=\"mailto: ([^\["]+)\">\1<\/a>/\[email\]$1\[\/email\]/g; #"
  } if($alwd{url}) {
    s/<a href=\"([^\]"]+)\">/\[url=$1\]/g; #"
    s/<\/a>/\[\/url\]/g;
  } if($alwd{size}) {
    s/<span style=\"font-size: ([0-9]{1,2})px\">/\[size=$1\]/g;
    s/<\/span><!--2-->/\[\/size\]/g;
  } if($alwd{color}) {
    s/<span style=\"color: ([^"\]\s]+)\">/\[color=$1\]/g; #" 
    s/<\/span><!--3-->/\[\/color\]/g;
  } if($alwd{quote}) {
    s/<span class=\"bbcode_quote_header\">Quote: <span class=\"bbcode_quote_body\">/\[quote\]/g;
    s/<span class=\"bbcode_quote_header\">([^<\]]+) wrote: <span class=\"bbcode_quote_body\">/\[quote=$1\]/g;
    s/<\/span><\/span>/\[\/quote\]/g;
  }
  s/<br \/>\r?\n/\n/g;
  if(!$self->{reverse_for_edit}) {
    s/\&gt\;/>/g;
    s/\&lt\;/</g;
    s/\&amp\;/\&/g;
  }
  s/\&#91\;/[/g;
  s/\&#93\;/]/g;
  return $_;
}

sub _code2html {
  my $self = shift;
  my $str = shift;
  my $incode = 0;
  my $return = ""; my $first = 0;
  foreach my $line (split(/\[/, $str)) {
    $line = "[$line" if $first; $first = 1;
    if(!$incode && $line =~ s/^\[code\]//) {
      $return .= "<span class=\"bbcode_code_header\">Code: <span class=\"bbcode_code_body\">";
      $incode = 1;
    }
    if($incode && $line =~ s/^\[\/code\]//) {
      $return .= "</span> </span>";
      $incode = 0;
    }
    $return .= $incode ? _codeparse($line) : $line;
  }  
  return $return;
}
sub _code2bb {
  my $self = shift;
  my $str = shift;
  my $incode = 0;
  my $return = ""; my $first = 0; my $next = 0;
  foreach my $line (split(/</, $str)) {
    $line = "<$line" if $first; $first = 1;
    if(!$incode && !$next && $line =~ s/^<span class=\"bbcode_code_header\">Code: //) {
      $next = 1;
    } if(!$incode && $next && $line =~ s/^<span class=\"bbcode_code_body\">//) {
      $return .= '[code]';
      $incode = 1; $next = 0;
    } if($incode && !$next && $line =~ s/^<\/span> //) {
      $next = 1;
    } if($incode && $next && $line =~ s/^<\/span>//) {
      $return .= '[/code]';
      $incode = 0; $next = 0;
    }
    $return .= $incode ? _codeparse($line) : $line;
  }  
  return $return;
}
sub _codeparse {
  local $_ = shift;
  s/\[/\&#91\;/g;
  s/\]/\&#93\;/g;
  s/<br \/>\r?\n/\n/g;
  return $_;
}

sub _list2html {
  my $self = shift;
  my $str = shift;
  my $return = ""; my $inlist = 0; my $liststart = 0; 
  my $m1; my $m2; my $item; my @items;
  foreach my $line (split(/\r?\n/, $str)) {
    $line .= "\n";
    if($line =~ s/^(.*)\[list(=a|=1)?\]//) {
      $m1 = $1; $m2 = $2;
      if($inlist) {
        @items = split(/\[\*\]/, $m1);
        foreach $item (0..$#items) {
          $return .= $items[$item] if !$item && $inlist == $liststart;
          $return .= "</li><li>$items[$item]" if $item && $inlist == $liststart;
          (($return .= "<li>$items[$item]") && ++$liststart) if $item && $inlist != $liststart;
        }
      } else { $return .= $m1 }
      $return .= '</p>' if !$inlist && $self->{in_paragraph};
      $return .= '<ul>' if !$m2;
      $return .= '<ul style="list-style-type: decimal">' if $m2 && $m2 eq "=1";
      $return .= '<ul style="list-style-type: lower-roman">' if $m2 && $m2 eq "=a";
      $return .= "\n";
      $inlist++;
    }
    if($inlist && $line =~ s/^(.*)\[\/list\]//) {
      @items = split(/\[\*\]/, $1);
      foreach $item (0..$#items) {
        $return .= $items[$item] if !$item && $inlist == $liststart;
        $return .= "</li><li>$items[$item]" if $item && $inlist == $liststart;
        (($return .= "<li>$items[$item]") && ++$liststart) if $item && $inlist != $liststart;
      }
      $return .= '</li></ul>';
      $return .= '<p>' if $inlist == 1 && $self->{in_paragraph};
      $liststart = --$inlist;
    }
    if($inlist) {
      @items = split(/\[\*\]/, $line);
      foreach $item (0..$#items) {
        $return .= $items[$item] if !$item && $inlist == $liststart;
        $return .= "</li><li>$items[$item]" if $item && $inlist == $liststart;
        (($return .= "<li>$items[$item]") && ++$liststart) if $item && $inlist != $liststart;
      }
    } else {
      $return .= $line;
    }
  }
  return $return;
}
sub _list2bb {
  my $self = shift;
  my $str = shift;
  my $return = ""; my $inlist = 0;
  my $m1; my $m2; my $item; my @items;
  foreach my $line (split(/\r?\n/, $str)) {
    $line .= "\n";
    if($line =~ s/^(.*)<ul( style=\"list-style-type: (decimal|lower-roman)\")?>//) {
      $m1 = $1; $m2 = $3;
      $m1 =~ s/<\/p>$//;
      if($inlist) {
        @items = split(/<li>/, $m1);
        foreach $item (0..$#items) {
          $items[$item] =~ s/<\/li>$//;
          $return .= $items[$item] if !$item;
          $return .= '[*]' . $items[$item] if $item;
        }
      } else { $return .= $m1 }
      $return .= '[list]' if !$m2;
      $return .= '[list=1]' if $m2 && $m2 eq ' style="list-style-type: decimal"';
      $return .= '[list=a]' if $m2 && $m2 eq ' style="list-style-type: lower-roman"';
      $inlist++;
    }
    if($inlist && $line =~ s/^(.*)<\/ul>(?:<p>)?//) {
      @items = split(/<li>/, $1);
      foreach $item (0..$#items) {
        $items[$item] =~ s/<\/li>$//;
        $return .= $items[$item] if !$item;
        $return .= '[*]' . $items[$item] if $item;
      }
      $return .= '[/list]';
      $inlist--;
    }
    if($inlist) {
      @items = split(/<li>/, $line);
      foreach $item (0..$#items) {
        $items[$item] =~ s/<\/li>$//;
        $return .= $items[$item] if !$item;
        $return .= '[*]' . $items[$item] if $item;
      }
    } else {
      $return .= $line;
    }
  }
  return $return;
}



1;

__END__

=head1 NAME

HTML::BBReverse - Perl module to convert HTML to BBCode and back

=head1 SYNOPSIS

  use HTML::BBReverse
  
  my $bbr = HTML::BBReverse->new();
  
  # convert BBCode into HTML
  my $html = $bbr->parse($bbcode);
  # convert generated HTML back to BBCode
  my $bbcode = $bbr->reverse($html);

=head1 DESCRIPTION

C<HTML::BBReverse> is a pure perl module for converting BBCode to HTML and is
able to convert the generated HTML back to BBCode.

=head2 METHODS

The following methods can be used

=head3 new

  my $bbr = HTML::BBReverse->new(
    allowed_tags => [ qw( b i u code url size color img quote list email ) ],
    reverse_for_edit => 1,
    in_paragraph => 0,
  );

C<new> creates a new HTML::BBReverse object using the configuration passed to
it. 

=head4 options

The following options can be passed to C<new>:

=over 4

=item allowed_tags

Specifies which BBCode tags will be parsed, for the current supported tags, see
L<the list of supported tags|/"SUPPORTED TAGS"> below. Defaults to all
supported tags.

=item reverse_for_edit

When set to a positive value, the C<reverse> method will parse C<&>, C<E<gt>> and
C<E<lt>> to their HTML entity equivalent. This option is useful when reversing
HTML to BBCode for editing in a browser, in a normal C<textarea>. When set to
zero, the C<reverse> method should just ignore these characters.

=item in_paragraph

Specifies wether the generated HTML is used between HTML paragraphs (C<E<lt>pE<gt>>
and C<E<lt>/pE<gt>>), and adds a C<E<lt>/pE<gt>> in front of and a C<E<lt>pE<gt>> after every
list. (XHTML 1.0 strict document types do not allow lists in paragraphs)

=back

=head3 parse

Parses BBCode text supplied as a single scalar string and returns the HTML as a
single scalar string.

=head3 reverse

Parses HTML generated from C<parse> supplied as a single scalar string and
returns BBCode as a single scalar string.
B<Note that this method can only be used to reverse HTML generated by the
C<parse> method of this module, it won't be able to parse just any HTML to
BBCode>

=head2 SUPPORTED TAGS

The following BBCode tags are supported:

  b, i, u, img, url, size, color, quote, list, email

Which will generate the following HTML:

  Input                              Output
  
  [b]bold[/b]                        <b>bold</b>
  [i]italic[/i]                      <i>italic</i>
  [u]underlined[/u]                  <span style="text-decoration: underline">underlined</span><!--1-->
  [img]pic.png[/img]                 <img src="pic.png" alt="" />
  [img=pic.png]desc[/img]            <img src="pic.png" alt="desc" title="desc" />
  [url=/file]desc[/url]              <a href="/file">desc</a>
  [size=20]text[/size]               <span style="font-size: 20px">text</span><!--2-->
  [color=red]text[/color]            <span style="color: red">text</span><!--3-->
  [quote]some quote[/quote]          <span class="bbcode_quote_header">Quote: <span class="bbcode_quote_body">some quote</span></span>
  [quote=author]some quote[/quote]   <span class="bbcode_quote_header">author wrote: <span class="bbcode_quote_body">some quote</span></span>
  [code]some code[/code]             <span class="bbcode_code_header">Code: <span class="bbcode_code_body">some code</span> </span>
  [email]some@mail.addr[/email]      <a href="mailto:some@mail.addr">some@mail.addr</a>

Note the C<E<lt>!--x--E<gt>> after some HTML close tags, these are used by the
C<reverse> method, to see the difference between HTML close tags which are the
same, while the BBCode equivalent is not the same.


=head1 SEE ALSO

http://www.phpbb.com/phpBB/faq.php?mode=bbcode

=head1 KNOWN BUGS

This module does contain a few bugs, if you find another bug not listed here,
please contact the author.

=head2 Multiple lists on one line

When there are two [list]-tags on one line, the first tag will be completely
ignored, for example:

  [list][*]item 1[*]item 2[/list][list]
  [*]another item[/list]

Will be parsed to:

  [list][*]item 1[*]item 2[/list]<ul>
  <li>another item</li></ul>

Note that the generated HTML will still be reversed to the original BBCode.
The best solution to this bug is just to add a linebreak after every list tag, 
this bug will probably be fixed in future versions of HTML::BBReverse.

=head2 Lists formatting

The space between a code start tag (C<[code]>) and the first item (C<[*]>)
will be completely ignored, and replaced with a linebreak.
B<This bug will probably not be fixed.>

=head1 AUTHOR

Y. Heling, E<lt>yorhel@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Y. Heling

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
