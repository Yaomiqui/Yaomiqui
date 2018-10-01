#!/usr/bin/perl
########################################################################
# Yaomiqui is a Web UI for Automation
# This is the main ENGINE
# 
# Written in freestyle Perl-CGI + Apache + MySQL + Javascript + CSS
# 
# Copyright (C) 2018 Hugo Maza Moreno
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
use FindBin qw($RealBin);
use strict;
use Net::OpenSSH;
use Data::Dumper;

our ($ticketNumber, $dbh, %VAR, $jsonCode);
my %VENV = get_vars();

if ( $ARGV[0] ) {
	$ticketNumber = $ARGV[0];
} else {
	exit;
}

my $specAutoBot;
$specAutoBot = " AND idAutoBot = '$ARGV[1]'" if $ARGV[1];

connected();
my $sth = $dbh->prepare("SELECT * FROM autoBot WHERE active = '1'$specAutoBot ORDER BY idAutoBot ASC");
$sth->execute();
my $AB = $sth->fetchall_arrayref;
$sth->finish;

my $sth = $dbh->prepare("SELECT * FROM ticket WHERE numberTicket = '$ticketNumber'");
$sth->execute();
my @TTS = $sth->fetchrow_array;
$sth->finish;
$dbh->disconnect if ($dbh);

my $jsonCode = $ARGV[2] ? $ARGV[2] : $TTS[10];
$jsonCode =~ s/\\/\\\\/g;
$jsonCode =~ s/\r//g;
$jsonCode =~ s/\n//g;

# ## debug
# print "JSONCODE:\n" . $jsonCode . "\n";

$TTS[1] = $ARGV[0] unless $TTS[1];

my $json = eval { decode_json $jsonCode };		# my $json = eval { from_json($jsonCode) };

