#!/usr/bin/perl
use strict;
use Babel;
use Tie::File;

my $o = tie my @array, 'Tie::File', '/etc/miquiloni/miquilonikey.enc' or die "I can't open miquiloni key enc\n";
my $encKey = $array[0];
untie @array;

my $crypt = new Babel;

my $string = $ARGV[0] || "admin";
my $enc = $crypt->encode($string, $encKey);
my $dec = $crypt->decode($enc, $encKey);

print "The source string is  $string\n";
print "The encrypted string  $enc\n";
print "The original string   $dec\n";
print "\n";

my $decode = $crypt->decode('!508*6-1*5+7^60.950*558+', $encKey);
print "\nLa diferencia:   $decode\n";
