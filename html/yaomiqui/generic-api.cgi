#!/usr/bin/perl
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# This is the GENERIC REST API for Yaomiqui 1.0
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
use CGI::Carp qw(fatalsToBrowser);
use JSON;
use Tie::File;
use Data::Dumper;
use FindBin qw($RealBin);
use lib $RealBin;
use strict;
no strict "subs";
use CGI;

our ($dbh, %VAR, $ticketNumber, $encKey, %input, %data);
%VAR = get_vars();
$encKey = getEncKey();

my $q = CGI->new();

if ( $ENV{HTTPS} ne 'on' ) {
	print $q->header('application/json');
	print qq~{"Error":"HTTPS is not being used"}~;
	exit;
}

# print $q->header('text/html');	##
foreach my $pair ( split(/\&/, $ENV{QUERY_STRING} ) ) {
	my ($k, $v) = split(/\=/, $pair);
	$input{$k} = $v;
	# print $k . ' = ' . $input{$k} . "\n";	##
}
my @pares = $q->param;
foreach my $par ( @pares ){
	$data{"$par"} = $q->param("$par");
	# print $par . ' = ' . $data{$par} . "\n";	##
}
# foreach my $key ( keys %ENV ) {	##
	# print $key . '=' . $ENV{$key} . "\n";	##
# }	##
# exit;	##

if ( $ENV{REMOTE_ADDR} ne $ENV{SERVER_ADDR} ) {
	if ( $input{user} and $input{passwd} ) {
		connected();
		my $sth = $dbh->prepare("SELECT password FROM users WHERE username = '$input{user}' AND active = '1'");
		$sth->execute();
		my ($crypt_passwd) = $sth->fetchrow_array;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		use Crypt::Babel;
		my $crypt = new Babel;
		if ( $crypt_passwd ne $crypt->encode($input{passwd}, $encKey) ) {
			print $q->header('application/json');
			print qq~{"Error":"Authentication failed"}~;
			exit;
		}
	} else {
		print $q->header('application/json');
		print qq~{"Error":"Authentication failed"}~;
		exit;
	}
}

use strict;

