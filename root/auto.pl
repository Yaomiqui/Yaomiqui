#!/usr/bin/perl
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# Launcher and parallel processing control for tickets in Yaomiqui
# 
# Yaomiqui and its logo are registered trademark by Hugo Maza Moreno
# Copyright (C) 2019
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################
use strict;
# use warnings;
use Parallel::ForkManager;
use FindBin qw($RealBin);
use lib $RealBin;

our $dbh;
our %VENV = get_vars();
our $MAX_PROCESSES = $VENV{'PROC_MAX_PARALLEL'};
$VENV{'CRITICAL_PROC'} ++;

my $pids = getPid();

if ( $pids < $VENV{'CRITICAL_PROC'} ) {
	connected();
	my $sth = $dbh->prepare("SELECT numberTicket FROM ticket WHERE idAutoBotCatched IS NULL");
	$sth->execute();
	my $AB = $sth->fetchall_arrayref;
	$sth->finish;
	
	if ( $AB ) {
		my $pm = new Parallel::ForkManager($MAX_PROCESSES);
		
		for my $i ( 0 .. $#{$AB} ) {
			my $pid = $pm->start and next; 
			
			eval { system ("$RealBin/yaomiqui.pl $AB->[$i][0]") };
			
			$pm->finish;
		}
	}
}

exit;

sub getPid {
	my $pid = `ps -eo pid,command | grep 'auto.pl' | grep -v grep | grep -v $$ | wc -l`;
	$pid =~ s/\n//g;
	
	return $pid;
}

sub connected {
	use DBI;
	$dbh = DBI->connect("DBI:mysql:$VENV{'DB'}:$VENV{'DBHOST'}", $VENV{'DBUSER'}, $VENV{'DBPASSWD'}) or print "Error... $DBI::errstr mysql_error()<br>";
}

sub get_vars {
	my %VARS;
	open my $file, "<$RealBin/yaomiqui.conf";
	while ( <$file> ) {
		$_ =~ s/\n$//;
		$_ =~ s/^\s*//;
		$_ =~ s/\s*$//;
		unless ( $_ =~ /\#/ ) {
			my ($key, $val) = split(/\s*\=\s*/, $_);
			$VARS{$key} = $val if $val;
		}
	}
	close $file;
	return %VARS;
}
