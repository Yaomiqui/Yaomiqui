#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use Parallel::ForkManager;

our $dbh;
our %VENV = get_vars();
our $MAX_PROCESSES = $VENV{'PROC_MAX_PARALLEL'};

unless ( getPid() ) {
	# print "Reading tickets...\n";
	connected();
	my $sth = $dbh->prepare("SELECT numberTicket FROM ticket WHERE idAutoBotCatched IS NULL OR finalState IS NULL");
	$sth->execute();
	my $AB = $sth->fetchall_arrayref;
	$sth->finish;
	
	if ( $AB ) {
		my $pm = new Parallel::ForkManager($MAX_PROCESSES);
		
		for my $i ( 0 .. $#{$AB} ) {
			my $pid = $pm->start and next; 
			
			# ## debug
			# print "$RealBin/yaomiqui.pl $AB->[$i][0]\n";
			eval { system ("$RealBin/yaomiqui.pl $AB->[$i][0]") };
			
			$pm->finish;
		}
	}
}

exit;

sub getPid {
	my $pid = `ps -eo pid,command | grep 'auto.pl' | grep -v grep | grep -v $$`;
	$pid =~ s/\n//g;
	
	if ( $pid ) {
		# print "There is process running: $pid\n";
		return 1;
	} else {
		# print "There is no process running...\n";
		return 0;
	}
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
