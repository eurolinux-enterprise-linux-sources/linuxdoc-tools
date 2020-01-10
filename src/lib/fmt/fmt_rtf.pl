#
#  fmt_rtf.pl
#
# -----------------------------------------------------------
#  RTF-specific driver stuff
#
#  Copyright © 1994-1996, Matt Welsh
#  Copyright © 1996, Cees de Groot
#  Copyright © 1998, Sven Rudolph
#  Copyright © 1999-2001, Taketoshi Sano
#  Copyright © 2008, Agustin Martin
# -----------------------------------------------------------

package LinuxDocTools::fmt_rtf;
use strict;

use LinuxDocTools::Vars;

use File::Copy;

my $rtf = {};
$rtf->{NAME} = "rtf";
$rtf->{HELP} = "";
$rtf->{OPTIONS} = [
		   { option => "twosplit", type => "f", short => "2" }
		   ];
$rtf->{twosplit}  = 0;

$Formats{$rtf->{NAME}} = $rtf;

# -------------------------------------------------------------
$rtf->{preASP} = sub {
# -------------------------------------------------------------
# RTF does not treat newline as whitespace, so we need to turn
# "\n" into " \n". Without the extra space, two words separated
# only by a newline will get jammed together in the RTF output.
# -------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;

  while (<$INFILE>){
    s/([^\\])\\n/$1 \\n/g;
    print $OUTFILE $_;
  }
};

# -------------------------------------------------------------
$rtf->{postASP} = sub {
# -------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# -------------------------------------------------------------
  my $INFILE  = shift;
  my $PIPE;
  my $rtf2rtf = "$main::AuxBinDir/rtf2rtf";
  my $split   = ($rtf->{twosplit}) ? "-2" : "";
  my $prefile = "$global->{filename}";
  my $rtffile = "$global->{filename}.rtf";

  open ($PIPE,"| $rtf2rtf $split $prefile > $rtffile")
    or die "fmt_rtf.pl::postASP: Could not open pipe to $rtf2rtf. Aborting ...\n";
  copy ($INFILE, $PIPE);
  close $PIPE;

  return 0;
};

1;
