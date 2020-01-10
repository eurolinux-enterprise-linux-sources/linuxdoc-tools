# We need to add an extra whitespace after each line, because
# otherwise it will be swallowed on continuation lines.
# When line is ended by a backslash e.g. (<em/kk/) we add a non
# breaking whitespace (asc(160), \112, \xA0) because othewise
# lines will be joined at the wrong place. We will try to
# filter this in postASP

while ( <> ){
  chomp;
  if ( m/\/$/ ){
    print $_ . "&nbsp;\n";
  } else {
    print "$_ \n";
  }
}

