#!/usr/bin/perl
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# This is the Main ENGINE
# The automation Power for Yaomiqui RPA Orchestrator
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
# use warnings;
use XML::Simple;
use JSON;
use strict;
use Net::OpenSSH;
use Data::Dumper;
use FindBin qw($RealBin);
use lib $RealBin;

our ($ticketNumber, $dbh, %VAR, %VENV, $jsonCode, $AutoBot);
# our ($ticketNumber, $dbh, $jsonCode, $AutoBot);
%VENV = get_vars();
%VAR = get_add_env_vars();

$VAR{TIMEOUT} = $VENV{TIMEOUT};
$VAR{SSH_TIMEOUT} = $VENV{SSH_TIMEOUT};
$VAR{ENVIRONMENT} = $VENV{ENVIRONMENT};
## For WinRM
$VAR{WINRM_CONNECTOR} = $VENV{WINRM_CONNECTOR};
$VAR{WINRM_PROTOCOL} = $VENV{WINRM_PROTOCOL};
$VAR{WINRM_TIMEOUT} = 60;

if ( $ARGV[0] ) {
    $ticketNumber = $ARGV[0];
} else {
    exit;
}

my $specAutoBot;
$specAutoBot = " AND idAutoBot = '$ARGV[1]'" if $ARGV[1];

connected();
my $sth = $dbh->prepare("SELECT * FROM autoBot WHERE active = '1'$specAutoBot ORDER BY idAutoBot ASC") or engineLog("ERROR :: $ticketNumber : I cannot do Select on autoBot table") and exit;
$sth->execute();
my $AB = $sth->fetchall_arrayref;
$sth->finish;

## Adding a last Autobot for tickets without no one filter to catch it but
my @a = ('','NO AUTOBOT NAME','','2018-10-07 00:00:00','1','1',"<AUTO><ON><VAR name='number' compare='exists'/></ON><DO><LOGING comment='No any Autobot caught this Ticket'/><SetVar name='TIMEOUT' value='1'></SetVar></DO></AUTO>");
## push on references was actually removed entirely in Perl 5.24 or newer
push @$AB, [@a];

my $sth = $dbh->prepare("SELECT * FROM ticket WHERE numberTicket = '$ticketNumber'") or engineLog("ERROR :: $ticketNumber : I cannot do Select on ticket table") and exit;
$sth->execute();
my @TTS = $sth->fetchrow_array;
$sth->finish;
$dbh->disconnect if ($dbh);

$TTS[1] = $ticketNumber unless $TTS[1];

my $jsonCode = $ARGV[2] ? $ARGV[2] : $TTS[10];
$jsonCode =~ s/\\/\\\\/g;
$jsonCode =~ s/\r?\n//g;

# ## debug
# print "JSONCODE:\n" . $jsonCode . "\n";

engineLog("INFO  :: $TTS[1] : Processing ticket with JSON: " . $jsonCode);

my $json = eval { decode_json $jsonCode };		# my $json = eval { from_json($jsonCode) };

# ## debug
# print "JSON: " . Dumper($json) . "\n";

chdir $RealBin;

