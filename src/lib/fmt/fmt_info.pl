#
#  fmt_info.pl
#
# ------------------------------------------------------------------
#  GNU Info-specific driver stuff
#
#  Copyright © 1994-1996, Matt Welsh
#  Copyright © 1996, Cees de Groot
#  Copyright © 1999-2000, Taketoshi Sano
#  Copyright © 2008-2009 Agustin Martin
# ------------------------------------------------------------------

package LinuxDocTools::fmt_info;
use strict;

use LinuxDocTools::Vars;

use File::Copy;
use Text::EntityMap;
use LinuxDocTools::CharEnts;
use LinuxDocTools::Lang;
use LinuxDocTools::Vars;
use LinuxDocTools::InfoUtils qw{info_process_texi};

my $info = {};
$info->{NAME}           = "info";
$info->{HELP}           = "";
$Formats{$info->{NAME}} = $info;
$info->{OPTIONS}        = [
			   ];

# ------------------------------------------------------------------
$info->{preNSGMLS} = sub {
# ------------------------------------------------------------------
  $global->{NsgmlsOpts} .= " -ifmtinfo ";
  $global->{NsgmlsPrePipe} = "cat  $global->{file}";
};

# ------------------------------------------------------------------
my $info_escape = sub {
# ------------------------------------------------------------------
# Ascii escape sub.  this is called-back by `parse_data' below in
# `info_preASP' to properly escape `\' characters coming from the SGML
# source.
# ------------------------------------------------------------------
  my ($data) = @_;

  #    $data =~ s|"| \"|g;	# Insert zero-width space in front of "
  #    $data =~ s|^\.| .|;	# ditto in front of . at start of line
  #    $data =~ s|\\|\\\\|g;	# Escape backslashes

  return ($data);
};

# ------------------------------------------------------------------
$info->{preASP} = sub {
# ------------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;
  my $suffix     = ( $global->{charset} eq "latin1" ) ? '.2l1texi' : '.2texi';
  my $char_maps  = load_char_maps ($suffix, [ Text::EntityMap::sdata_dirs() ]);
  my $inpreamble = 1;
  my $inheading;

  # Replace some symbols in the file before sgmlsasp is called. This
  # has been done in preNSGMLS, but if the specified sgml file is
  # divided into multiple pieces, the preNSGMLS is not enough.
  while ( <$INFILE> ) {
    s/\@/\@\@/g;
    s/\{/\@\{/g;
    s/\}/\@\}/g;
#      s/-\((.*)\)/-\'\($1\)\'/;
    s/-\((.*)\)/-\[$1\]/;
    s/\\\|urlnam\\\|/ /g;
    s/\\\|refnam\\\|/ /g;

    if ( s/^-// ) {
      chomp;
      s/([^\\])\\n/$1 /g if $inheading;      # Remove spurious \n in headings
      s/(\\n|^)\\011/$1/g if $inpreamble;    # Remove leading tabs in abstract.
      print $OUTFILE "-" .
	parse_data ($_, $char_maps, $info_escape) . "\n";
    } elsif (/^A/) {
      /^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	|| die "bad attribute data: $_\n";
      my ($name,$type,$value) = ($1,$2,$4);
      if ($type eq "CDATA") {
	# CDATA attributes get translated also
	$value = parse_data ($value, $char_maps, $info_escape);
      }
      print $OUTFILE "A$name $type $value\n";
    } else {
      if (/^\(HEADING/){
        $inheading = 1;
	$inpreamble = '';          # No longer in preamble if found a HEADING
      } elsif (/^\)HEADING/){
        $inheading = '';
      }
      #  Default action if not skipped over by previous conditions: copy in to out.
      print $OUTFILE $_;
    }
  }

  return 0;
};

# ------------------------------------------------------------------
$info->{postASP} = sub {
# ------------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# ------------------------------------------------------------------
  my $INFILE    = shift;
  my $OUTFILE;
  my $msgheader = "fmt_info::postASP";
  my $fileinfo  = "info file generated from $global->{file} by means of linuxdoc-tools";

  my $rawtexi   = "$global->{tmpbase}.1.texi0";
  my $texifile  = "$global->{tmpbase}.2.texi";
  my $infofile  = "$global->{filename}.info";
  my $infofile0 = "$global->{tmpbase}.info";

  open ($OUTFILE, "> $rawtexi")
    or die "fmt_info::postASP: Could not open \"$rawtexi\" for writing. Aborting ...\n";
  copy ($INFILE, $OUTFILE);
  close $OUTFILE;

  # Preprocess the raw texinfo file
  info_process_texi($rawtexi,$texifile,$infofile);

  system ("makeinfo $texifile -o $infofile") == 0
    or die "$msgheader: Failed to run makeinfo. Aborting ...\n";

  move $infofile, $infofile0;

  my $TMPINFO;
  my $infotext;
  open ( $TMPINFO, "< $infofile0")
    or die "Could not open $infofile0 for read. Aborting ... \n";
  {
    local $/ = undef;
    $infotext = <$TMPINFO>;
  }
  close $TMPINFO;

  # Change to something useful origin filename given by makeinfo
  $infotext =~ s/$texifile/$fileinfo/;

  # Remove not needed line in resulting info file. Only first match.
  $infotext =~ s/\\input texinfo//;

  open ($OUTFILE, "> $infofile")
    or die "Could not open $infofile for write. Aborting ... \n";
  print $OUTFILE $infotext;
  close $OUTFILE;

  return 0;
};

1;
