#!/usr/bin/perl
########################################################################
# Yaomiqui is a Web UI for AUTOMATION
# Copyright (C) 2017  Hugo Maza M.
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
use IO::Socket;
use strict;
use JSON;
use FindBin qw($RealBin);

my %VAR = get_vars();
our $dbh;

$|=1;
my $main =IO::Socket::INET->new(
	LocalHost => '127.0.0.1',
	LocalPort => 2050,
	Listen => 10,
	Proto => 'tcp',
	Reuse => 1,
	# Timeout => 2
) or die "Error al iniciar el servidor\n";
$main->autoflush(1);
print "[Aceptando conexiones en el puerto 2050] con PID $$\n";

while (1) {
	while ( my $conect = $main->accept() ) {
		my $pid = fork() and next;
		
		my $data;
		while ( sysread($conect, my $input, 1024) ) {
			chomp $input;
			$input =~ s/\s*$//;
			
			if ( $input =~ /}}$/ ) {
				$data .= $input;
				print $conect "HTTP/1.0 200 OK\r\n";	# syswrite($conect, "HTTP/1.0 200 OK\r\n");
				$conect->close();						# close $conect;
				last;
			}
			
			$data .= $input;
			$conect->flush;
		}
		
		$data =~ /({.+})$/;
		$data = $1;
		
		# my $json = decode_json $data;
		my $json = JSON->new->utf8->decode($data);
		
		if ( $json->{ticket}->{number} ) {
			my $sysdate = sysdate();
			
			connected();
			my $sth = $dbh->prepare("SELECT numberTicket FROM ticket WHERE numberTicket = '$json->{ticket}->{number}'");
			$sth->execute();
			my ($TT) = $sth->fetchrow_array;
			$sth->finish;
			
			unless ( $TT ) {
				my $insert_string = "INSERT INTO ticket (numberTicket, sysidTicket, subject, initialDate, initialState, json) 
				VALUES ('$json->{ticket}->{number}', '$json->{ticket}->{sys_id}', '$json->{ticket}->{subject}', '$sysdate', '$json->{ticket}->{state}', '$data')";
				my $sth = $dbh->prepare("$insert_string");
				$sth->execute();
				$sth->finish;
				$dbh->disconnect if ($dbh);
			}
		}
		
		exit(0);
	}
}

close($main);
exit;

sub connected {
	use DBI;
	$dbh = DBI->connect("DBI:mysql:$VAR{'DB'}:$VAR{'DBHOST'}", $VAR{'DBUSER'}, $VAR{'DBPASSWD'}) or print "Error... $DBI::errstr mysql_error()<br>";
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

sub sysdate {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	$fecha[4] ++;
	@fecha = map { if ($_ < 10) { $_ = "0$_"; }else{ $_ } } @fecha;
						#year	mon		 mday		hour	min		sec
	return my $sysdate = "$fecha[5]-$fecha[4]-$fecha[3] $fecha[2]:$fecha[1]:$fecha[0]";
}