if ( $json ) {
    
    foreach my $k ( keys %{$json->{ticket}} ) {
    	$VAR{$k} = $json->{ticket}->{$k};
    }
    foreach my $k ( keys %{$json->{data}} ) {
    	$VAR{$k} = $json->{data}->{$k};
    }
    
    		# ## debug
    		# foreach my $key ( sort keys %VAR ) {
    			# print "$key = $VAR{$key}\n";
    		# }
    	
    ####	CHECK FOR EACH AUTOBOT
    AUTOBOT: for my $i ( 0 .. $#{$AB} ) {
    	
    	$AB->[$i][6] =~ s/\r//g;
    	$AB->[$i][6] =~ s/\n//g;
    	
    	$AB->[$i][6] =~ s/ xml\:space\=\'preserve\'//g;
    	
    	##	Adding a DO Statement for Timeout if you forget to put some END function
    	my $extendedTO = $VAR{TIMEOUT} + 30;
    	$AB->[$i][6] =~ s/<\/AUTO>/<DO><Sleep seconds='$extendedTO'\/><\/DO><\/AUTO>/;
    	
    	# ## Debug
    	# print "\nXML code:\n" . $AB->[$i][6] . "\n";
    	
    	$AB->[$i][6] = forceDOarray($AB->[$i][6]);
    	
    	# ## debug
    	# print "XML:\n" . qq~$AB->[$i][6]~ . "\n\n";
    	
    	my $xml = XML::Simple->new;
    	
    	my $aBot = eval { $xml->XMLin(
    		$AB->[$i][6],
    		KeyAttr => { NoEscape => 1 },
    		ForceArray => [ 'VAR', 'DO' ],
    		ContentKey => '-content' 
    	)};
    	unless ( $aBot ) {
    		# engineLog(qq~ERROR :: $ticketNumber : $@ : Not Valid XML for AutoBot when trying to parser the string '$AB->[$i][6]'. Trying with next AutoBot~);
    		engineLog(qq~ERROR :: $ticketNumber : Not Valid XML for AutoBot when trying to parser the string '$AB->[$i][6]'. Trying with next AutoBot~);
    		next;
    	};
    	
    		# ## debug
    		# print Dumper($aBot->{ON}->{VAR}->[0], $aBot->{ON}->{VAR}->[1], $aBot->{ON}->{VAR}->[2]) . "\n";
    	
    	my $catch = 0;
    	
    	foreach my $i ( 0 .. $#{$aBot->{ON}->{VAR}} ) {
    		
    		# ## debug
    		# print Dumper($aBot->{ON}->{VAR}->[$i]) . "\n";
    		
    		my $name = $aBot->{ON}->{VAR}->[$i]->{name}; # to be frienldy next line
    		$catch = compareVAR($VAR{$name}, $aBot->{ON}->{VAR}->[$i]->{compare}, $aBot->{ON}->{VAR}->[$i]->{value}, $VAR{number}, 'no_log');
    		
    		# ## debug
    		# print "\$catch = $catch\n";
    		
    		next AUTOBOT unless $catch;		## 	THIS TICKET DOES NOT APPLIES FOR THIS AUTOBOT BECAUSE ONE OF THEM IS NOT TRUE
    	}
    	
    	
    	if ( $catch ) {
    		
    		unless ( $ARGV[1] ) {
    			connected();
    			
    			##### PARANOIAC!!! CHECK FOR id AutoBotCatched IF IS EMPTY (again I kow) AND LOCK THE TABLE TO CATCH THIS
    			$dbh->do("LOCK TABLES ticket WRITE, ticket AS ticketRead READ");
    			
    			my $chk = $dbh->prepare("SELECT idAutoBotCatched, finalState FROM ticket AS ticketRead WHERE numberTicket = '$ticketNumber'");
    			$chk->execute();
    			my $ABc = $chk->fetchall_arrayref;
    			$chk->finish;
    			
    			my $doLog = 0;
    			unless ( $ABc->[0][0] or $ABc->[0][1] ) {
    				my $sth = $dbh->prepare("UPDATE ticket SET idAutoBotCatched='$AB->[$i][0]' WHERE numberTicket='$ticketNumber'");
    				$sth->execute();
    				$sth->finish;
    				$dbh->do("UNLOCK TABLES");
    				$dbh->disconnect if $dbh;
    				$doLog = 1;
    			} else {
    				$dbh->do("UNLOCK TABLES");
    				$dbh->disconnect if $dbh;
    				next AUTOBOT;
    			}
    			
    			if ( $doLog ) {
    				## debug
    				# print "GOTCHA!! I have ticket '$TTS[1]' to this Autobot\n\n";
    				$AutoBot = $AB->[$i][0];
    				mlog($TTS[1], qq~Ticket was caught by Autobot ID: [<a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$AB->[$i][0]" target="_blank">$AB->[$i][0]</a>]~);
    				engineLog(qq~INFO  :: $ticketNumber : Ticket was caught by Autobot ID $AB->[$i][0] ($AB->[$i][1])~);
    			}
    			
    		} else {
    			$AutoBot = $AB->[$i][0];
    			mlog($TTS[1], qq~Ticket was caught by Autobot ID: [<a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$AB->[$i][0]" target="_blank">$AB->[$i][0]</a>]~);
    			engineLog(qq~INFO  :: $ticketNumber : Ticket was caught by Autobot ID $AB->[$i][0] ($AB->[$i][1])~);
    		}
    		
    		####	waterfall depth
    		if ( exists $aBot->{IF} ) {
    			foreach my $i ( 0 .. $#{$aBot->{IF}->{VAR}} ) {
    				my $catchInitIF = 0;
    				
    				# ## debug
    				# print Dumper($aBot->{IF}->{VAR}->[$i]) . "\n";
    				
    				my $name = replaceSpecChar($aBot->{IF}->{VAR}->[$i]->{name}); # to be frienldy next line
    				my $value = replaceSpecChar($aBot->{IF}->{VAR}->[$i]->{value});
    				
    				# ## debug
    				# print "RAW: $aBot->{IF}->{VAR}->[$i]->{name} <-> $aBot->{IF}->{VAR}->[$i]->{value}\n";
    				# print "SUS: $name <-> $value\n";
    				
    				$catchInitIF = compareVAR($name, $aBot->{IF}->{VAR}->[$i]->{compare}, $value, $VAR{number});
    				
    				if ( $catchInitIF ) {
    					if ( $aBot->{IF}->{VAR}->[$i]->{DO} ) {
    						runDO($aBot->{IF}->{VAR}->[$i]->{DO}, $VAR{number});
    					} else {
    						if ( $aBot->{IF}->{DO}->{LOGING} ) {
    							my $comment = replaceSpecChar($aBot->{IF}->{DO}->{LOGING}->{comment});
    							runLOGING($comment, $VAR{number});
    						}
    						if ( $aBot->{IF}->{DO}->{END} ) {
    							my $value = replaceSpecChar($aBot->{IF}->{DO}->{END}->{value});
    							runEND($value, $VAR{number});
    						}
    						elsif ( $aBot->{IF}->{DO}->{RETURN} ) {
    							my $value = replaceSpecChar($aBot->{IF}->{DO}->{RETURN}->{value});
    							runRETURN($value, $VAR{number}, $AutoBot);
    						}
    					}
    					
    				}
    			}
    		}
    		elsif ( exists $aBot->{DO} ) {
    			
    			# ## debug
    			# print "TICKET: " . $VAR{number} . "\nDUMPER:\n" . Dumper($aBot->{DO}) , "\n";
    			
    			runDO($aBot->{DO}, $VAR{number});
    		}
    		# `kill -9 $$`;
    		# exit;
    	}
    }
    
} else {
    print "Error: Not Valid JSON";
    engineLog(qq~ERROR :: $ticketNumber : Not Valid JSON for ticket when trying to parser the string '$jsonCode'~);
    # `kill -9 $$`;
    # exit;
}



`kill -9 $$`;
exit;

sub runLOGING {
    my ($comment, $TT) = @_;
    $comment = replaceSpecChar($comment);
    
    # print $comment."\n" if $TT eq 'NDF00000001';
    
    mlog($TT, qq~NOTE: [$comment]~);
}

sub runEND {
    my ($value, $TT) = @_;
    my $sysdate = sysdate();
    
    $value = replaceSpecChar($value);
    
    if ( $ticketNumber ne 'NDF00000001' ) {
    	connected();
    	my $sth = $dbh->prepare("UPDATE ticket SET finalDate = '$sysdate', finalState = '$value' WHERE numberTicket='$TT'");
    	$sth->execute();
    	$sth->finish;
    	$dbh->disconnect if $dbh;
    }
    
    mlog($TT, qq~Final State: [$value]~);
    engineLog("INFO  :: $TT : Ticket closed with status [$value]");
    
    my $pid = $$;
    `kill -9 $pid`;
    exit;
}

sub runRETURN {
    my ($value, $TT, $AutoBot) = @_;
    $value = replaceSpecChar($value);
    
    print $value;
    
    mlog($TT, qq~Returned value: [$value]~);
    engineLog("INFO  :: $TT : Autobot $AutoBot returned with status [$value]");
    
    my $pid = $$;
    `kill -9 $pid`;
    exit;
}

sub replaceSpecChar {
    my $line = shift;
    
    # $line =~ s!\$\{([^\$\}]+)\}!$VAR{$1}!g;
    $line =~ s!\$\{([a-zA-Z\_]+)\}!$VAR{$1}!g;
    
    $line = replaceHash($line) if $line =~ /\$\[\[/;
    
    return $line;
}

sub replaceHash {
    my $line = shift;
    
    $line =~ /(.*)\$\[\[\{([a-zA-Z0-9\{\}\_\-\.]+)\}\]\](.*)/;
    my $bef = $1;
    my $tmp = $2;
    my $aft = $3;
    
    my $content;
    my @T = split(/\}\{/, $tmp);
    
    if ( scalar @T == 5 ) { $content = $VAR{$T[0]}{$T[1]}{$T[2]}{$T[3]}{$T[4]} }
    elsif ( scalar @T == 4 ) { $content = $VAR{$T[0]}{$T[1]}{$T[2]}{$T[3]} }
    elsif ( scalar @T == 3 ) { $content = $VAR{$T[0]}{$T[1]}{$T[2]} }
    elsif ( scalar @T == 2 ) { $content = $VAR{$T[0]}{$T[1]} }
    else { $content = $VAR{$T[0]} }
    
    $bef = replaceHash($bef) if $bef =~ /\$\[\[/;
    $aft = replaceHash($aft) if $aft =~ /\$\[\[/;
    
    $line = $bef . $content . $aft;
    
    return $line;
}

sub runDO {
    
    my ($DOarray, $TT) = @_;
    my @output;
    
    foreach my $DO ( @{$DOarray} ) {
    	## Timeout function starts
    	eval {
    		local $SIG{ALRM} = sub { die "timeout\n" };
    		alarm $VAR{TIMEOUT};
    		## Timeout function 1rst section
    		
    		
    		
    		
    		
    		## START TO EXECUTE ALL OF DO FUNCTION
    		
    		if ( $DO->{execLinuxCommand} ) {
    			$VAR{Error} = '';
    			
    			my $linuxCommand = replaceSpecChar($DO->{execLinuxCommand}->{command});
    			# $linuxCommand =~ s/'/'\\''/g;
    			$linuxCommand =~ s/\r?\n//g;
    			
    			my $linerrfile = '/tmp/' . $TT . '.err';
    			
    			# ## debug
    			# print "COMMAND:\n" . $linuxCommand . "\n\n";
    			
    			$VAR{ $DO->{execLinuxCommand}->{catchVarName} } = `$linuxCommand 2>$linerrfile`;
    			$VAR{ $DO->{execLinuxCommand}->{catchVarName} } =~ s/^\n//g;
    			$VAR{ $DO->{execLinuxCommand}->{catchVarName} } =~ s/\n$//g;
    			
    			$VAR{Error} = `cat $linerrfile 2>/dev/null`;
    			$VAR{Error} =~ s/^\n//g;
    			$VAR{Error} =~ s/\n$//g;
    			
    			# ## debug
    			# print "RESULTS:\n" . $VAR{ $DO->{execLinuxCommand}->{catchVarName} } . "\n\n";
    			
    			unless ( $VAR{Error} ) {
    				mlog($TT, qq~Linux Command [$DO->{execLinuxCommand}->{command}] Executed on Local Server [localhost]. Results: [$VAR{ $DO->{execLinuxCommand}->{catchVarName} }]~ . "\nError: []");
    			} else {
    				mlog($TT, qq~Linux Command [$DO->{execLinuxCommand}->{command}] Executed on Local Server [localhost]. Results: [$VAR{ $DO->{execLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
    			}
    			
    			unlink "$linerrfile";
    		}
    		
    		
    		if ( $DO->{execRemoteLinuxCommand} ) {
    			$VAR{Error} = '';
    			my $remoteLinuxCommand;
    			if ( $DO->{execRemoteLinuxCommand}->{publicKey} ) {
    				$DO->{execRemoteLinuxCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteUser});
    				$DO->{execRemoteLinuxCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteHost});
    				$DO->{execRemoteLinuxCommand}->{publicKey} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{publicKey});
    				
    				my $SACM = $VAR{TIMEOUT} / 60;
    				$DO->{execRemoteLinuxCommand}->{port} = 22 unless $DO->{execRemoteLinuxCommand}->{port};
    				
    				$Net::OpenSSH::debug = -1;
    				my $ssh = Net::OpenSSH->new($DO->{execRemoteLinuxCommand}->{remoteHost},
    					user				=> $DO->{execRemoteLinuxCommand}->{remoteUser},
    					key_path			=> $DO->{execRemoteLinuxCommand}->{publicKey},
    					port				=> $DO->{execRemoteLinuxCommand}->{port},
    					strict_mode			=> 0,
    					timeout				=> $VAR{SSH_TIMEOUT},
    					kill_ssh_on_timeout	=> 1,
    					master_opts 		=> [-o => 'StrictHostKeyChecking=no',
    											-o => 'LogLevel=QUIET',
    											-o => "ConnectTimeout=$VENV{CONNECTTIMEOUT}",
    											-o => 'ServerAliveInterval=60',
    											-o => "ServerAliveCountMax=$SACM",
    											-o => 'TCPKeepAlive=yes']
    				);
    				
    				$VAR{Error} = $ssh->error;
    				$VAR{Error} =~ s/^\n//g;
    				$VAR{Error} =~ s/\n$//g;
    				
    				$remoteLinuxCommand = replaceSpecChar($DO->{execRemoteLinuxCommand}->{command});
    				$remoteLinuxCommand =~ s/'/'\\''/g;
    				$remoteLinuxCommand =~ s/\r?\n//g;
    				
    				unless ( $ssh->error ) {
    					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } = $ssh->capture2("$remoteLinuxCommand 2>&1");
    					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } =~ s/^\n//g;
    					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } =~ s/\n$//g;
    					mlog($TT, qq~Remote Linux Command [$DO->{execRemoteLinuxCommand}->{command}] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: []");
    				}
    				else {
    					mlog($TT, qq~Remote Linux Command [$DO->{execRemoteLinuxCommand}->{command}] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
    				}
    				## END OF execRemoteLinuxCommand WITH PUBLIC KEY
    			}
    			else {
    				$DO->{execRemoteLinuxCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteUser});
    				$DO->{execRemoteLinuxCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteHost});
    				my $linuxpasswd = replaceSpecChar($DO->{execRemoteLinuxCommand}->{passwd});
    				
    				if ( $DO->{execRemoteLinuxCommand}->{EncKey} and $DO->{execRemoteLinuxCommand}->{EncPasswd} ) {
    					$DO->{execRemoteLinuxCommand}->{EncKey} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{EncKey});
    					$DO->{execRemoteLinuxCommand}->{EncPasswd} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{EncPasswd});

    					use Babel;
    					my $crypt = new Babel;
    					$linuxpasswd = $crypt->decode($DO->{execRemoteLinuxCommand}->{EncPasswd}, $DO->{execRemoteLinuxCommand}->{EncKey});
    				}
    				
    				## print "PASSWORD: " . $DO->{execRemoteLinuxCommand}->{passwd} . "\n";
    				my $SACM = $VAR{TIMEOUT} / 60;
    				$DO->{execRemoteLinuxCommand}->{port} = 22 unless $DO->{execRemoteLinuxCommand}->{port};
    				
    				$Net::OpenSSH::debug = -1;
    				my $ssh = Net::OpenSSH->new($DO->{execRemoteLinuxCommand}->{remoteHost},
    					user				=> $DO->{execRemoteLinuxCommand}->{remoteUser},
    					password			=> $linuxpasswd,
    					port				=> $DO->{execRemoteLinuxCommand}->{port},
    					strict_mode			=> 0,
    					timeout				=> $VAR{SSH_TIMEOUT},
    					kill_ssh_on_timeout	=> 1,
    					master_opts 		=> [-o => 'StrictHostKeyChecking=no',
    											-o => 'LogLevel=QUIET',
    											-o => "ConnectTimeout=$VENV{CONNECTTIMEOUT}",
    											-o => 'ServerAliveInterval=60',
    											-o => "ServerAliveCountMax=$SACM",
    											-o => 'TCPKeepAlive=yes']
    					# master_opts => [-o => 'StrictHostKeyChecking=no', -o => 'LogLevel=QUIET']
    				);
    				
    				$VAR{Error} = $ssh->error;
    				$VAR{Error} =~ s/^\n//g;
    				$VAR{Error} =~ s/\n$//g;
    				
    				$remoteLinuxCommand = replaceSpecChar($DO->{execRemoteLinuxCommand}->{command});
    				$remoteLinuxCommand =~ s/'/'\\''/g;
    				$remoteLinuxCommand =~ s/\r?\n//g;
    				
    				unless ( $VAR{Error} ) {
    					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } = $ssh->capture2("$remoteLinuxCommand 2>&1");
    					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } =~ s/^\n//g;
    					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } =~ s/\n$//g;
    					mlog($TT, qq~Remote Linux Command [$DO->{execRemoteLinuxCommand}->{command}] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: []");
    				}
    				else {
    					mlog($TT, qq~Remote Linux Command [$DO->{execRemoteLinuxCommand}->{command}] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
    				}
    				## END OF execRemoteLinuxCommand WITH USER AND PASSWORD
    			}
    		}
    		
    		
    		if ( $DO->{execRemoteWindowsCommand} ) {
    			$VAR{Error} = '';
                
    			my $remoteWindowsCommand = replaceSpecChar($DO->{execRemoteWindowsCommand}->{command});
    			$remoteWindowsCommand =~ s/'/'\\''/g;
    			$remoteWindowsCommand =~ s/\r//g;
    			$remoteWindowsCommand =~ s/\n//g;
                # $remoteWindowsCommand =~ s/\\"/"/g;
    			# $remoteWindowsCommand =~ s/"/\\"/g;
    			
    			$DO->{execRemoteWindowsCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{remoteUser});
    			$DO->{execRemoteWindowsCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{remoteHost});
    			my $winpasswd = replaceSpecChar($DO->{execRemoteWindowsCommand}->{passwd});
    			$DO->{execRemoteWindowsCommand}->{remoteDomain} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{domain});

    			$DO->{execRemoteWindowsCommand}->{EncPasswd} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{EncPasswd});
    			$DO->{execRemoteWindowsCommand}->{EncKey} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{EncKey});
    			
    			if ( $DO->{execRemoteWindowsCommand}->{EncKey} and $DO->{execRemoteWindowsCommand}->{EncPasswd} ) {
    				use Babel;
    				my $crypt = new Babel;
    				$winpasswd = $crypt->decode($DO->{execRemoteWindowsCommand}->{EncPasswd}, $DO->{execRemoteWindowsCommand}->{EncKey});
    			}
    			
    			$DO->{execRemoteWindowsCommand}->{remoteDomain} = $DO->{execRemoteWindowsCommand}->{remoteDomain} . '/' if $DO->{execRemoteWindowsCommand}->{remoteDomain};
    			
    			my $winerrfile = '/tmp/' . $TT . '.err';
                
                ## Added for SOAP::WinRM
                my @execute;
                
                ########################################################
                ####    WINEXE
                ########################################################
    			if ( $VAR{WINRM_CONNECTOR} eq 'Winexe' ) {
                    engineLog($TT, qq~Using Winexe as Windows connector~);
                    engineLog($TT, qq~Using Domain $DO->{execRemoteWindowsCommand}->{remoteDomain}~) if $DO->{execRemoteWindowsCommand}->{remoteDomain};
                    mlog($TT, qq~Using Winexe as Windows connector~);
                    mlog($TT, qq~Using Domain $DO->{execRemoteWindowsCommand}->{remoteDomain}~) if $DO->{execRemoteWindowsCommand}->{remoteDomain};
                    
                    $remoteWindowsCommand =~ s/\\"/"/g;
                    $remoteWindowsCommand =~ s/"/\\"/g;
                    
                    ####	FOR UBUNTU 18.04
                    my $bionic;
                    my $ostype = `cat /etc/os-release | egrep -w 'ID|VERSION_ID' | sed 's/"//g' | awk -F"=" '{print \$2}'`;
                    $ostype =~ s/\n//g;
                    
                    if ( $ostype eq 'ubuntu18.04' ) {
                        $bionic = '-d 1';
                    }
                    ####
                    
                    $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } = `winexe $bionic -k $DO->{execRemoteWindowsCommand}->{useKerberos} --uninstall -U '$DO->{execRemoteWindowsCommand}->{remoteDomain}$DO->{execRemoteWindowsCommand}->{remoteUser}\%$winpasswd' //$DO->{execRemoteWindowsCommand}->{remoteHost} '$remoteWindowsCommand' 2>$winerrfile`;
                    $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } =~ s/^\n//g;
                    $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } =~ s/\n$//g;
                    
                    ####	FOR UBUNTU 18.04
                    if ( ( $ostype eq 'ubuntu18.04' ) and ( $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } =~ /NT_STATUS/ ) ) {
                        $VAR{Error} = $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} };
                        $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } = '';
                    } else {
                        ## debug
                        # print qq~COMMAND LINE:winexe -U '$DO->{execRemoteWindowsCommand}->{remoteDomain}$DO->{execRemoteWindowsCommand}->{remoteUser}\%$DO->{execRemoteWindowsCommand}->{remotePasswd}' //$DO->{execRemoteWindowsCommand}->{remoteHost} '$remoteWindowsCommand'\n~;
                        
                        $VAR{Error} = `cat $winerrfile 2>/dev/null`;
                        $VAR{Error} =~ s/^\n//g;
                        $VAR{Error} =~ s/\n$//g;
                    }
                    ####
                }
                ########################################################
                ####    SOAP::WinRM
                ########################################################
                elsif ( $VAR{WINRM_CONNECTOR} eq 'WinRM' ) {
                    $DO->{execRemoteWindowsCommand}->{remoteDomain} =~ s/\/$//;
                    # $DO->{execRemoteWindowsCommand}->{useKerberos} = 'yes' ? '1' : '0';
                    
                    engineLog($TT, qq~Using WinRM as Windows connector~);
                    engineLog($TT, qq~Using Domain $DO->{execRemoteWindowsCommand}->{remoteDomain}~) if $DO->{execRemoteWindowsCommand}->{remoteDomain};
                    engineLog($TT, qq~Using Kerberos: $DO->{execRemoteWindowsCommand}->{useKerberos}~) if $DO->{execRemoteWindowsCommand}->{useKerberos};
                    mlog($TT, qq~Using WinRM as Windows connector~);
                    mlog($TT, qq~Using Domain $DO->{execRemoteWindowsCommand}->{remoteDomain}~) if $DO->{execRemoteWindowsCommand}->{remoteDomain};
                    mlog($TT, qq~Using Kerberos: $DO->{execRemoteWindowsCommand}->{useKerberos}~) if $DO->{execRemoteWindowsCommand}->{useKerberos};
                    
                    $DO->{execRemoteWindowsCommand}->{useKerberos} = 'yes' ? '1' : '0';
                    
                    ## PowerShell-SOAP::WinRM to Winexe Microbots compatibility
                    $remoteWindowsCommand =~ s/^\n*//;
                    $remoteWindowsCommand =~ s/\n*$//;
                    $remoteWindowsCommand =~ s/^powershell\s*\&\s*\{(.+)\}$/PowerShell \"\&{$1}\"/i;
                    
                    $VAR{WINRM_PROTOCOL} = lc $VAR{WINRM_PROTOCOL};
                    
                    ## Debug
                    # print $remoteWindowsCommand . "\n";
                    # print $DO->{execRemoteWindowsCommand}->{remoteDomain} . $DO->{execRemoteWindowsCommand}->{remoteUser} . "\n";
                    
                    use SOAP::WinRM;
                    my $winrm = SOAP::WinRM->new(
                        host            => $DO->{execRemoteWindowsCommand}->{remoteHost},
                        protocol		=> $VAR{WINRM_PROTOCOL},
                        timeout			=> $VAR{WINRM_TIMEOUT},
                        domain          => $DO->{execRemoteWindowsCommand}->{remoteDomain},
                        username        => $DO->{execRemoteWindowsCommand}->{remoteUser},
                        password        => $winpasswd,
                        kerberos        => $DO->{execRemoteWindowsCommand}->{useKerberos}
                    );
                    
                    unless ($winrm) {
                        $VAR{Error} = $SOAP::WinRM::errstr;
                    }
                    else {
                        @execute = $winrm->execute( command => [ $remoteWindowsCommand ] );
                        
                        unless (defined($execute[0])) {
                            $VAR{Error} = $winrm->errstr;
                        } else {
                            chomp @execute;
                            $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } = $execute[1];
                        }
                    }
                }
                ## Added for SOAP::WinRM
                
    			unless ( $VAR{Error} ) {
    				mlog($TT, qq~Remote Windows Command [$DO->{execRemoteWindowsCommand}->{command}] Executed on Remote Server [$DO->{execRemoteWindowsCommand}->{remoteHost}].\nResults: [$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} }]~ . "\nError: []");
    			}
    			else {
    				mlog($TT, qq~Remote Windows Command [$DO->{execRemoteWindowsCommand}->{command}] Executed on Remote Server [$DO->{execRemoteWindowsCommand}->{remoteHost}].\nResults: [$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} }]~ . "\nError: [" . $VAR{Error} . "]");
    			}
    			
    			unlink "$winerrfile";
    		}
    		
    		
    		if ( $DO->{DecodePWDtoVar} ) {
    			$VAR{Error} = '';
    			if ( $DO->{DecodePWDtoVar}->{EncKey} and $DO->{DecodePWDtoVar}->{EncPasswd} ) {
    				$DO->{DecodePWDtoVar}->{EncKey} = replaceSpecChar($DO->{DecodePWDtoVar}->{EncKey});
    				$DO->{DecodePWDtoVar}->{EncPasswd} = replaceSpecChar($DO->{DecodePWDtoVar}->{EncPasswd});
    				
    				use Babel;
    				my $crypt = new Babel;
    				$VAR{ $DO->{DecodePWDtoVar}->{name} } = $crypt->decode($DO->{DecodePWDtoVar}->{EncPasswd}, $DO->{DecodePWDtoVar}->{EncKey});
    				mlog($TT, 'Encrypted Password was decode using EncKey and assigned to "${' . $DO->{DecodePWDtoVar}->{name} . '}" variable');
    			} else {
    				$VAR{Error} = 'Encrypted Password or EncKey is missing';
    				mlog($TT, qq~Error: Encrypted Password or EncKey is missing~);
    			}
    		}
    		
    		
    		if ( $DO->{JSONtoVar} ) {
    			$VAR{Error} = '';
    			$DO->{JSONtoVar}->{JsonSource} =~ s/\$|\{|\}|\s//g;
    			
    			my $json = eval { decode_json $VAR{ $DO->{JSONtoVar}->{JsonSource} } };
    			## debug
    			# print "VAR:\n" . Dumper(%{$VAR{$DO->{JSONtoVar}->{catchVarName}}}) . "\n";
    			
    			if ( $json ) {
    				%{$VAR{$DO->{JSONtoVar}->{catchVarName}}} = %{$json};
    				## debug
    				# print "VAR:\n" . Dumper(%{$VAR{$DO->{JSONtoVar}->{catchVarName}}}) . "\n";
    				
    				mlog($TT, qq~JSONtoVar [$DO->{JSONtoVar}->{catchVarName}] Mapped. Results: [Ok]~);
    			} else {
    				# ## debug
    				# print "Error: NOT VALID JSON\n";
    				$VAR{Error} = 'NOT VALID JSON';
    				mlog($TT, qq~JSONtoVar [$DO->{JSONtoVar}->{catchVarName}] Not Mapped. Results: [Error: $VAR{Error}]~);
    			}
    		}
    		
    		
    		if ( $DO->{SetVar} ) {
    			$DO->{SetVar}->{value} = replaceSpecChar($DO->{SetVar}->{value});
    			$DO->{SetVar}->{name} =~ s/\$|\{|\}|\s//g;
    			$VAR{ $DO->{SetVar}->{name} } = $DO->{SetVar}->{value};
    			
    			## debug
    			# print "NAME:" . $DO->{SetVar}->{name} . "\n";
    			# print "VALUE: " . $DO->{SetVar}->{value} . "\n";
    			# print "VALUE: " . $VAR{ $DO->{SetVar}->{name} } . "\n";
    			
    			mlog($TT, qq~Setting value [$DO->{SetVar}->{value}] to var [$DO->{SetVar}->{name}]. Results: [Ok]~);
    		}
    		
    		
    		if ( $DO->{SplitVar} ) {
    			my $separator = $DO->{SplitVar}->{separator};
    			$separator =~ s/comma/\,/;
    			$separator =~ s/semicolon/\;/;
    			$separator =~ s/pipe/\\|/;
    			$separator =~ s/nl/\\n/;
    			
    			$DO->{SplitVar}->{arrayName} =~ s/\$|\{|\}|\s//g;
    			@{ $VAR{ $DO->{SplitVar}->{arrayName} } } = split(/$separator/, replaceSpecChar($DO->{SplitVar}->{inputVarName}));
    			
    			# ## debug
    			# print "Split Dumper: \n" . Dumper($VAR{ $DO->{SplitVar}->{arrayName} }) . "\n";
    			
    			mlog($TT, qq~Splitting variable [$DO->{SplitVar}->{inputVarName}] to Array Variable [$DO->{SplitVar}->{arrayName}]. Results: [Ok]~);
    		}
    		
    		
    		if ( $DO->{FOREACH} ) {
    			mlog($TT, qq~Starting to execute FOREACH~);
    			
    			$DO->{FOREACH}->{arrayName} =~ s/\$|\{|\}|\s//g;
    			FOREACH_LOOP: foreach my $i ( @{ $VAR{ $DO->{FOREACH}->{arrayName} } } ) {
    				$VAR{i} = $i;
    				
    				# ## debug
    				# print $VAR{i}, "\n";
    				
    				runDO($DO->{FOREACH}->{DO}, $TT);
    				if ( $DO->{FOREACH}->{lastIfi} ) {
    					if ( $VAR{i} eq $DO->{FOREACH}->{lastIfi} ) {
    						mlog($TT, qq~Coming out of the loop: \${i} eq $DO->{FOREACH}->{lastIfi}~);
    						last FOREACH_LOOP;
    					}
    				}
    			}
    			$VAR{i} = '';
    			
    			mlog($TT, qq~FOREACH executed. Results: [Ok]~);
    		}
    		
    		
    		if ( $DO->{FOREACH_NUMBER} ) {
    			mlog($TT, qq~Starting to execute FOREACH_NUMBER~);
    			
    			$DO->{FOREACH_NUMBER}->{initRange} = replaceSpecChar($DO->{FOREACH_NUMBER}->{initRange});
    			$DO->{FOREACH_NUMBER}->{endRange} = replaceSpecChar($DO->{FOREACH_NUMBER}->{endRange});
    			
    			FOREACH_LOOP: foreach my $i ( $DO->{FOREACH_NUMBER}->{initRange} .. $DO->{FOREACH_NUMBER}->{endRange} ) {
    				$VAR{n} = $i;
    				
    				# ## debug
    				# print $VAR{n}, "\n";
    				
    				runDO($DO->{FOREACH_NUMBER}->{DO}, $TT);
    				if ( $DO->{FOREACH_NUMBER}->{lastIfn} ) {
    					if ( $VAR{n} eq $DO->{FOREACH_NUMBER}->{lastIfn} ) {
    						mlog($TT, qq~Coming out of the loop: \${n} eq $DO->{FOREACH_NUMBER}->{lastIfn}~);
    						last FOREACH_LOOP;
    					}
    				}
    			}
    			$VAR{n} = '';
    			
    			mlog($TT, qq~FOREACH_NUMBER executed. Results: [Ok]~);
    		}
    		
    		
    		if ( $DO->{AUTOBOT} ) {
    			my $JsonVars = replaceSpecChar($DO->{AUTOBOT}->{JsonVars});
    			
    			$JsonVars =~ s/\r/ /g;
    			$JsonVars =~ s/\n/ /g;
    			
    			$VAR{ $DO->{AUTOBOT}->{catchVarName} } = `$RealBin/yaomiqui.pl '$TT' '$DO->{AUTOBOT}->{idAutoBot}' '$JsonVars' 2>/dev/null`;
    			$VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/^\n//g;
    			$VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/\n$//g;
    			
    			mlog($TT, qq~AutoBot [<a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$DO->{AUTOBOT}->{idAutoBot}" target="_blank">$DO->{AUTOBOT}->{idAutoBot}</a>] Executed. Results: [$VAR{ $DO->{AUTOBOT}->{catchVarName} }]~);
    		}
    		
    		
    		if ( $DO->{SendEMAIL} ) {
    			$VAR{Error} = '';
    			if ( $DO->{SendEMAIL}->{Subject} and $DO->{SendEMAIL}->{From} and $DO->{SendEMAIL}->{To} and $DO->{SendEMAIL}->{Type} and $DO->{SendEMAIL}->{Body} ) {
    				
    				$DO->{SendEMAIL}->{Subject} = replaceSpecChar($DO->{SendEMAIL}->{Subject});
    				$DO->{SendEMAIL}->{From} = replaceSpecChar($DO->{SendEMAIL}->{From});
    				$DO->{SendEMAIL}->{To} = replaceSpecChar($DO->{SendEMAIL}->{To});
    				$DO->{SendEMAIL}->{Body} = replaceSpecChar($DO->{SendEMAIL}->{Body});
    				# $DO->{SendEMAIL}->{Body} =~ s/\r//g;
    				# $DO->{SendEMAIL}->{Body} =~ s/\n//g;
    				
    				$DO->{SendEMAIL}->{From} =~ s/\\//g;
    				$DO->{SendEMAIL}->{To} =~ s/\\//g;
    				
    				if ( $DO->{SendEMAIL}->{From} =~ /\@/ and $DO->{SendEMAIL}->{To} =~ /\@/ ) {
    					use MIME::Lite;
    					my $msg = MIME::Lite->new(
    								Subject => $DO->{SendEMAIL}->{Subject},
    								From    => $DO->{SendEMAIL}->{From},
    								To      => $DO->{SendEMAIL}->{To},
    								Type    => $DO->{SendEMAIL}->{Type},
    								Data    => qq~$DO->{SendEMAIL}->{Body}~
    								# Data    => $DO->{SendEMAIL}->{Body}
    							);
    					$msg->attr('content-type.charset' => 'UTF-8');
    					
    					# $msg->send();
    					eval { $msg->send() };
    					$VAR{Error} = "MIME::Lite->send failed: $@" if $@;
    					
    					my $results = $msg->last_send_successful();
    					$results = 'Ok' if $results == 1;
    					mlog($TT, qq~SendEMAIL Executed. Results: [$results]~);
    				} else {
    					$VAR{Error} = qq~Error: Some data is wrong [$DO->{SendEMAIL}->{From} or $DO->{SendEMAIL}->{To}]~;
    					mlog($TT, qq~SendEMAIL NOT Executed. Error: Some data is wrong [$DO->{SendEMAIL}->{From} or $DO->{SendEMAIL}->{To}]~);
    				}
    			} else {
    				$VAR{Error} = qq~Error: Some data is missing [Subject, From, To, Type or Body]~;
    				mlog($TT, qq~SendEMAIL NOT Executed. Error: Some data is missing [Subject, From, To, Type or Body]~);
    			}
    		}
    		
    		
    		if ( $DO->{IntegerArray} ) {
    			for my $i ( $DO->{IntegerArray}->{initRange} .. $DO->{IntegerArray}->{endRange} ) {
    				push @{ $VAR{ $DO->{IntegerArray}->{arrayName} } }, $i;
    			}
    			
    			mlog($TT, qq~Array [$DO->{IntegerArray}->{arrayName}] created (from $DO->{IntegerArray}->{initRange} to $DO->{IntegerArray}->{endRange})~);
    		}
    		
    		
    		if ( $DO->{Sleep} ) {
    			mlog($TT, qq~Sleeping $DO->{Sleep}->{seconds} seconds~);
    			sleep ($DO->{Sleep}->{seconds});
    			mlog($TT, qq~Waking up~);
    		}
    		
    		
    		if ( $DO->{LOGING} ) {
    			
    			# ## debug
    			# print "LOGIN:\n" . Dumper($DO->{LOGING}) . "\n";
    			
    			runLOGING($DO->{LOGING}->{comment}, $TT);
    		}
    		
    		
    		if ( $DO->{END} ) {
    			runEND($DO->{END}->{value}, $TT);
    		}
    		
    		
    		if ( $DO->{RETURN} ) {
    			runRETURN($DO->{RETURN}->{value}, $TT, $AutoBot);
    		}
    		
    		
    			####	waterfall depth
    			if ( exists $DO->{IF} ) {
    				foreach my $i ( 0 .. $#{$DO->{IF}->{VAR}} ) {
    					my $catchInitIF = 0;
    					
    					# ## debug
    					# print "Dumper DO-IF-VAR:\n" . Dumper($DO->{IF}->{VAR}->[$i]) . "\n";
    					# print "Dumper DO-IF:\n" . Dumper($DO->{IF}->{VAR}) . "\n";
    					
    					my $name = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{name}); # to be frienldy next line
    					my $value = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{value});
    					
    					# ## debug
    					# print "RAW: $DO->{IF}->{VAR}->[$i]->{name} <-> $DO->{IF}->{VAR}->[$i]->{value}\n";
    					# print "SUS: $name <-> $value\n";
    					
    					$catchInitIF = compareVAR($name, $DO->{IF}->{VAR}->[$i]->{compare}, $value, $TT);
    					
    					# ## debug
    					# print "catchInitIF: " . $catchInitIF . "\n";
    					
    					if ( $catchInitIF ) {
    						if ( $DO->{IF}->{VAR}->[$i]->{DO} ) {
    							
    							# ## debug
    							# print "DO:\n" . Dumper($DO->{IF}->{VAR}->[$i]->{DO}) . "\n";
    							
    							runDO($DO->{IF}->{VAR}->[$i]->{DO}, $TT);
    						}
    						else {
    							
    							# ## debug
    							# print "IF:\n" . Dumper($DO->{IF}) . "\n";
    							
    							if ( $DO->{IF}->{DO}->{LOGING} ) {
    								my $comment = replaceSpecChar($DO->{IF}->{DO}->{LOGING}->{comment});
    								runLOGING($comment, $TT);
    							}
    							if ( $DO->{IF}->{DO}->{END} ) {
    								my $value = replaceSpecChar($DO->{IF}->{DO}->{END}->{value});
    								runEND($value, $TT);
    							}
    							elsif ( $DO->{IF}->{DO}->{RETURN} ) {
    								my $value = replaceSpecChar($DO->{IF}->{DO}->{RETURN}->{value});
    								runRETURN($value, $TT, $AutoBot);
    							}
    						}
    						
    					}
    				}
    			}
    			elsif ( exists $DO->{DO} ) {
    				runDO($DO->{DO}, $TT);
    			}
    			
    			## FINISH TO EXECUTE ALL OF DO FUNCTION
    		
    		
    		
    		
    		
    		## Timeout function continues
    		alarm 0;
    	};
    	
    	if ( $@ eq "timeout\n" ) {
    		`rm -f /tmp/*.err >/dev/null 2>&1`;
    		
    		$VAR{Error} = qq~TIMEOUT REACHED. \${TIMEOUT} var was configured to ($VAR{TIMEOUT} seconds)~;
    		mlog($TT, qq~TIMEOUT REACHED. \${TIMEOUT} var was configured to ($VAR{TIMEOUT} seconds)~);
    		
    		if ( $VENV{STATUS_AFTER_TIMEOUT} ) {
    			mlog($TT, qq~Ticket automatically closed as $VENV{STATUS_AFTER_TIMEOUT} by Timeout policies~);
    			my $policy = $AutoBot ? 'Timeout policies' : 'Internal process when no AutoBot catching it';
    			engineLog("WARN  :: $TT : Ticket automatically closed as $VENV{STATUS_AFTER_TIMEOUT} by $policy ($VAR{TIMEOUT} seconds)");
    			runEND($VENV{STATUS_AFTER_TIMEOUT}, $TT);
    		}
    	}
    	## Timeout function ends
    }

}


