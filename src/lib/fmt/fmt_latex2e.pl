#
#  fmt_latex2e.pl
#
# ------------------------------------------------------------------
#  LaTeX-specific driver stuff
#
#  Copyright © 1994-1996, Matt Welsh
#  Copyright © 1996, Cees de Groot
#  Copyright © 1999-2002, Taketoshi Sano
#  Copyright © 1999, Kazuyuki Okamoto (euc-jp support in sgml2txt, sgml2html, and sgml2latex)
#  Copyright © 1999, Tetsu ONO (euc-jp support in sgml2txt, sgml2html, and sgml2latex)
#  Copyright © 2000, Juan Jose Amor (Support for PDF files)
#  Copyright © 2006-2009, Agustin Martin
# ------------------------------------------------------------------

package LinuxDocTools::fmt_latex2e;
use strict;

use LinuxDocTools::CharEnts;
use LinuxDocTools::Vars;
use LinuxDocTools::Lang;

use File::Copy;

my $latex2e = {};
$latex2e->{NAME} = "latex2e";
$latex2e->{HELP} = "
  Note that this output format requires LaTeX 2e.

";
$latex2e->{OPTIONS} = [
		       { option => "output",
			 type => "l",
			 'values' => [ "dvi", "tex", "ps", "pdf" ],
			 short => "o" },
		       { option => "bibtex",
			 type => "f",
			 short => "b" },
		       { option => "makeindex",
			 type => "f",
			 short => "m" },
		       { option => "pagenumber",
			 type => "i",
			 short => "n" },
		       { option => "quick",
			 type => "f",
			 short => "q" },
		       { option => "dvips",
			 type => "l",
			 'values' => [ "dvips", "dvi2ps", "jdvi2kps" ],
			 short => "s" },
		       { option => "latex",
			 type => "l",
			 'values' => [ "latex", "hlatexp", "platex", "jlatex" ],
			 short => "x" }
		       ];
$latex2e->{output}         = "tex";
$latex2e->{pagenumber}     = 1;
$latex2e->{quick}          = 0;
$latex2e->{bibtex}         = 0;
$latex2e->{makeindex}      = 0;
$latex2e->{latex}          = "unknown";
$latex2e->{dvips}          = "unknown";
$Formats{$latex2e->{NAME}} = $latex2e;

# ------------------------------------------------------------------
$latex2e->{preNSGMLS} = sub {
# ------------------------------------------------------------------
  $global->{NsgmlsOpts} .= " -ifmttex ";

  #  for Japanese jlatex users
  if ($global->{language} eq "ja" && $latex2e->{latex} eq "unknown") {
    $latex2e->{latex} = "jlatex";
    $latex2e->{dvips} = "dvi2ps";
    # for Japanese platex users
    #	$latex2e->{latex} = "platex";
    #	$latex2e->{dvips} = "dvips";
  }

  # for Korean users
  if ($global->{language} eq "ko" && $latex2e->{latex} eq "unknown") {
    $latex2e->{latex} = "hlatexp";
  }

  # default process command
  $latex2e->{latex} = "latex" if ($latex2e->{latex} eq "unknown");
  $latex2e->{dvips} = "dvips" if ($latex2e->{dvips} eq "unknown");

  $global->{NsgmlsPrePipe} = "cat $global->{file} | sed 's/_/\\&lowbar;/g' ";
};

# extra `\\' here for standard `nsgmls' output
my %latex2e_escapes;
$latex2e_escapes{'#'} = '\\\\#';
$latex2e_escapes{'$'} = '\\\\$';
$latex2e_escapes{'%'} = '\\\\%';
$latex2e_escapes{'&'} = '\\\\&';
$latex2e_escapes{'~'} = '\\\\~{}';
$latex2e_escapes{'_'} = '\\\\_';
$latex2e_escapes{'^'} = '\\\\^{}';
$latex2e_escapes{'\\'} = '\\verb+\\+';
$latex2e_escapes{'{'} = '\\\\{';
$latex2e_escapes{'}'} = '\\\\}';
$latex2e_escapes{'>'} = '{$>$}';
$latex2e_escapes{'<'} = '{$<$}';	# wouldn't happen, but that's what'd be
$latex2e_escapes{'|'} = '{$|$}';

my $in_verb;
my $remove_comment; # added 2000 Jan 25 by t.sano

