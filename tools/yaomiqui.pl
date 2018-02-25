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

my $jsonCode = $ARGV[2] ? $ARGV[2] : $TTS[9];

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
		my $xml = XML::Simple->new;
		my $aBot = $xml->XMLin($AB->[$i][6],
		# KeyAttr => {item => 'name'},
		# ForceArray => [ 'item' ],
		KeyAttr => [ 'VAR' ],
		ForceArray => [ 'VAR' ],
		ContentKey => '-content' )  or next;
		
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
			
			mlog($TTS[1], qq~Ticket was catched by Autobot ID: <a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$AB->[$i][0]" target="_blank">[$AB->[$i][0]]</a>~) if $ticketNumber ne '00000000';
			
			unless ( $ARGV[1] ) {
				connected();
				my $sth = $dbh->prepare("UPDATE ticket SET idAutoBotCatched='$AB->[$i][0]' WHERE numberTicket='$ticketNumber'");
				$sth->execute();
				$sth->finish;
				$dbh->disconnect if $dbh;
			}
			
			####	waterfall depth
			if ( exists $aBot->{IF} ) {
				my $catchInitIF = 0;
				foreach my $i ( 0 .. $#{$aBot->{IF}->{VAR}} ) {
					
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
							if ( $aBot->{IF}->{VAR}->[$i]->{LOGING} ) {
								my $comment = replaceSpecChar($aBot->{IF}->{VAR}->[$i]->{LOGING}->{comment});
								runLOGING($comment, $VAR{number});
							}
							if ( $aBot->{IF}->{VAR}->[$i]->{END} ) {
								my $value = replaceSpecChar($aBot->{IF}->{VAR}->[$i]->{END}->{value});
								runEND($value, $VAR{number});
							}
							elsif ( $aBot->{IF}->{VAR}->[$i]->{RETURN} ) {
								my $value = replaceSpecChar($aBot->{IF}->{VAR}->[$i]->{RETURN}->{value});
								runRETURN($value, $VAR{number});
							}
						}
						
					}
				}
			}
			
			if ( exists $aBot->{DO} ) {
				
				# ## debug
				# print "TICKET: " . $VAR{number} . "\nDUMPER:\n" . Dumper($aBot->{DO}) , "\n";
				
				runDO($aBot->{DO}, $VAR{number});
			}
			####
			
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
	
	# ## debug
	# print $comment , "\n";
	
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
	
	mlog($TT, qq~Value Returned: [$value]~);
	# print $value;
	exit;
}