sub compareVAR {
    my ($name, $comparator, $value, $TT, $no_log) = @_;
    
    if ( $name =~ /^\$\{.+\}$/ ) {
    	$name =~ s/\$|\{|\}|\s//g;
    	$VAR{$name} = $value;
    }
    
    if ( $comparator eq 'exists' ) {
    	if ( $name ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
    elsif ( $comparator eq 'notexist' ) {
    	unless ( $name ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
    elsif ( $comparator eq 'contains' ) {
    	if ( $value =~ /\|/ ) {
    		foreach ( split(/\|/, $value ) ) {
    			if ( $name =~ /$_/ ) {
    				mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    				return 1;
    			}
    		}
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	} else {
    		if ( $name =~ /$value/ ) {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    			return 1;
    		} else {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    			return 0;
    		}
    		
    	}
    }
    elsif ( $comparator eq 'notcontain' ) {
    	if ( $value =~ /\|/ ) {
    		foreach ( split(/\|/, $value ) ) {
    			if ( $name =~ /$_/ ) {
    				mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    				return 0;
    			}
    		}
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		if ( $name =~ /$value/ ) {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    			return 0;
    		} else {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    			return 1;
    		}
    		
    	}
    }
    elsif ( $comparator eq 'startsw' ) {
    	if ( $value =~ /\|/ ) {
    		foreach ( split(/\|/, $value ) ) {
    			if ( $name =~ /^$_/ ) {
    				mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    				return 1;
    			}
    		}
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	} else {
    		if ( $name =~ /^$value/ ) {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    			return 1;
    		} else {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    			return 0;
    		}
    		
    	}
    }
    elsif ( $comparator eq 'notstartsw' ) {
    	if ( $value =~ /\|/ ) {
    		foreach ( split(/\|/, $value ) ) {
    			unless ( $name =~ /^$_/ ) {
    				mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    				return 1;
    			}
    		}
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	} else {
    		unless ( $name =~ /^$value/ ) {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    			return 1;
    		} else {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    			return 0;
    		}
    		
    	}
    }
    elsif ( $comparator eq 'endsw' ) {
    	if ( $value =~ /\|/ ) {
    		foreach ( split(/\|/, $value ) ) {
    			if ( $name =~ /$_$/ ) {
    				mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    				return 1;
    			}
    		}
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	} else {
    		if ( $name =~ /$value$/ ) {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    			return 1;
    		} else {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    			return 0;
    		}
    		
    	}
    }
    elsif ( $comparator eq 'notendsw' ) {
    	if ( $value =~ /\|/ ) {
    		foreach ( split(/\|/, $value ) ) {
    			unless ( $name =~ /$_$/ ) {
    				mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    				return 1;
    			}
    		}
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	} else {
    		unless ( $name =~ /$value$/ ) {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    			return 1;
    		} else {
    			mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    			return 0;
    		}
    		
    	}
    }
    elsif ( $comparator eq 'eq' ) {
    	if ( $name eq $value ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
    elsif ( $comparator eq 'ne' ) {
    	if ( $name ne $value ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
    elsif ( $comparator eq 'isempty' ) {
    	#~ if ( length $name == 0 ) {
    	if ( $name eq '' ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
    elsif ( $comparator eq 'lt' ) {
    	if ( $name lt $value ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
    elsif ( $comparator eq 'gt' ) {
    	if ( $name gt $value ) {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = true)~) unless $no_log;
    		return 1;
    	} else {
    		mlog($TT, qq~Comparison: IF [$name] $comparator [$value] (RETURN = false)~) unless $no_log;
    		return 0;
    	}
    }
}


sub forceDOarray {
    my $string = shift;
    $string =~ /<AUTO>(<ON>.+<\/ON>)(.+)<\/AUTO>/;
    my $on = $1;
    $string = $2;
    $string =~ s/<DO>//g;
    $string =~ s/<\/DO>//g;
    $string =~ s/<IF>/<DO><IF>/g;
    $string =~ s/<\/IF>/<\/IF><\/DO>/g;
    $string =~ s/<execLinuxCommand/<DO><execLinuxCommand/g;
    $string =~ s/<\/execLinuxCommand>/<\/execLinuxCommand><\/DO>/g;
    $string =~ s/<execRemoteLinuxCommand/<DO><execRemoteLinuxCommand/g;
    $string =~ s/<\/execRemoteLinuxCommand>/<\/execRemoteLinuxCommand><\/DO>/g;
    $string =~ s/<execRemoteWindowsCommand/<DO><execRemoteWindowsCommand/g;
    $string =~ s/<\/execRemoteWindowsCommand>/<\/execRemoteWindowsCommand><\/DO>/g;
    $string =~ s/<JSONtoVar/<DO><JSONtoVar/g;
    $string =~ s/<\/JSONtoVar>/<\/JSONtoVar><\/DO>/g;
    $string =~ s/<SetVar/<DO><SetVar/g;
    $string =~ s/<\/SetVar>/<\/SetVar><\/DO>/g;
    $string =~ s/<DecodePWDtoVar/<DO><DecodePWDtoVar/g;
    $string =~ s/<\/DecodePWDtoVar>/<\/DecodePWDtoVar><\/DO>/g;
    $string =~ s/<SplitVar /<DO><SplitVar /g;
    $string =~ s/<FOREACH/<DO><FOREACH/g;
    $string =~ s/<\/FOREACH>/<\/FOREACH><\/DO>/g;
    $string =~ s/<\/FOREACH_NUMBER>/<\/FOREACH_NUMBER><\/DO>/g;
    $string =~ s/<AUTOBOT/<DO><AUTOBOT/g;
    $string =~ s/<\/AUTOBOT>/<\/AUTOBOT><\/DO>/g;
    $string =~ s/<SendEMAIL/<DO><SendEMAIL/g;
    $string =~ s/<\/SendEMAIL>/<\/SendEMAIL><\/DO>/g;
    $string =~ s/<Sleep /<DO><Sleep /g;
    $string =~ s/<IntegerArray /<DO><IntegerArray /g;
    $string =~ s/<LOGING /<DO><LOGING /g;
    $string =~ s/<RETURN /<DO><RETURN /g;
    $string =~ s/<END /<DO><END /g;
    $string =~ s!/>!/></DO>!g;
    return '<AUTO>' . $on . $string . '</AUTO>';
}


sub mlog {
    my ($ticketNumber, $log) = @_;
    # $log =~ s/\'/\"/g;
    my $sysdate = sysdate();
    
    if ( $ticketNumber ne 'NDF00000001' ) {
    	connected();
    	my $insert_string = "INSERT INTO log (numberTicket, insertDate, log) VALUES ('$ticketNumber', '$sysdate', ?)";
    	my $sth = $dbh->prepare("$insert_string");
    	$sth->execute($log) or return;
    	$sth->finish;
    	$dbh->disconnect if ($dbh);
    }
    # else {
    	# print "$sysdate : $ticketNumber : $log\n";
    # }
}

sub engineLog {
    my $msg = shift;
    my $date = date_nospace();
    my $sysdate = sysdate();
    my $engine_log_dir = $VENV{engine_log_dir};
    
    if ( $ticketNumber ne 'NDF00000001' ) {
    	open my $ELOG, ">>", "$engine_log_dir/engine-$date.log";
    	print $ELOG qq~$sysdate :: $msg\n~;
    	close $ELOG;
    	# engineLog("ERROR :: TT : ");
    	# engineLog("INFO  :: TT : ");
    	# engineLog("WARN  :: TT : ");
    }
    # else {
    	# print qq~$sysdate :: $msg\n~;
    # }
}

sub connected {
    use DBI;
    # $dbh = DBI->connect("DBI:mysql:$VENV{'DB'}:$VENV{'DBHOST'}", $VENV{'DBUSER'}, $VENV{'DBPASSWD'}) or print "Error... $DBI::errstr mysql_error()<br>";
    $dbh = DBI->connect("DBI:mysql:$VENV{'DB'}:$VENV{'DBHOST'}", $VENV{'DBUSER'}, $VENV{'DBPASSWD'}) or engineLog("ERROR :: $ticketNumber : MySQL Connect: " . $DBI::errstr) and exit;
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
    
    use DBI;
    my $dbh = DBI->connect("DBI:mysql:$VARS{'DB'}:$VARS{'DBHOST'}", $VARS{'DBUSER'}, $VARS{'DBPASSWD'}) or die "Error... $DBI::errstr mysql_error()<br>";
    my $sth = $dbh->prepare("SELECT varName, varValue FROM configVars");
    $sth->execute();
    my $cnfVar = $sth->fetchall_arrayref;
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    for my $i ( 0 .. $#{$cnfVar} ) {
    	$VARS{ $cnfVar->[$i][0] } = $cnfVar->[$i][1] if $cnfVar->[$i][1];
    }
    
    return %VARS;
}

sub get_add_env_vars {
    my %VARS;
    
    connected();
    my $sth = $dbh->prepare("SELECT varName, varValue FROM environmentVars");
    $sth->execute();
    my $cnfVar = $sth->fetchall_arrayref;
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    for my $i ( 0 .. $#{$cnfVar} ) {
    	$VARS{ $cnfVar->[$i][0] } = $cnfVar->[$i][1] if $cnfVar->[$i][1];
    }
    
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
