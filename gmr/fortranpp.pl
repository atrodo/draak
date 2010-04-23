#!/usr/bin/perl

use strict;
use warnings;

my $s = "";

while (<>)
{
  $s .= $_;
}

while ($s =~ s/^[c*].*?\n//xmsi) {};
while ($s =~ s/^(.{5}) . ([^\n]*?) (\d{8})? \n .{5} [^\s0] ([^\n]*?) (\d{8})? \n/$1 $2$4 $3\n/xms) {};
#while ($s =~ s/^(.{6}) ([^\n]*?) (\d{8})? \n .{5} [^0\s] ([^\n]*?) (\d{8})? \n/$1$2$4$3\n/) {};

my $out = "";

foreach my $line (split /\n/, $s)
{
  my ($label, $code, $lineno) = $line =~ m/^(.{6}) ([^\n]*?) (\d{8})? $/xms;
  next unless defined $code;
  $lineno ||= "";

  while ($code =~ m[(\d+)H]xmsg)
  {
    my $count = $1;
    $code =~ m[$count H (.{$count})]x;
    my $newstr = $1;
    $newstr =~ s/'/''/g;
    $code =~ s[$count H .{$count}]['$newstr']x;
  }

  $code =~ m/^/;
  my $newcode = "";

  while ($code =~ m/\G ([^']*) (?:') ([^']*(?:(?:'')[^']*)*) (?:')/xmsgc)
  {
    my $s = $1;
    my $q = $2;
    $s =~ s/\s+//xmsg;
    $newcode .= "$s'$q'";
  }

  {
    $code =~ m/\G(.*)$/;
    my $s = $1;
    $s =~ s/\s+//xmsg;
    $newcode .= $s;
  }

  print "$label$newcode $lineno\n";
}

#print $s;
