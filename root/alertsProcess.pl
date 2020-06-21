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
use JSON;
use Tie::File;
use Data::Dumper;
use FindBin qw($RealBin);
use lib $RealBin;
use strict;
no strict "subs";
use Date::Calc qw(Delta_DHMS);

our ($dbh, %VAR);
%VAR = get_vars();


connected();
my $sth = $dbh->prepare("SELECT A.idAlert, A.alertCounter, A.insertDate, A.lastDate, A.severity, A.impact, A.urgency, A.title, A.definition, A.description, 
A.silenced, T.countToStatusUp, T.minutesToStatusDown, T.minutesToHidden, T.dlFirstEscalation, T.dlSecondEscalation, T.dlThirdEscalation, T.idAutoBot, T.Json 
FROM alerts AS A, alertTriggerToAutoBot AS T 
WHERE T.idTrigger = A.idTrigger");
$sth->execute();
my $alert = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);

my $sysdate = sysdate();
my ($year, $month, $day, $hour, $min, $seg) = parseDataDate($sysdate);

ALERT: for my $i ( 0 .. $#{$alert} ) {
    my ($idAlert, $alertCounter, $insertDate, $lastDate, $severity, $impact, $urgency, $title, $definition, $description, $silenced, $countToStatusUp, 
    $minutesToStatusDown, $minutesToHidden, $dlFirstEscalation, $dlSecondEscalation, $dlThirdEscalation, $idAutoBot, $Json) = @{$alert->[$i]};
    
    my $totalMinutes;
    my ($lyear, $lmonth, $lday, $lhour, $lmin, $lseg) = parseDataDate($lastDate);
    
    my ($tday, $thour, $tmin, $tsec) = Delta_DHMS($lyear, $lmonth, $lday, $lhour, $lmin, $lseg, $year, $month, $day, $hour, $min, $seg);
    
    $totalMinutes = $tmin;
    $totalMinutes += $tday * 24 * 60;
    $totalMinutes += $thour * 60;
    $totalMinutes += ($tsec * (100 / 60)) / 100;
    $totalMinutes = sprintf("%.2f", $totalMinutes);
    # print "TOTAL MINUTES DIFF: $totalMinutes\n";
    
    
    
    unless ( $silenced ) {
        unless ( $totalMinutes >= $minutesToStatusDown ) {
                ## Alert has downgraded the level. We don't do nothing
                # print "$totalMinutes >= $minutesToStatusDown\n";
            
            connected();
            my $sth = $dbh->prepare("SELECT firstScalation, secondScalation, thirdScalation FROM scalation WHERE idAlert = '$idAlert'");
            $sth->execute();
            my ($firstScalation, $secondScalation, $thirdScalation) = $sth->fetchrow_array;
            $sth->finish;
            $dbh->disconnect if ($dbh);
            
            my $escalationNumber;
            
            if ( $thirdScalation ) {
                next ALERT;
            }
            elsif ( $secondScalation ) {
                $escalationNumber = '3';
                $countToStatusUp = $countToStatusUp + 1;
            }
            elsif ( $firstScalation ) {
                $escalationNumber = '2';
                # $countToStatusUp = $countToStatusUp;
            }
            else {
                $escalationNumber = '1';
                $countToStatusUp = $countToStatusUp - 1;
            }
            
            
            if ( $alertCounter >= $countToStatusUp ) {
                        print "Este sí está alertado: $alertCounter >= $countToStatusUp\n";

                if ( $idAutoBot ) {
                    my $jsonData = qq~"idAlert": "$idAlert",
    "escalationNumber": "$escalationNumber",
    "dlFirstEscalation": "$dlFirstEscalation",
    "dlSecondEscalation": "$dlSecondEscalation",
    "dlThirdEscalation": "$dlThirdEscalation",
    "insertDate": "$insertDate",
    "severity": "$severity",
    "impact": "$impact",
    "urgency": "$urgency",
    "title": "$title",
    "definition": "$definition",
    "description": "$description"~;
                    
                    my $randId = randId();
                    
                    $Json =~ s/\[\[AUTOMATED-DATA\]\]/$jsonData/;
                    $Json =~ s/\$\{randomSysId\}/$randId/;
                    $Json =~ s/\n//g;
                    
                    my $TT;
                    foreach my $subIdx ( 1 .. 4 ) {
                        my $JsonToSend = $Json;
                        $TT = 'AL-'  . $idAlert . '_' . $subIdx;
                        
                        $JsonToSend =~ s/\$\{randomNumber\}/$TT/;
                        
                        print "Trying: $TT\n";
                        my $results = `curl -k -H "Content-Type: application/json" -X PUT -d '$JsonToSend' --url "https://127.0.0.1/yaomiqui/generic-api.cgi/insertTicket/"`;
                        print $results . "\n";
                        my $jsonDecoded = eval { JSON->new->decode($results) };
                        
                        unless ( $jsonDecoded->{Error} =~ /already exists/ ) {
                            last;
                        }
                        
                        next ALERT if $subIdx == 4;
                    }
                    
                    
                    my $escalationField;
                    my $ticketField;
                    if ( $escalationNumber eq '1' ) {
                        $escalationField = 'firstScalation';
                        $ticketField = 'numberFirstTicket';
                    }
                    if ( $escalationNumber eq '2' ) {
                        $escalationField = 'secondScalation';
                        $ticketField = 'numberSecondTicket';
                    }
                    if ( $escalationNumber eq '3' ) {
                        $escalationField = 'thirdScalation';
                        $ticketField = 'numberThirdTicket';
                    }
                    
                    connected();
                    my $sth1 = $dbh->prepare("UPDATE scalation SET $escalationField = '$sysdate', $ticketField = '$TT' WHERE idAlert = '$idAlert'");
                    $sth1->execute();
                    $sth1->finish;
                    $dbh->disconnect if ($dbh);
                    
                }
            }
            
        }
    }
    
    
    
    
    if ( $totalMinutes >= $minutesToHidden ) {
        print "This is for hidden (Move it to History): $totalMinutes >= $minutesToHidden\n";
        my $sysdate = sysdate();
        
        connected();
        my $sth = $dbh->prepare("SELECT * FROM alerts WHERE idAlert = '$idAlert'");
        $sth->execute();
        my @alert = $sth->fetchrow_array;
        $sth->finish;
        
        my $sth1 = $dbh->prepare("INSERT INTO alertsHistory (idAlert, alertCounter, insertDate, lastDate, hiddenDate, severity, impact, urgency, 
        queue, title, definition, description, idTrigger, silenced) VALUES (
        '$alert[0]', 
        '$alert[1]', 
        '$alert[2]', 
        '$alert[3]', 
        '$sysdate', 
        '$alert[5]', 
        '$alert[6]', 
        '$alert[7]', 
        '$alert[8]', 
        '$alert[9]', 
        '$alert[10]', 
        '$alert[11]', 
        '$alert[12]', 
        '$alert[13]')");
        $sth1->execute();
        $sth1->finish;
        
        my $sth2 = $dbh->prepare("DELETE FROM alerts WHERE idAlert = '$idAlert'");
        $sth2->execute();
        $sth2->finish;
        
        $dbh->disconnect if ($dbh);
    }
}










exit;

sub parseDataDate {
    my $date = shift;
    
    $date =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/;  #2020-06-06 10:17:30
    my $yr = $1;
    my $mon = $2;
    my $day = $3;
    my $hr = $4;
    my $min = $5;
    my $seg = $6;
    
    return ($yr, $mon, $day, $hr, $min, $seg)
}

sub connected {
	use DBI;
	$dbh = DBI->connect("DBI:mysql:$VAR{'DB'}:$VAR{'DBHOST'}", $VAR{'DBUSER'}, $VAR{'DBPASSWD'}) or restApiLog("ERROR  :: MySQL Connect: " . $DBI::errstr) and exit;
}

sub get_vars {
	my %VARS;
	open my $file, "</var/www/yaomiqui/yaomiqui.conf";
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
	# return my $date_nospace = "$fecha[5]$fecha[4]$fecha[3]$fecha[2]$fecha[1]$fecha[0]";
	return my $date_nospace = "$fecha[3]$fecha[2]$fecha[1]";
}

sub randId {
    my @chars = ('a'..'z',1..9,'A'..'Z');
    my $randId;
    $randId .= $chars[int(rand(@chars))] for 1..32;
    
    return $randId;
}