# passed to `parse_data' below in latex2e_preASP
my $latex2e_escape = sub {
  my ($data) = @_;

  if (!$in_verb) {
    # escape special characters
    $data =~ s|([\#\$%&~_^\\{}<>\|])|$latex2e_escapes{$1}|ge;
  }

  return ($data);
};

# ------------------------------------------------------------------
$latex2e->{preASP} = sub {
# ------------------------------------------------------------------
#  Translate character entities and escape LaTeX special chars.
# ------------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;

  # Note: `sdata_dirs' made an anonymous array to have a single argument
  my $tex_char_maps = load_char_maps ('.2tex', [ Text::EntityMap::sdata_dirs() ]);

  # ASCII char maps are used in the verbatim environment because TeX
  # ignores all the escapes
  my $ascii_char_maps = load_char_maps ('.2ab', [ Text::EntityMap::sdata_dirs() ]);
  $ascii_char_maps = load_char_maps ('.2l1b', [ Text::EntityMap::sdata_dirs() ]) if $global->{charset} eq "latin";

  my $char_maps = $tex_char_maps;

  # used in `latex2e_escape' anonymous sub to switch between escaping
  # characters from SGML source or not, depending on whether we're in
  # a VERB or CODE environment or not
  $in_verb = 0;

  # switch to remove empty line from TeX source or not, depending
  # on whether we're in a HEADING or ABSTRACT environment or not
  $remove_comment = 0;

  while (<$INFILE>) {
    if ( s/^-// ){
      chomp;
      s/^\\n/ /;          # Remove spurious leading \n (not real \\n)
      $_ = parse_data ($_, $char_maps, $latex2e_escape);
      if ($remove_comment){
	s/(\s+\\n)+//;
      }
      print $OUTFILE "-" . $_ . "\n";
    } elsif (/^A/) {
      /^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	|| die "bad attribute data: $_\n";
      my ($name,$type,$value) = ($1,$2,$4);
      if ($type eq "CDATA") {
	# CDATA attributes get translated also
	if ($name eq "URL" or $name eq "ID" or $name eq "CA") {
	  # URL for url.sty is a kind of verbatim...
	  # CA is used in "tabular" element.
	  # Thanks to Evgeny Stambulchik, he posted this fix
	  # on sgml-tools list. 2000 May 17, t.sano
	  my $old_verb = $in_verb;
	  $in_verb = 1;
	  $value = parse_data ($value, $ascii_char_maps,
			       $latex2e_escape);
	  $in_verb = $old_verb;
	} else {
	  $value = parse_data ($value, $char_maps, $latex2e_escape);
	}
      }
      print $OUTFILE "A$name $type $value\n";
    } elsif (/^\((VERB|CODE)/) {
      print $OUTFILE $_;
      # going into VERB/CODE section
      $in_verb = 1;
      $char_maps = $ascii_char_maps;
    } elsif (/^\)(VERB|CODE)/) {
      print $OUTFILE $_;
      # leaving VERB/CODE section
      $in_verb = 0;
      $char_maps = $tex_char_maps;
    } elsif (/^\((HEADING|ABSTRACT)/) {
      print $OUTFILE $_;
      # empty lines (comment in sgml source) do harm
      # in HEADING or ABSTRACT
      $remove_comment = 1;
    } elsif (/^\)(HEADING|ABSTRACT)/) {
      print $OUTFILE $_;
      # leaving HEADING or ABSTRACT section
      $remove_comment = 0;
    } else {
      print $OUTFILE $_;
    }
  }
};

# ------------------------------------------------------------------
sub latex2e_defnam($) {
# ------------------------------------------------------------------
# return the string of the name of the macro for urldef
# ------------------------------------------------------------------
  my ($num) = @_;

  if ($num > 26*26*26) {
    die "Too many URLs!\n";
  }

  my $anum = ord("a");

  my $defnam = chr ($anum + ($num / 26 / 26)) .
    chr ($anum + ($num / 26 % 26)) .
    chr ($anum + ($num % 26));

  return ($defnam);
};

# ------------------------------------------------------------------
$latex2e->{postASP} = sub
# ------------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# ------------------------------------------------------------------
{
  my $INFILE       = shift;
  my $OUTFILE;
  my $SGMLFILE;
  my $filename     = $global->{filename};
  my $tmplatexdir  = $global->{tmpbase} . "-latex-" . $$ . ".dir";
  my $tmplatexnam  = $tmplatexdir . "/" . $filename;
  my $msgheader    = "fmt_latex2e::postASP";
  my @epsfiles     = ();
  my @texlines     = ();
  my @urldefines   = ();
  my @urlnames     = ();
  my $urlnum       = 0;
  my $tmpepsf;
  my $saved_umask  = umask;
  $ENV{TEXINPUTS} .= ":$main::DataDir";

  umask 0077;
  mkdir ($tmplatexdir, 0700)
    or die "Could not create \"$tmplatexdir\" directory.\n";

  # check epsfile is specified in source file
  {
    my $epsf;
    open $SGMLFILE, "<$filename.sgml";
    while (<$SGMLFILE>){
      # for epsfile
      if ( s/^\s*<eps\s+file=(.*)>/$1/ ) {
	s/\s+angle=.*//;
	s/\s+height=.*//;
	s/\"//g;
	$epsf = $_;
	chop ( $epsf );
	push @epsfiles, $epsf;
      }
      if ($latex2e->{output} eq "pdf") {
	if ( s/^\s*<img\s+src=(.*)>/$1/ ) {
	  s/\"//g;
	  $epsf = $_;
	  chop ( $epsf );
	  push @epsfiles, $epsf;
	}
      }
    }
    close $SGMLFILE;
  }

  # Parse TeX file and check nameurl specified in source file
  {
    my $urlid;
    my $urlnam;
    my $urldef;

    while (<$INFILE>){
      # Read TeX file
      push @texlines, $_;
      # and check for nameurl
      if ( /\\nameurl/ ){
	($urlid, $urlnam) = ($_ =~ /\\nameurl{(.*)}{(.*)}/);
	print $urlnum . ": " . $urlid . "\n" if ( $global->{debug} );

	$urldef = latex2e_defnam($urlnum) . "url";
	s/\\nameurl{.*}{.*}/{\\em $urlnam} {\\tt \\$urldef}/;
	push @urlnames, $_;
	push @urldefines, "\\urldef{\\$urldef} \\url{$urlid}\n";
	$urlnum++;
      }
    }
    close $INFILE;
  }

  # --------------------------------------------------------------------
  #  Set the correct \documentclass and packages options.
  # --------------------------------------------------------------------
  {
    my $langlit = ISO2English ($global->{language});
    $langlit = ($langlit eq 'english') ? "" : "$langlit";
    my $hlatexopt = "";
    $global->{charset} = "nippon" if ($global->{language} eq "ja");
    $global->{charset} = "euc-kr" if ($global->{language} eq "ko");

    # Getting document class prefix
    my $classprefix = "";
    if ($global->{charset} eq "nippon") {
      if ($latex2e->{latex} eq "platex") {
	$classprefix = "j";
      } elsif ($latex2e->{latex} eq "jlatex") {
	$classprefix = "j-";
      }
    }

    # Getting class options
    my $classoptions = $global->{papersize} . 'paper';

    # Getting babel options
    my $babeloptions = $langlit || "english";
    if ( ($global->{charset} eq "nippon")
	 ||
	 ($global->{charset} eq "euc-kr")) {
      $babeloptions = '';
    }

    open ($OUTFILE, "> $tmplatexnam.tex")
      or die "fmt_latex2e::postASP: Could not open \"$tmplatexnam.tex\" for write.\n";

    # Loop over the TeX file
    my $inpreamble = 1;
    while (defined($texlines[0])) {
      $_ = shift @texlines;

      if ( $inpreamble ) {
	if (/%end-preamble/) {
	  $inpreamble = '';

	  if ($latex2e->{pagenumber}) {
	    $_ = $_ . '\setcounter{page}{' .
	      $latex2e->{pagenumber} .
	      "}\n";
	  } else {
	    $_ = $_ . "\\pagestyle{empty}\n";
	  }

	  # Now include the explicitly added stuff
	  $_ = $_ . $global->{pass} . "\n" if ($global->{pass});

	  print $OUTFILE $_;

	  # Add to preamble url definitions for \urldef
	  if ($urlnum && $latex2e->{output} ne "pdf") {
	    foreach my $thisurl ( @urldefines ) {
	      print $OUTFILE $thisurl;
	    }
	  }
	} else {   # -- Not in last line of linuxdoc-tools added preamble
	  # Set correct class name and options in the header
	  if (/^\\documentclass\[\@CLASSOPTIONS\@\]/) {
	    s/\@(ARTICLE|REPORT|BOOK)\@/$classprefix . lc($1)/e;
	    s/\@CLASSOPTIONS\@/$classoptions/;
	    $_ = $_ . "\\makeindex\n" if ($latex2e->{makeindex});
	  }
	  # Set correct DTD name
	  elsif (/^\\usepackage{\@LINUXDOC_DTD\@-sgml}/) {
	    my $dtd = $global->{"dtd"};
	    s/\@LINUXDOC_DTD\@/$dtd/;
	  }
	  # Set correct babel options
	  elsif (/^\\usepackage\[\@BABELOPTIONS\@\]{babel}/) {
	    if ( $babeloptions ) {
	      s/\@BABELOPTIONS\@/$babeloptions/;
	    } else {
	      s/^/%%/;
	    }
	  }
	  elsif (/^\\usepackage.epsfig/ && ($global->{charset} eq "euc-kr")) {
	    $hlatexopt = "[noautojosa]" if ($latex2e->{latex} eq "hlatexp");
	    $_ = $_ . "\\usepackage" . "$hlatexopt" . "{hangul}\n";
	  }
	  # Deal with input encoding
	  elsif ( /\\usepackage\[\@CHARSET\@\]\{inputenc\}/ ) {
	    if ( $global->{charset} eq "latin" ) {
	      s/\@CHARSET\@/latin1/;
	    } else {
	      s/^/%%/;
	    }
	  }
	  # nippon or euc-kr do not use T1 encoding
	  elsif ( (/\\usepackage\[T1\]\{fontenc\}/)    &&
		  ( ($global->{charset} eq "nippon")   ||
		    ($global->{charset} eq "euc-kr"))) {
	    s/^/%%/;
	  }
	  print $OUTFILE $_;
	}
      } else {   # -- Not in linuxdocsgml added preamble
	#
	if (/\\nameurl/ && $latex2e->{output} ne "pdf") {
	  $_ = shift @urlnames;
	}
	print $OUTFILE $_;
      }
    }
  }
  close $OUTFILE;

  #  LaTeX, dvips, and assorted cleanups.
  if ($latex2e->{output} eq "tex") {
    # comment out, because this backup action is not documented yet.
    #
    #      if ( -e "$filename.tex" ) {
    #          rename ("$filename.tex", "$filename.tex.back");
    #      }

    umask $saved_umask;
    copy ("$tmplatexnam.tex", "$filename.tex");
    if ( ! $global->{debug} ) {
      unlink ("$tmplatexnam.tex");
      rmdir ($tmplatexdir) || return -1;
    }

    return 0;
  }

  # Run LaTeX in nonstop mode so it won't prompt & hang on errors.
  # Suppress the output of LaTeX on all but the last pass, after
  # references have been resolved.  This avoids large numbers of
  # spurious warnings.
  my $current_dir;
  chop ($current_dir = `pwd`);
  print $current_dir . "\n" if ( $global->{debug} );

  # copy epsfiles specified in tex file
  for my $epsf ( @epsfiles ) {
    $tmpepsf = $tmplatexdir . "/" . $epsf;
    print $epsf . " " . $tmpepsf . "\n" if ( $global->{debug} );
    copy ("$epsf", "$tmpepsf") or die "can not copy graphics\n";
  }

  # go to the temporary directory
  chdir ($tmplatexdir);

  my ($latexcommand) = "$latex2e->{latex} '\\nonstopmode\\input{$filename.tex}'";

  # We run pdflatex instead of latex if user selected pdf output
  if ($latex2e->{output} eq "pdf") {
    $latexcommand = "pdflatex '\\nonstopmode\\input{$filename.tex}'";
  }

  # run hlatex if hlatexp is used
  # for pdf: how about status?(for hlatex and hlatexp)
  if ($latex2e->{latex} eq "hlatexp") {
    #$latex2e->{output} = "ps" if ($latex2e->{output} eq "pdf");
    $latexcommand = "hlatex '\\nonstopmode\\input{$filename.tex}'";
  }

  # We use jlatex for Japanese encoded (euc-jp) characters.
  # pdf support for Japanese are not yet. use ps for the time being.
  if ($global->{charset} eq "nippon") {
    $latex2e->{output} = "ps" if ($latex2e->{output} eq "pdf");
    $latexcommand = "$latex2e->{latex} '\\nonstopmode\\input{$filename.tex}'";
  }
  my ($suppress) = $latex2e->{quick} ? "" : ' >/dev/null';

  system ($latexcommand . $suppress) == 0
    or die "$msgheader: LaTeX first run problem. Aborting ...\n";

  if ( $latex2e->{bibtex} ) {
    system ( "bibtex $filename" ) == 0
      or print STDERR "$msgheader: Problems when running BibTeX. Ignoring ...\n";
  }

  unless ( $latex2e->{quick} ){
    system ($latexcommand . ' >/dev/null') == 0
      or die "$msgheader: LaTeX second run problem. Aborting ...\n";
    system ( $latexcommand ) == 0
      or die "$msgheader: LaTeX third run problem. Aborting ...\n";
  }

  if ( ! $global->{debug} ) {
    my @suffixes = qw(log blg aux toc lof lot dlog bbl out);
    for my $suf (@suffixes) {
      unlink "$tmplatexnam.$suf";
    }
  }

  # go back to the working directory
  chdir ($current_dir);

  # output dvi file
  if ($latex2e->{output} eq "dvi") {
    # comment out, because this backup action is not documented yet.
    #
    #      if ( -e "$filename.dvi" )
    #        {
    #          rename ("$filename.dvi", "$filename.dvi.back");
    #        }
    umask $saved_umask;
    copy ("$tmplatexnam.dvi", "$filename.dvi");
    if ( $global->{debug} ) {
      print "Temporary files are in $tmplatexdir\n";
      print "Please check there and remove them manually.\n";
    } else {
      unlink ("$tmplatexnam.tex", "$tmplatexnam.dvi");
      for my $epsf ( @epsfiles ) {
	$tmpepsf = $tmplatexdir . "/" . $epsf;
	print $tmpepsf . "\n" if ( $global->{debug} );
	unlink ("$tmpepsf");
      }
      rmdir ($tmplatexdir) || return -1;
    }
    return 0;
  }

  # output pdf file
  if ($latex2e->{output} eq "pdf") {
    # comment out, because this backup action is not documented yet.
    #
    #      if ( -e "$filename.pdf" )
    #         {
    #          rename ("$filename.pdf", "$filename.pdf.back");
    #        }
    umask $saved_umask;
    copy ("$tmplatexnam.pdf", "$filename.pdf");
    if ( $global->{debug} ) {
      print "Temporary files are in $tmplatexdir\n";
      print "Please check there and remove them manually.\n";
    } else {
      unlink ("$tmplatexnam.tex", "$tmplatexnam.pdf");
      for my $epsf ( @epsfiles ) {
	$tmpepsf = $tmplatexdir . "/" . $epsf;
	print $tmpepsf . "\n" if ( $global->{debug} );
	unlink ("$tmpepsf");
      }
      rmdir ($tmplatexdir) || return -1;
    }
    return 0;
  }

  # convert dvi into ps using dvips command
  chdir ($tmplatexdir);
  if ($latex2e->{dvips} eq "dvi2ps") {
    `dvi2ps -q -o $global->{papersize} -c $tmplatexnam.ps $filename.dvi`;
  } elsif ($latex2e->{dvips} eq "jdvi2kps") {
    `jdvi2kps -q -pa $global->{papersize} -o $tmplatexnam.ps $filename.dvi`;
  } else {
    `dvips -R -q -t $global->{papersize} -o $tmplatexnam.ps $filename.dvi`;
  }

  chdir ($current_dir);

  # comment out, because this backup action is not documented yet.
  #
  #   if ( -e "$filename.ps" )
  #    {
  #      rename ("$filename.ps", "$filename.ps.back");
  #    }
  umask $saved_umask;
  copy ("$tmplatexnam.ps", "$filename.ps");
  unlink ("$tmplatexnam.ps");
  if ( $global->{debug} ) {
    print "Temporary files are in $tmplatexdir\n";
    print "Please check there and remove them manually.\n";
  } else {
    unlink ("$tmplatexnam.tex", "$tmplatexnam.dvi", "$tmplatexnam.ps");
    for my $epsf ( @epsfiles ) {
      $tmpepsf = $tmplatexdir . "/" . $epsf;
      print $tmpepsf . "\n" if ( $global->{debug} );
      unlink ("$tmpepsf");
    }
    rmdir ($tmplatexdir) || return -1;
  }
  return 0;

};

1;
