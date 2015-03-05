#!/usr/local/bin/perl
use FileHandle;
use IPC::Open2;

###
# OIG TLE retrieval program
# DJG - 6/14/98
#
# Uses a file called "one" which has sat numbers to get
#
# Places all output in a single file called "five.tle".
#
###

### Configure:
##$login = "emurphy";
##$passwd = "bdr529";

$login = "mromelfanger";
$passwd = "fusejhu";
$output_filename = "five.tle";
$log_filename = "get_tle.logfile";

### (end of configure section)

# system("fixlist one tempone");
# chop($satstoget = `cat tempone`);
# system("rm -f tempone");

$satstoget = "25791";

# The "output" file collects debugging copies of everything that comes back.
open(OUT,">$log_filename") || die "Could not open output file";

# The following logs in to OIG and gets the first "continue" code

$host = "oig1.gsfc.nasa.gov";
#$url = "scripts/foxweb.dll/loginok\@app01?tdac=&ffv01=$login&ffv02=$passwd";
$url = "scripts/foxweb.exe/loginok\@app01?tdac=&ffv01=$login&ffv02=$passwd";

open2 (\*Reader, \*Writer, "telnet $host 80") || die "Error opening connection";
Writer->autoflush();

print Reader "telnet $host 80\n";
print Writer "GET \/$url\n";
while (<Reader>) {
  print OUT "$_";  # copy each login screen line to the output file
  if (/tdac=(\w+)\"/) {
    $continuecode = $1;  # This code is the "continue" code
  }
}
close(Reader);
close(Writer);

# $continuecode contains the very first "continue" code after login.

print OUT "*** \n Starting User's Home Page output page \n***\n\n";

# This url accesses the next screen (user home page)
#$url = "scripts/foxweb.dll/favorhome\@app01?tdac=" . $continuecode;
$url = "scripts/foxweb.exe/favorhome\@app01?tdac=" . $continuecode;
# print $url; # debug print

open2 (\*Reader, \*Writer, "telnet $host 80") || die "Error opening connection";
Writer->autoflush();

print Reader "telnet $host 80\n";
print Writer "GET \/$url\n";

while (<Reader>) {
  print OUT "$_";      # copy each line to the output file

  if(/tdac=(\w+)\"/) {

#   Look for the "tle ad hoc query" code and save it
    chop($word = "$_");
    if ($word =~ /ftleadhoc.+tdac=(\w+)\"/) {
      $tlequerycode = "$1";
    }
  }
}
# close(HOMEPAGE);
# This access is to the "TLE ad hoc query" web page.
#$url = "scripts/foxweb.dll/ftleadhoc\@app01?tdac=" . $tlequerycode;
$url = "scripts/foxweb.exe/ftleadhoc\@app01?tdac=" . $tlequerycode;

open2 (\*Reader, \*Writer, "telnet $host 80") || die "Error opening connection";
Writer->autoflush();

print Reader "telnet $host 80\n";
print Writer "GET \/$url\n";

while (<Reader>) {
  print OUT "$_";  # copy each login screen line to the output file

  # Look for the TLE "submit" code
  chop($word = "$_");
  if ($word =~ /tdac\" VALUE=\"(\w+)\"/) {
    $gotcode2 = "$1";
  }
}
close(Reader);
close(Writer);

# Compose the TLE query and submit it
#$url = "scripts/foxweb.dll/ftleadhoc\@app01?tdac=" . $gotcode2;
$url = "scripts/foxweb.exe/ftleadhoc\@app01?tdac=" . $gotcode2;
$url .= "&ffv01=" . $satstoget . "&ffv02=standard&ffv03=catno&ffv04=five";

# print "$url\n";  # debug print

# Read the reply and copy the relevant lines to output_filename

$copy = "no";
open(TLEOUT,">$output_filename") || die "Error opening $output_filename";

open2 (\*Reader, \*Writer, "telnet $host 80") || die "Error opening connection";
Writer->autoflush();

print Reader "telnet $host 80\n";
print Writer "GET \/$url\n";

while (<Reader>) {
  if ($_ =~ /<P>/) {  # End copy operation
    print "$_";       # write remaining limit to output file
    $copy = "no";
  }
  if ($copy eq "yes") {
    print TLEOUT "$_";   # copy every line to five.tle
    # print "$_";          # and to the terminal
  }
  if (substr($_,0,5) eq "<PRE>") {  # Begin copy operation
    $copy = "yes";
  }
}
close(Reader);
close(Writer);
close(TLEOUT);

# The following will remove all session files. You can comment it
# out for debugging.
# system("rm -f output");

# The following script "fixes up" the output
# system("fix/do.fix.one");

### end of Perl script