# ## debug
# print "JSON: " . Dumper($json) . "\n";

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
		
		$AB->[$i][6] = forceDOarray($AB->[$i][6]);
		
		# ## debug
		# print "XML:\n" . qq~$AB->[$i][6]~ . "\n\n";
		
		my $xml = XML::Simple->new;
		
		my $aBot = $xml->XMLin($AB->[$i][6],
		KeyAttr => { NoEscape => 1 },
		ForceArray => [ 'VAR', 'DO' ],
		ContentKey => '-content' ) or next;
		
			# ## debug
			# print "JSON START:\n";
			# print Dumper($aBot) . "\n";
			# print "JSON END:\n";
			# print Dumper($aBot->{ON}->{VAR}->[0], $aBot->{ON}->{VAR}->[1], $aBot->{ON}->{VAR}->[2]) . "\n";
		
		my $catch = 0;
		
		foreach my $i ( 0 .. $#{$aBot->{ON}->{VAR}} ) {
			
			## debug
			# print Dumper($aBot->{ON}->{VAR}->[$i]) . "\n";
			
			my $name = $aBot->{ON}->{VAR}->[$i]->{name}; # to be frienldy next line
			$catch = compareVAR($VAR{$name}, $aBot->{ON}->{VAR}->[$i]->{compare}, $aBot->{ON}->{VAR}->[$i]->{value}, $VAR{number}, 'no_log');
			
			# ## debug
			# print "\$catch = $catch\n";
			
			next AUTOBOT unless $catch;		## 	THIS TICKET DOES NOT APLIES FOR THIS AUTOBOT
		}
		
		
		if ( $catch ) {
			
			## debug
			# print "GOTCHA!! I have ticket '$TTS[1]' to this Autobot\n\n";
			
			mlog($TTS[1], qq~Ticket was caught by Autobot ID: [<a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$AB->[$i][0]" target="_blank">$AB->[$i][0]</a>]~) if $ticketNumber ne '00000000';
			
			unless ( $ARGV[1] ) {
				connected();
				my $sth = $dbh->prepare("UPDATE ticket SET idAutoBotCatched='$AB->[$i][0]' WHERE numberTicket='$ticketNumber'");
				$sth->execute();
				$sth->finish;
				$dbh->disconnect if $dbh;
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
								runRETURN($value, $VAR{number});
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
			
			exit;
		}
	}
	
} else {
	print "Error: Not Valid JSON";
	exit;
}




exit;

sub runLOGING {
	my ($comment, $TT) = @_;
	$comment = replaceSpecChar($comment);
	
	mlog($TT, qq~NOTE: [$comment]~);
}

sub runEND {
	my ($value, $TT) = @_;
	my $sysdate = sysdate();
	
	$value = replaceSpecChar($value);
	
	connected();
	my $sth = $dbh->prepare("UPDATE ticket SET finalDate = '$sysdate', finalState = '$value' WHERE numberTicket='$TT'");
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	mlog($TT, qq~Final State: [$value]~);
	my $pid = $$;
	`kill -9 $pid`;
	exit;
}

sub runRETURN {
	my ($value, $TT) = @_;
	$value = replaceSpecChar($value);
	
	print $value;
	
	mlog($TT, qq~Returned value: [$value]~);
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
		
		if ( $DO->{execLinuxCommand} ) {
			undef $VAR{Error};
			
			my $linuxCommand = replaceSpecChar($DO->{execLinuxCommand}->{command});
			$linuxCommand =~ s/\\/\\\\/g;
			
			my $linerrfile = '/tmp/' . $TT . '.err';
			
			$VAR{ $DO->{execLinuxCommand}->{catchVarName} } = `$linuxCommand 2>$linerrfile`;
			$VAR{ $DO->{execLinuxCommand}->{catchVarName} } =~ s/^\n//g;
			$VAR{ $DO->{execLinuxCommand}->{catchVarName} } =~ s/\n$//g;
			
			$VAR{Error} = `cat $linerrfile 2>/dev/null`;
			$VAR{Error} =~ s/^\n//g;
			$VAR{Error} =~ s/\n$//g;
			
			## debug
			# print "RESULTS:\n" . $VAR{ $DO->{execLinuxCommand}->{catchVarName} } . "\n\n";
			
			unless ( $VAR{Error} ) {
				mlog($TT, qq~Linux Command [$linuxCommand] Executed on Local Server [localhost]. Results: [$VAR{ $DO->{execLinuxCommand}->{catchVarName} }]~ . "\nError: []");
			} else {
				mlog($TT, qq~Linux Command [$linuxCommand] Executed on Local Server [localhost]. Results: [$VAR{ $DO->{execLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
			}
			
			unlink "$linerrfile";
		}
		
		
		if ( $DO->{execRemoteLinuxCommand} ) {
			undef $VAR{Error};
			my $remoteLinuxCommand;
			if ( $DO->{execRemoteLinuxCommand}->{publicKey} ) {
				$remoteLinuxCommand = replaceSpecChar($DO->{execRemoteLinuxCommand}->{command});
				# $remoteLinuxCommand =~ s/'/'\\''/g;
				$DO->{execRemoteLinuxCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteUser});
				$DO->{execRemoteLinuxCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteHost});
				$DO->{execRemoteLinuxCommand}->{publicKey} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{publicKey});
				
				my $ssh = Net::OpenSSH->new($DO->{execRemoteLinuxCommand}->{remoteHost},
					user		=> $DO->{execRemoteLinuxCommand}->{remoteUser},
					key_path	=> $DO->{execRemoteLinuxCommand}->{publicKey},
					master_opts => [-o => "StrictHostKeyChecking=no", -o => "LogLevel=QUIET"]
				);
				
				unless ( $ssh->error ) {
					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } = $ssh->capture2($remoteLinuxCommand);
					
					unless ( $ssh->error ) {
						mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: []");
					}
					else {
						$VAR{Error} = $ssh->error;
						mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
					}
				}
				else {
					$VAR{Error} = $ssh->error;
					mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
				}
				## END OF execRemoteLinuxCommand WITH PUBLIC KEY
			}
			else {
				undef $VAR{Error};
				$remoteLinuxCommand = replaceSpecChar($DO->{execRemoteLinuxCommand}->{command});
				# $remoteLinuxCommand =~ s/'/'\\''/g;
				$DO->{execRemoteLinuxCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteUser});
				$DO->{execRemoteLinuxCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteHost});
				$DO->{execRemoteLinuxCommand}->{passwd} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{passwd});
				
				my $ssh = Net::OpenSSH->new($DO->{execRemoteLinuxCommand}->{remoteHost},
					user		=> $DO->{execRemoteLinuxCommand}->{remoteUser},
					password	=> $DO->{execRemoteLinuxCommand}->{passwd},
					master_opts => [-o => "StrictHostKeyChecking=no", -o => "LogLevel=QUIET"]
				);
				
				unless ( $ssh->error ) {
					$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } = $ssh->capture2($remoteLinuxCommand);
					
					unless ( $ssh->error ) {
						mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: []");
					}
					else {
						$VAR{Error} = $ssh->error;
						mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
					}
				}
				else {
					$VAR{Error} = $ssh->error;
					mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~ . "\nError: [$VAR{Error}]");
				}
				## END OF execRemoteLinuxCommand WITH USER AND PASSWORD
			}
		}
		
		
		if ( $DO->{execRemoteWindowsCommand} ) {
			undef $VAR{Error};
			my $remoteWindowsCommand = replaceSpecChar($DO->{execRemoteWindowsCommand}->{command});
			$remoteWindowsCommand =~ s/\'/\\\'/g;
			$remoteWindowsCommand =~ s/\r//g;
			$remoteWindowsCommand =~ s/\n//g;
			
			$DO->{execRemoteWindowsCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{remoteUser});
			$DO->{execRemoteWindowsCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{remoteHost});
			$DO->{execRemoteWindowsCommand}->{remotePasswd} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{passwd});
			$DO->{execRemoteWindowsCommand}->{remoteDomain} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{domain});
			
			$DO->{execRemoteWindowsCommand}->{remoteDomain} = $DO->{execRemoteWindowsCommand}->{remoteDomain} . '/' if $DO->{execRemoteWindowsCommand}->{remoteDomain};
			
			my $winerrfile = '/tmp/' . $TT . '.err';
			
			$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } = `winexe -k $DO->{execRemoteWindowsCommand}->{useKerberos} -U '$DO->{execRemoteWindowsCommand}->{remoteDomain}$DO->{execRemoteWindowsCommand}->{remoteUser}\%$DO->{execRemoteWindowsCommand}->{remotePasswd}' //$DO->{execRemoteWindowsCommand}->{remoteHost} '$remoteWindowsCommand' 2>$winerrfile`;
			$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } =~ s/^\n//g;
			$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } =~ s/\n$//g;
			
			## debug
			# print qq~COMMAND LINE:winexe -U '$DO->{execRemoteWindowsCommand}->{remoteDomain}$DO->{execRemoteWindowsCommand}->{remoteUser}\%$DO->{execRemoteWindowsCommand}->{remotePasswd}' //$DO->{execRemoteWindowsCommand}->{remoteHost} '$remoteWindowsCommand'\n~;
			
			$VAR{Error} = `cat $winerrfile 2>/dev/null`;
			$VAR{Error} =~ s/^\n//g;
			$VAR{Error} =~ s/\n$//g;
			
			unless ( $VAR{Error} ) {
				mlog($TT, qq~Remote Windows Command [$remoteWindowsCommand] Executed on Remote Server [$DO->{execRemoteWindowsCommand}->{remoteHost}].\nResults: [$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} }]~ . "\nError: []");
			}
			else {
				mlog($TT, qq~Remote Windows Command [$remoteWindowsCommand] Executed on Remote Server [$DO->{execRemoteWindowsCommand}->{remoteHost}].\nResults: [$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} }]~ . "\nError: [" . $VAR{Error} . "]");
			}
			
			unlink "$winerrfile";
		}
		
		
		if ( $DO->{JSONtoVar} ) {
			undef $VAR{Error};
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
			
			@{ $VAR{ $DO->{SplitVar}->{arrayName} } } = split(/$separator/, replaceSpecChar($DO->{SplitVar}->{inputVarName}));
			
			# ## debug
			# print "Split Dumper: \n" . Dumper($VAR{ $DO->{SplitVar}->{arrayName} }) . "\n";
			
			mlog($TT, qq~Splitting variable [$DO->{SplitVar}->{inputVarName}] to Array Variable [$DO->{SplitVar}->{arrayName}]. Results: [Ok]~);
		}
		
		
		if ( $DO->{FOREACH} ) {
			mlog($TT, qq~Starting to execute FOREACH~);
			
			$DO->{FOREACH}->{arrayName} =~ s/\$|\{|\}|\s//g;
			foreach my $i ( @{ $VAR{ $DO->{FOREACH}->{arrayName} } } ) {
				$VAR{i} = $i;
				
				# ## debug
				# print $VAR{i}, "\n";
				
				runDO($DO->{FOREACH}->{DO}, $TT);
			}
			
			mlog($TT, qq~FOREACH executed. Results: [Ok]~);
		}
		
		
		if ( $DO->{FOREACH_NUMBER} ) {
			mlog($TT, qq~Starting to execute FOREACH_NUMBER~);
			
			foreach my $i ( $DO->{FOREACH_NUMBER}->{initRange} .. $DO->{FOREACH_NUMBER}->{endRange} ) {
				$VAR{i} = $i;
				
				# ## debug
				# print $VAR{i}, "\n";
				
				runDO($DO->{FOREACH_NUMBER}->{DO}, $TT);
			}
			
			mlog($TT, qq~FOREACH_NUMBER executed. Results: [Ok]~);
		}
		
		
		if ( $DO->{AUTOBOT} ) {
			my $JsonVars = replaceSpecChar($DO->{AUTOBOT}->{JsonVars});
			
			$JsonVars =~ s/\r/ /g;
			$JsonVars =~ s/\n/ /g;
			
			$VAR{ $DO->{AUTOBOT}->{catchVarName} } = `$RealBin/yaomiqui.pl '$TT' '$DO->{AUTOBOT}->{idAutoBot}' '$JsonVars' 2>&1`;
			$VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/^\n//g;
			$VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/\n$//g;
			
			mlog($TT, qq~AutoBot [<a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$DO->{AUTOBOT}->{idAutoBot}" target="_blank">$DO->{AUTOBOT}->{idAutoBot}</a>] Executed. Results: [$VAR{ $DO->{AUTOBOT}->{catchVarName} }]~);
		}
		
		
		if ( $DO->{SendEMAIL} ) {
			undef $VAR{Error};
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
			sleep ($DO->{Sleep}->{seconds});
			mlog($TT, qq~Sleeping $DO->{Sleep}->{seconds} seconds~);
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
			runRETURN($DO->{RETURN}->{value}, $TT);
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
								runRETURN($value, $TT);
							}
						}
						
					}
				}
			}
			elsif ( exists $DO->{DO} ) {
				runDO($DO->{DO}, $TT);
			}
	
	}

}


sub compareVAR {
	my ($name, $comparator, $value, $TT, $no_log) = @_;
	
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
	
	print "$sysdate : $ticketNumber : $log\n" if  $ticketNumber eq '00000000';
	
	if ( $ticketNumber ne '00000000' ) {
		connected();
		# my $insert_string = "INSERT INTO log (numberTicket, insertDate, log) VALUES ('$ticketNumber', '$sysdate', '$log')";
		my $insert_string = "INSERT INTO log (numberTicket, insertDate, log) VALUES ('$ticketNumber', '$sysdate', ?)";
		my $sth = $dbh->prepare("$insert_string");
		$sth->execute($log);
		$sth->finish;
		$dbh->disconnect if ($dbh);
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

sub sysdate {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	$fecha[4] ++;
	@fecha = map { if ($_ < 10) { $_ = "0$_"; }else{ $_ } } @fecha;
						#year	mon		 mday		hour	min		sec
	return my $sysdate = "$fecha[5]-$fecha[4]-$fecha[3] $fecha[2]:$fecha[1]:$fecha[0]";
}
