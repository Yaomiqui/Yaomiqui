#!/usr/bin/perl
use strict;
use FindBin qw($RealBin);
use lib $RealBin;
my @chars = ('a'..'z','A'..'Z',0..9);
print $chars[int(rand(@chars))] for 1..$ARGV[0] || 30;
exit;
