#!/usr/bin/perl
use strict;
my @chars = ('a'..'z','A'..'Z',0..9);
print $chars[int(rand(@chars))] for 1..$ARGV[0] || 30;
exit;