sub replaceSpecChar {
	my $line = shift;
	
	$line =~ s!\[quote\]!\'!g;
	$line =~ s!\[quotes\]!\"!g;
	$line =~ s!\[gt\]!\>!g;
	$line =~ s!\[lt\]!\<!g;
	$line =~ s!\[semi\]!\;!g;
	$line =~ s!\[comm\]!\`!g;
	$line =~ s!\$\{([^\$]+)\}!$VAR{$1}!g;
	
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
	foreach my $el ( @T ) {
		$content = $VAR{$el};
	}
	
	$bef = replaceHash($bef) if $bef =~ /\$\[\[/;
	$aft = replaceHash($aft) if $aft =~ /\$\[\[/;
	
	$line = $bef . $content . $aft;
	
	return $line;
}

sub runDO {
	my ($DO, $TT) = @_;
	my @output;
	
	if ( $DO->{execLinuxCommand} ) {
		my $linuxCommand = replaceSpecChar($DO->{execLinuxCommand}->{command});
		$VAR{ $DO->{execLinuxCommand}->{catchVarName} } = `$linuxCommand 2>&1`;
		$VAR{ $DO->{execLinuxCommand}->{catchVarName} } =~ s/\n*$//g;
		
		mlog($TT, qq~Local Linux Command [$linuxCommand] Executed. Results: [$VAR{ $DO->{execLinuxCommand}->{catchVarName} }]~);
	}
	
	elsif ( $DO->{execRemoteLinuxCommand} ) {
		my $remoteLinuxCommand;
		if ( $DO->{execRemoteLinuxCommand}->{publicKey} ) {
			$remoteLinuxCommand = replaceSpecChar($DO->{execRemoteLinuxCommand}->{command});
			$remoteLinuxCommand =~ s/\'/\\\'/;
			$DO->{execRemoteLinuxCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteUser});
			$DO->{execRemoteLinuxCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteHost});
			$DO->{execRemoteLinuxCommand}->{publicKey} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{publicKey});
			
			$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } = `/usr/bin/ssh -o StrictHostKeyChecking=no -i $DO->{execRemoteLinuxCommand}->{publicKey} $DO->{execRemoteLinuxCommand}->{remoteUser}\@$DO->{execRemoteLinuxCommand}->{remoteHost} -t '$remoteLinuxCommand'`;
			
			# ## debug
			# print qq~/usr/bin/sshpass -p "$DO->{execRemoteLinuxCommand}->{passwd}" /usr/bin/ssh -o StrictHostKeyChecking=no $DO->{execRemoteLinuxCommand}->{remoteUser}\@$DO->{execRemoteLinuxCommand}->{remoteHost} -t '$remoteLinuxCommand' 2>&1~;
			
			# $VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } =~ s/\n//g;
		}
		else {
			$remoteLinuxCommand = replaceSpecChar($DO->{execRemoteLinuxCommand}->{command});
			$remoteLinuxCommand =~ s/\'/\\\'/;
			$DO->{execRemoteLinuxCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteUser});
			$DO->{execRemoteLinuxCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{remoteHost});
			$DO->{execRemoteLinuxCommand}->{passwd} = replaceSpecChar($DO->{execRemoteLinuxCommand}->{passwd});
			
			$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } = `/usr/bin/sshpass -p "$DO->{execRemoteLinuxCommand}->{passwd}" /usr/bin/ssh -o StrictHostKeyChecking=no $DO->{execRemoteLinuxCommand}->{remoteUser}\@$DO->{execRemoteLinuxCommand}->{remoteHost} -t '$remoteLinuxCommand'`;
			
			# ## debug
			# print qq~/usr/bin/sshpass -p "$DO->{execRemoteLinuxCommand}->{passwd}" /usr/bin/ssh -o StrictHostKeyChecking=no $DO->{execRemoteLinuxCommand}->{remoteUser}\@$DO->{execRemoteLinuxCommand}->{remoteHost} -t '$remoteLinuxCommand' 2>&1~;
			
			# $VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} } =~ s/\n//g;
		}
		
		mlog($TT, qq~Remote Linux Command [$remoteLinuxCommand] Executed on Remote Server [$DO->{execRemoteLinuxCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteLinuxCommand}->{catchVarName} }]~);
	}
	
	elsif ( $DO->{execRemoteWindowsCommand} ) {
		my $remoteWindowsCommand = replaceSpecChar($DO->{execRemoteWindowsCommand}->{command});
		$remoteWindowsCommand =~ s/\'/\\\'/;
		$DO->{execRemoteWindowsCommand}->{remoteUser} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{remoteUser});
		$DO->{execRemoteWindowsCommand}->{remoteHost} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{remoteHost});
		$DO->{execRemoteWindowsCommand}->{remotePasswd} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{passwd});
		$DO->{execRemoteWindowsCommand}->{remoteDomain} = replaceSpecChar($DO->{execRemoteWindowsCommand}->{domain});
		
		$DO->{execRemoteWindowsCommand}->{remoteDomain} = $DO->{execRemoteWindowsCommand}->{remoteDomain} . '/' if $DO->{execRemoteWindowsCommand}->{remoteDomain};
		
		$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } = `winexe -k $DO->{execRemoteWindowsCommand}->{useKerberos} -U '$DO->{execRemoteWindowsCommand}->{remoteDomain}$DO->{execRemoteWindowsCommand}->{remoteUser}\%$DO->{execRemoteWindowsCommand}->{remotePasswd}' //$DO->{execRemoteWindowsCommand}->{remoteHost} '$remoteWindowsCommand'`;
		
		# ## debug
		# print qq~COMMAND LINE:winexe -U '$DO->{execRemoteWindowsCommand}->{remoteDomain}$DO->{execRemoteWindowsCommand}->{remoteUser}\%$DO->{execRemoteWindowsCommand}->{remotePasswd}' //$DO->{execRemoteWindowsCommand}->{remoteHost} '$remoteWindowsCommand'\n~;
		# $VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} } =~ s/\n//g;
		
		mlog($TT, qq~Remote Windows Command [$remoteWindowsCommand] Executed on Remote Server [$DO->{execRemoteWindowsCommand}->{remoteHost}]. Results: [$VAR{ $DO->{execRemoteWindowsCommand}->{catchVarName} }]~);
	}
	
	
	if ( $DO->{AUTOBOT} ) {
		my $JsonVars = replaceSpecChar($DO->{AUTOBOT}->{JsonVars});
		$JsonVars = '{"data": {' . $JsonVars . '}}';
		$VAR{ $DO->{AUTOBOT}->{catchVarName} } = `$RealBin/yaomiqui.pl '$TT' '$DO->{AUTOBOT}->{idAutoBot}' '$JsonVars' 2>&1`;
		$VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/\n//g;
		# $VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/ok 1//;		# Test::JSON trash
		# $VAR{ $DO->{AUTOBOT}->{catchVarName} } =~ s/\# Tests were run but no plan was declared and done_testing.*$//;		# Test::JSON advertisment
		
		mlog($TT, qq~AutoBot [$DO->{AUTOBOT}->{idAutoBot}] Executed. Results: [$VAR{ $DO->{AUTOBOT}->{catchVarName} }]~);
	}
	
	
	if ( $DO->{JSONtoVar} ) {
		my $catchVarName = $DO->{JSONtoVar}->{catchVarName};
		my $JsonSource = replaceSpecChar($DO->{JSONtoVar}->{JsonSource});
		
		unless ( $DO->{JSONtoVar}->{JsonSource} =~ /^\$/ ) {
			my $json = eval { decode_json $JsonSource };
			if ( $json ) {
				%{$VAR{$catchVarName}} = %$json;
				
				# ## debug
				# print "sys_id:\n" . $VAR{$catchVarName}{ticket}{sys_id} . "\n";
				mlog($TT, qq~JSONtoVar [$catchVarName] Mapped. Results: [Ok]~);
			} else {
				# ## debug
				# print "Error: NOT VALID JSON\n";
				mlog($TT, qq~JSONtoVar [$catchVarName] Not Mapped. Results: [Error: JSON NOT VALID]~);
			}
		}
	}
	
	
	if ( $DO->{SetVar} ) {
		$DO->{SetVar}->{value} = replaceSpecChar($DO->{SetVar}->{value});
		$VAR{ $DO->{SetVar}->{name} } = $DO->{SetVar}->{value};
		
		mlog($TT, qq~Setting value [$DO->{SetVar}->{value}] to var [$DO->{SetVar}->{name}]. Results: [Ok]~);
	}
	
	
	if ( $DO->{SplitVar} ) {
		my $separator = $DO->{SplitVar}->{separator};
		$separator =~ s/comma/\,/;
		$separator =~ s/semicolon/\;/;
		$separator =~ s/pipe/\|/;
		$separator =~ s/nl/\n/;
		
		$VAR{ $DO->{SplitVar}->{inputVarName} } = replaceSpecChar($DO->{SplitVar}->{inputVarName});
		@{ $VAR{ $DO->{SplitVar}->{arrayName} } } = split(/$separator/, $VAR{ $DO->{SplitVar}->{inputVarName} });
		
		## debug
		print Dumper($VAR{ $DO->{SplitVar}->{arrayName} }) , "\n";
		
		mlog($TT, qq~Splitting variable [$DO->{SplitVar}->{inputVarName}] to Array Variable [$DO->{SplitVar}->{arrayName}]. Results: [Ok]~);
	}
	
	
	# if ( $DO->{SplitFile} ) {
		# 
	# }
	
	
	if ( $DO->{FOREACH} ) {
		for my $i ( 0 .. $#{ $VAR{ $DO->{FOREACH}->{arrayName} } } ) {
			$VAR{i} = $VAR{ $DO->{FOREACH}->{arrayName} }[$i];
			
			## debug
			# print $VAR{i}, "\n";
			# print Dumper($DO->{FOREACH}->{DO}), "\n";
			
			runDO($DO->{FOREACH}->{DO}, $TT);
		}
		
		mlog($TT, qq~FOREACH executed. Results: [Ok]~);
	}
	
	
	if ( $DO->{LOGING} ) {
		runLOGING($DO->{LOGING}->{comment}, $TT);
	}
	
	
	if ( $DO->{END} ) {
		runEND($DO->{END}->{value}, $TT);
	}
	elsif ( $DO->{RETURN} ) {
		runRETURN($DO->{RETURN}->{value}, $TT);
	}
	
	
			####	waterfall depth
			if ( exists $DO->{IF} ) {
				my $catchInitIF = 0;
				foreach my $i ( 0 .. $#{$DO->{IF}->{VAR}} ) {
					# print Dumper($DO->{IF}->{VAR}->[$i]) . "\n";
					my $name = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{name}); # to be frienldy next line
					my $value = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{value});
					
					# print "RAW: $DO->{IF}->{VAR}->[$i]->{name} <-> $DO->{IF}->{VAR}->[$i]->{value}\n";
					# print "SUS: $name <-> $value\n";
					
					$catchInitIF = compareVAR($name, $DO->{IF}->{VAR}->[$i]->{compare}, $value, $TT);
					
					if ( $catchInitIF ) {
						if ( $DO->{IF}->{VAR}->[$i]->{DO} ) {
							runDO($DO->{IF}->{VAR}->[$i]->{DO}, $TT);
						} else {
							if ( $DO->{IF}->{VAR}->[$i]->{LOGING} ) {
								my $comment = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{LOGING}->{comment});
								runLOGING($comment, $TT);
							}
							if ( $DO->{IF}->{VAR}->[$i]->{END} ) {
								my $value = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{END}->{value});
								runEND($value, $TT);
							}
							elsif ( $DO->{IF}->{VAR}->[$i]->{RETURN} ) {
								my $value = replaceSpecChar($DO->{IF}->{VAR}->[$i]->{RETURN}->{value});
								runRETURN($value, $TT);
							}
						}
						
					}
				}
			}
			
			
			if ( exists $DO->{DO} ) {
				runDO($DO->{DO}, $TT);
			}
			####
	
	# return @output;
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
		if ( length $name == 0 ) {
			mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = true)~) unless $no_log;
			return 1;
		} else {
			mlog($TT, qq~Comparison: IF [$name] $comparator (RETURN = false)~) unless $no_log;
			return 0;
		}
	}
}





sub mlog {
	my ($ticketNumber, $log) = @_;
	$log =~ s/\'/\"/g;
	my $sysdate = sysdate();
	
	# print "$sysdate : $ticketNumber : $log\n";
	
	 if ( $ticketNumber ne '00000000' ) {
		 connected();
		my $insert_string = "INSERT INTO log (numberTicket, insertDate, log) VALUES ('$ticketNumber', '$sysdate', '$log')";
		my $sth = $dbh->prepare("$insert_string");
		$sth->execute();
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