if ( $ENV{REQUEST_METHOD} eq 'GET' ) {
	print $q->header('application/json');
	
	if ( $ENV{PATH_INFO} =~ /^\/getTicket\// ) {
		$ENV{PATH_INFO} =~ /^\/getTicket\/(.+)/;
		$ticketNumber = $1;
		
		if ( $ticketNumber ) {
			connected();
			my $sth = $dbh->prepare("SELECT t.numberTicket, t.Subject, a.autoBotName, t.initialDate, a.idAutoBot FROM ticket t, autoBot a 
			WHERE numberTicket = '$ticketNumber' AND t.idAutoBotCatched = a.idAutoBot");
			$sth->execute();
			my @TT = $sth->fetchrow_array;
			$sth->finish;
			
			my $var;
			if ( $TT[0] ) {
				$var = qq~{"ticket":{"Number":"$TT[0]","Subject":"$TT[1]","AutoBotName":"$TT[2]","initialDate":"$TT[3]","idAutoBot":"$TT[4]"},~;
				
				$sth = $dbh->prepare("SELECT insertDate, log FROM log WHERE numberTicket = '$ticketNumber' ORDER BY idLog ASC");
				$sth->execute();
				my $LOG = $sth->fetchall_arrayref;
				$sth->finish;
				$dbh->disconnect if ($dbh);
				
				$var .= '"logs":[';
				foreach my $i ( 0 .. $#{$LOG} ) {
					$LOG->[$i][1] =~ s/\\/\\\\/g;
					$LOG->[$i][1] =~ s/\n/\\n/g;
					$LOG->[$i][1] =~ s/\r/\\r/g;
					$LOG->[$i][1] =~ s/"/\\"/g;
					$LOG->[$i][1] =~ s/'/\\'/g;
					$LOG->[$i][1] =~ s/\//\\\//g;
					$LOG->[$i][1] =~ s/\b/\\\b/g;
					$LOG->[$i][1] =~ s/\f/\\\f/g;
					$LOG->[$i][1] =~ s/\t/\\\t/g;
					$LOG->[$i][1] =~ s/\&/\\\&/g;
					$LOG->[$i][1] =~ s/\?/\\\?/g;
					$LOG->[$i][1] =~ s/\$/\\\$/g;
					$LOG->[$i][1] =~ s/\{/\\\{/g;
					$LOG->[$i][1] =~ s/\}/\\\}/g;
					$LOG->[$i][1] =~ s/\[/\\\[/g;
					$LOG->[$i][1] =~ s/\]/\\\]/g;
					$var .= qq~{"insertDate":"$LOG->[$i][0]","log":"$LOG->[$i][1]"},~;
				}
				$var =~ s/,$//;
				$var .= ']}';
			}
			else {
				$var .= qq~{"Results":"No matches found"}~;
			}
			print $var;
		}
		else {
			print qq~{"Error":"No ticket Number"}~;
		}
	}
	else {
		print qq~{"Error":"Wrong PATH_INFO"}~;
	}
}
elsif ( $ENV{REQUEST_METHOD} eq 'PUT' ) {
	print $q->header('application/json');
	
	if ( $ENV{PATH_INFO} =~ /^\/insertTicket\// ) {
		my $json = eval { JSON->new->utf8->decode($data{PUTDATA}) };
		# my $json = eval { decode_json $data{PUTDATA} };
		
		if ( $json->{ticket}->{number} ) {
			my $sysdate = sysdate();
			
			connected();
			##### PARANOIAC!!! CHECK FOR id AutoBotCatched IF DOES NOT EXISTS
			$dbh->do("LOCK TABLES ticket WRITE, ticket AS ticketRead READ");
			
			my $sth = $dbh->prepare("SELECT numberTicket FROM ticket WHERE numberTicket = '$json->{ticket}->{number}'");
			$sth->execute();
			my ($TT) = $sth->fetchrow_array;
			$sth->finish;
			
			unless ( $TT ) {
				my $insert_string = "INSERT INTO ticket (numberTicket, sysidTicket, subject, initialDate, initialState, typeTicket, json) 
				VALUES (?, ?, ?, '$sysdate', ?, ?, ?)";
				my $sth = $dbh->prepare("$insert_string");
				
				if ( $sth->execute($json->{ticket}->{number}, $json->{ticket}->{sys_id}, $json->{ticket}->{subject}, $json->{ticket}->{state}, $json->{ticket}->{type}, $data{PUTDATA}) ) {
					restApiLog("INFO  :: $ticketNumber : Ticket successfully inserted with data: $data{PUTDATA}. User: $input{user}");
					print qq~$data{PUTDATA}~;
				} else {
					restApiLog("ERROR :: $ticketNumber : I cannot insert the ticket. Maybe JSON not well formed: $data{PUTDATA}. User: $input{user}");
					print qq~{"Error":"I cannot insert the ticket. Maybe JSON not well formed"}~;
				}
				
				$sth->finish;
				$dbh->do("UNLOCK TABLES");
				$dbh->disconnect if ($dbh);
				
				exit;
			}
			else {
				$dbh->do("UNLOCK TABLES");
				$dbh->disconnect if ($dbh);
				
				restApiLog("ERROR :: $ticketNumber : Ticket number $json->{ticket}->{number} already exists. User: $input{user}");
				print qq~{"Error":"Ticket number $json->{ticket}->{number} already exists"}~;
				exit;
			}
		}
		else {
			restApiLog("ERROR :: $ticketNumber : I cannot get the ticket Number. Data: $data{PUTDATA}. User: $input{user}");
			print qq~{"Error":"I cannot get the ticket Number"}~;
		}
	}
    elsif ( $ENV{PATH_INFO} =~ /^\/insertAlert\// ) {
        my $json = eval { JSON->new->decode($data{PUTDATA}) };
		# my $json = eval { decode_json $data{PUTDATA} };
        
        if ( $json->{alert}->{title} and $json->{alert}->{definition} ) {
            my $sysdate = sysdate();
            
            my $AND;
            $AND .= qq~ AND A.queue = '$json->{alert}->{queue}' ~ if $json->{alert}->{queue};
            $AND .= qq~ AND A.impact = '$json->{alert}->{impact}' ~ if $json->{alert}->{impact};
            $AND .= qq~ AND A.severity = '$json->{alert}->{severity}' ~ if $json->{alert}->{severity};
            $AND .= qq~ AND A.urgency = '$json->{alert}->{urgency}' ~ if $json->{alert}->{urgency};
            $AND .= qq~ AND A.description = '$json->{alert}->{description}' ~ if $json->{alert}->{description};
            
            connected();
            my $sth = $dbh->prepare(qq~SELECT A.idAlert, A.alertCounter, A.idTrigger, T.countToStatusUp, T.idAutoBot, T.Json 
            FROM alerts AS A, alertTriggerToAutoBot as T 
            WHERE A.title = '$json->{alert}->{title}' AND A.definition = '$json->{alert}->{definition}' $AND AND T.idTrigger = A.idTrigger~);
            $sth->execute();
            my ($idAlert, $alertCounter, $idTrigger, $countToStatusUp, $idAutoBot, $Json) = $sth->fetchrow_array;
            $sth->finish;
            
            if ( $idAlert ) {
                $alertCounter ++;
                my $sth = $dbh->prepare(qq~UPDATE alerts SET alertCounter = '$alertCounter', lastDate = '$sysdate' WHERE idAlert = '$idAlert'~);
                $sth->execute();
                $sth->finish;
                
                restApiLog("INFO  :: ALERTS : Alert successfully updated with data: $data{PUTDATA}. User: $input{user}");
                print qq~{"results": {"update alert": "successful"}}~;
            }
            else {
                $dbh->do("LOCK TABLES alerts WRITE");
                my $sth = $dbh->prepare(qq~INSERT INTO alerts 
                (insertDate, lastDate, severity, impact, urgency, queue, title, definition, description, idTrigger) VALUES (
                '$sysdate', '$sysdate', ?, ?, ?, ?, ?, ?, ?, ?)~);
                $sth->execute($json->{alert}->{severity}, $json->{alert}->{impact}, $json->{alert}->{urgency}, $json->{alert}->{queue}, $json->{alert}->{title}, $json->{alert}->{definition}, $json->{alert}->{description}, $json->{alert}->{idTrigger});
                $sth->finish;
                
                my $sth1 = $dbh->prepare(qq~SELECT idAlert FROM alerts ORDER BY idAlert DESC LIMIT 1~);
                $sth1->execute();
                my ($NewIdAlert) = $sth1->fetchrow_array;
                $sth1->finish;
                $dbh->do("UNLOCK TABLES");
                
                my $sth2 = $dbh->prepare(qq~INSERT INTO scalation (idAlert) VALUES ('$NewIdAlert')~);
                $sth2->execute();
                $sth2->finish;
                
                restApiLog("INFO  :: ALERTS : Alert successfully inserted with data: $data{PUTDATA}. User: $input{user}");
                print qq~{"results": {"insert alert": "successful"}}~;
            }
            $dbh->disconnect if ($dbh);
        }
        else {
            restApiLog("ERROR :: ALERTS : Tittle or Definition missing. Data: $data{PUTDATA}. User: $input{user}");
            print qq~{"Error":"Tittle or Definition missing"}~;
        }
    }
	else {
		restApiLog("ERROR :: $ticketNumber : Wrong PATH_INFO - $ENV{PATH_INFO}. User: $input{user}");
		print qq~{"Error":"Wrong PATH_INFO"}~;
	}
}
# elsif ( $ENV{REQUEST_METHOD} eq 'POST' ) {
	
# }
else {
	print $q->header('application/json');
	
	restApiLog("ERROR :: $ticketNumber : Wrong METHOD: $ENV{REQUEST_METHOD}. User: $input{user}");
	print qq~{"Error":"Wrong METHOD: $ENV{REQUEST_METHOD}"}~;
}

# print $q->header('application/json');
# print qq~{"":""}~;







exit;

sub connected {
	use DBI;
	$dbh = DBI->connect("DBI:mysql:$VAR{'DB'}:$VAR{'DBHOST'}", $VAR{'DBUSER'}, $VAR{'DBPASSWD'}) or restApiLog("ERROR :: $ticketNumber : MySQL Connect: " . $DBI::errstr) and exit;
}

sub restApiLog {
	my $msg = shift;
	my $date = date_nospace();
	my $sysdate = sysdate();
	my $engine_log_dir = $VAR{engine_log_dir};
	
	open my $ELOG, ">>", "$engine_log_dir/rest-api-$date.log";
	print $ELOG qq~$sysdate :: $msg\n~;
	close $ELOG;
	# restApiLog("ERROR :: $ticketNumber : ");
	# restApiLog("INFO  :: $ticketNumber : ");
	# restApiLog("WARN  :: $ticketNumber : ");
}

sub get_vars {
	my %VARS;
	open my $file, "<../../yaomiqui.conf";
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

sub date_nospace {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	$fecha[4] ++;
	@fecha = map { if ($_ < 10) { $_ = "0$_"; }else{ $_ } } @fecha;
						#year	mon		 mday		hour	min		sec
	return my $date_nospace = "$fecha[5]$fecha[4]$fecha[3]";
}

sub getEncKey {
	# my $o = tie my @array, 'Tie::File', $VAR{enc_key} or die "I can't open yaomiqui encrypted key: $VAR{enc_key}\n";
	my $o = tie my @array, 'Tie::File', $VAR{enc_key} or restApiLog("ERROR :: $ticketNumber : I can't open yaomiqui encrypted key: " . $VAR{enc_key}) and exit;
	my $encKey = $array[0];
	untie @array;
	return $encKey;
}


