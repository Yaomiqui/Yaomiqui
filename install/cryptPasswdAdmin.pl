#!/usr/bin/perl
use strict;
use Crypt::Babel;
use Tie::File;

my $o = tie my @array, 'Tie::File', '/var/www/yaomiqui/certs/yaomiquikey.enc' or die "I can't open yaomiqui key enc\n";
my $encKey = $array[0];
untie @array;

my $crypt = new Crypt::Babel;

my $string = $ARGV[0] || die "I need the passwd as arg\n";
my $enc = $crypt->encode($string, $encKey);
# my $dec = $crypt->decode($enc, $encKey);
# print "dec: $dec\n";
print $enc;
