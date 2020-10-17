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
use MIME::Base64;
use Tie::File;
use Data::Dumper;
use FindBin qw($RealBin);
use lib $RealBin;
use strict;
no strict "subs";
use CGI;

our ($dbh, %VAR, $ticketNumber, $encKey, %input, %data);
%VAR = get_vars();
# $encKey = getEncKey();
my $debug = 0;

my $q = CGI->new();

if ( $ENV{HTTPS} ne 'on' ) {
	print $q->header('application/json');
	print qq~{"Error":"HTTPS is not being used"}~;
	exit;
}

print $q->header('text/html') if $debug;	##
foreach my $pair ( split(/\&/, $ENV{QUERY_STRING} ) ) {
	my ($k, $v) = split(/\=/, $pair);
	$input{$k} = $v;
	print $k . ' = ' . $input{$k} . "\n" if $debug;	##
}
my @pares = $q->param;
foreach my $par ( @pares ){
	$data{"$par"} = $q->param("$par");
	print $par . ' = ' . $data{$par} . "\n" if $debug;	##
}
if ( $debug ) {
    foreach my $key ( keys %ENV ) {	##
        print $key . '=' . $ENV{$key} . "\n";	##
    }	##
    exit;	##
}

# if ( $ENV{REMOTE_ADDR} ne $ENV{SERVER_ADDR} ) {     ## When we don't need authentication from localhost
if ( $input{remote_acc} =~ /^127.0.0.1|localhost/ ) {     ## When we don't need authentication from localhost
	if ( $input{access_key} and $input{secret_acc} ) {
        $input{access_key} = cleanField($input{access_key});
        $input{secret_acc} = cleanField($input{secret_acc});
        
        unless ( ($VAR{access_key} eq $input{access_key}) and ($VAR{secret_acc} eq $input{secret_acc}) and ($VAR{remote_acc} eq $ENV{REMOTE_ADDR}) ) {
            print $q->header('application/json');
            print qq~{"Error":"Authentication failed"}~;
            exit;
        }
	} else {
		print $q->header('application/json');
		print qq~{"Error":"Parameters missing"}~;
		exit;
	}
}

use strict;

if ( $ENV{REQUEST_METHOD} eq 'POST' ) {
	if ( $ENV{PATH_INFO} =~ /^\/ExecuteCommand\// ) {
                      # my $json = eval { decode_json $data{POSTDATA} };
        my $json = eval { JSON->new->decode($data{POSTDATA}) };
        
        ## Timeout function starts
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm $json->{Exec}->{timeout};
            ## Timeout function 1rst section
        
        
        if ( $json->{Exec}->{serverType} eq 'Local' ) {
            
            my $randomString = randomString();
            my $linerrfile = '/var/lib/yaomiqui/tmp/' . $randomString . '.err';
            
            my $linuxCommand = decode_base64( $json->{Exec}->{command} );
            
            my $resultsExecution;
            
            if ( $linuxCommand =~ /^perl\s*\&\{/ ) {
                
                $linuxCommand =~ s/^perl\s*\&\{//;
                $linuxCommand =~ s/}$//;
                
                my $scriptFile = '/var/lib/yaomiqui/tmp/' . $randomString . '.pl';
                
                open(PERLSCRIPT, ">$scriptFile");
                print PERLSCRIPT $linuxCommand;
                close PERLSCRIPT;
                
                $resultsExecution = `/usr/bin/perl $scriptFile 2>$linerrfile`;
                
                unlink "$scriptFile";
                
            }
            elsif ( $linuxCommand =~ /^bash\s*\&\{/ ) {
                
                $linuxCommand =~ s/^bash\s*\&\{//;
                $linuxCommand =~ s/}$//;
                
                my $scriptFile = '/var/lib/yaomiqui/tmp/' . $randomString . '.sh';
                
                open(BASHSCRIPT, ">$scriptFile");
                print BASHSCRIPT $linuxCommand;
                close BASHSCRIPT;
                
                $resultsExecution = `/bin/bash $scriptFile 2>$linerrfile`;
                
                unlink "$scriptFile";
                
            }
            else {
                if ( $linuxCommand =~ /^perl\s*-e '/ ) {
                    $linuxCommand =~ s/^perl\s*-e '//;
                    $linuxCommand =~ s/'$//;
                    $linuxCommand =~ s/'/'\\''/g;
                    $linuxCommand = qq~/usr/bin/perl -e '$linuxCommand'~;
                }
                
                my $scriptFile = '/var/lib/yaomiqui/tmp/' . $randomString;
                
                open(SCRIPT, ">$scriptFile");
                print SCRIPT $linuxCommand;
                close SCRIPT;
                
                chmod 0755, $scriptFile;
                
                $resultsExecution = `$scriptFile 2>$linerrfile`;
                
                unlink "$scriptFile";
            }
            
            $resultsExecution = encode_base64( $resultsExecution, '' );
            my $Error = encode_base64( `cat $linerrfile`, '' );
            
            print $q->header('application/json; charset=UTF-8');
            print qq~{"Result": "Success", "Response": "$resultsExecution", "Error": "$Error"}~;
            
            unlink "$linerrfile";
            
        }
        
        
        
        
        
        
        
        
        
        elsif ( $json->{Exec}->{serverType} eq 'Linux' ) {
            
            my $Error;
            my $resultsExecution;
            # my $SACM = $json->{Exec}->{timeout} / 60;
            my $ssh;
            
            my $randomString = randomString();
            my $linerrfile = '/var/lib/yaomiqui/tmp/' . $randomString . '.err';
            
            my $remoteLinuxCommand = decode_base64( $json->{Exec}->{command} );
            
            if ( $remoteLinuxCommand =~ /^perl\s*-e '/ ) {
                $remoteLinuxCommand =~ s/^perl\s*-e '//;
                $remoteLinuxCommand =~ s/'$//;
                $remoteLinuxCommand =~ s/'/'\\''/g;
                $remoteLinuxCommand = qq~/usr/bin/perl -e '$remoteLinuxCommand'~;
            }
            
            $remoteLinuxCommand =~ s/\r?\n//g;
            
            use Net::OpenSSH;
            $Net::OpenSSH::debug = -1;
            
            if ( $json->{Exec}->{Linux}->{key_path} ) {
                $ssh = Net::OpenSSH->new($json->{Exec}->{host},
                    user				=> $json->{Exec}->{username},
                    key_path			=> $json->{Exec}->{Linux}->{key_path},
                    port				=> $json->{Exec}->{Linux}->{port},
                    strict_mode			=> 0,
                    timeout				=> $json->{Exec}->{timeout},
                    kill_ssh_on_timeout	=> 1,
                    master_opts 		=> [
                                            -o => 'StrictHostKeyChecking=no',
                                            -o => 'LogLevel=QUIET',
                                            -o => "ConnectTimeout=43200",
                                            -o => 'ServerAliveInterval=60',
                                            -o => "ServerAliveCountMax=10",
                                            -o => 'TCPKeepAlive=yes'
                                            ]
                );
            }
            else {
                $ssh = Net::OpenSSH->new($json->{Exec}->{host},
                    user				=> $json->{Exec}->{username},
                    password			=> $json->{Exec}->{password},
                    port				=> $json->{Exec}->{Linux}->{port},
                    strict_mode			=> 0,
                    timeout				=> $json->{Exec}->{timeout},
                    kill_ssh_on_timeout	=> 1,
                    master_opts 		=> [
                                            -o => 'StrictHostKeyChecking=no',
                                            -o => 'LogLevel=QUIET',
                                            -o => "ConnectTimeout=43200",
                                            -o => 'ServerAliveInterval=60',
                                            -o => "ServerAliveCountMax=10",
                                            -o => 'TCPKeepAlive=yes'
                                            ]
                );
            }
            
            my $scriptFile = $randomString;
            my $scriptFileLocalPath = '/var/lib/yaomiqui/tmp/' . $scriptFile;
            
            open(SCRIPT, ">$scriptFileLocalPath");
            print SCRIPT $remoteLinuxCommand;
            close SCRIPT;
            
            `sshpass -p "$json->{Exec}->{password}" scp $scriptFileLocalPath $json->{Exec}->{username}\@$json->{Exec}->{host}:$json->{Exec}->{Linux}->{TempDir}/$scriptFile 2>>$linerrfile`;
            
            unlink "$scriptFileLocalPath";
            
            unless ( $ssh->error ) {
                # $resultsExecution = $ssh->capture2("$remoteLinuxCommand 2>&1");
                $ssh->capture2("chmod 755 $json->{Exec}->{Linux}->{TempDir}/$scriptFile");
                $resultsExecution = $ssh->capture2("$json->{Exec}->{Linux}->{TempDir}/$scriptFile 2>&1;");
                $ssh->capture2("rm -f $json->{Exec}->{Linux}->{TempDir}/$scriptFile");
                
                $resultsExecution =~ s/^\n//g;
                $resultsExecution =~ s/\n$//g;
            }
            else {
                $Error = $ssh->error;
            }
            
            $Error .= `cat $linerrfile`;
            
            $resultsExecution = encode_base64( $resultsExecution, '' );
            $Error = encode_base64( $Error, '' );
            
            print $q->header('application/json; charset=UTF-8');
            print qq~{"Result": "Success", "Response": "$resultsExecution", "Error": "$Error"}~;
            
            unlink "$linerrfile";
            
        }
        
        
        
        
        
        
        
        
        
        
        elsif ( $json->{Exec}->{serverType} eq 'Windows' ) {
            
            my $Error;
            my $resultsExecution;
            
            my $remoteWindowsCommand = decode_base64( $json->{Exec}->{command} );
            $remoteWindowsCommand =~ s/\r?\n//g;
            
            $json->{Exec}->{password} = decode_base64( $json->{Exec}->{password} );
            
            use WinRM::WinRSExec;
            my $winrm = WinRM::WinRSExec->new({
                host            => $json->{Exec}->{host},
                protocol		=> $json->{Exec}->{Windows}->{protocol},
                timeout			=> $json->{Exec}->{timeout},
                domain          => $json->{Exec}->{Windows}->{domain},
                path            => $json->{Exec}->{Windows}->{path},
                username        => $json->{Exec}->{username},
                password        => $json->{Exec}->{password},
                kerberos        => $json->{Exec}->{Windows}->{kerberos}
            });
            
            unless ( $winrm ) {
                $Error = 'Cannot create a "new" WinRM::WinRSExec object. ' . "$? : $!";
            }
            else {
                $winrm->execute({ command => $remoteWindowsCommand });
                
                if ( $winrm->response ) {
                    $resultsExecution = $winrm->response;
                }
                elsif ( $winrm->error ) {
                    $Error = $winrm->error;
                }
                else {
                    $Error = 'Unknown error';
                }
            }
            
            $resultsExecution = encode_base64( $resultsExecution, '' );
            $Error = encode_base64( $Error, '' );
            
            print $q->header('application/json');
            print qq~{"Result": "Success", "Response": "$resultsExecution", "Error": "$Error"}~;
        }
        else {
            print $q->header('application/json');
            print qq~{"Result": "Error", "Response": "", "Error": "serverType Not specified"}~;
        }
        
        
        
        ## Timeout function continues
        alarm 0;
        };
        
        if ( $@ eq "timeout\n" ) {
            print $q->header('application/json; charset=ISO-8859-1');
            print qq~{"Result": "Error", "Response": "", "Error": "Timed out"}~;
        }
        ## Timeout function ends
        
    }
    else {
        print $q->header('application/json');
        print qq~{"Result": "Error", "Response": "", "Error": "Wrong Path"}~;
    }
}
else {
	print $q->header('application/json');
	
	restApiLog("ERROR :: $ticketNumber : Wrong METHOD: $ENV{REQUEST_METHOD}. User: $input{user}");
	print qq~{"Error":"Wrong METHOD: $ENV{REQUEST_METHOD}"}~;
}

# print $q->header('application/json');
# print qq~{"Result": "Error", "Response": "", "Error": "Nothing to do"}~;







exit;

sub cleanField {
    my $field = shift;
    $field =~ s/<|>|script|java|onmouse|onkey|onload|onerror|onunload|onresize|onclick|onchange|onblur|onfocus|onselect|onsubmit|\#|select|update|delete|insert|sleep//gi;
    return $field;
}

# sub connected {
	# use DBI;
	# $dbh = DBI->connect("DBI:mysql:$VAR{'DB'}:$VAR{'DBHOST'}", $VAR{'DBUSER'}, $VAR{'DBPASSWD'}) or restApiLog("ERROR :: $ticketNumber : MySQL Connect: " . $DBI::errstr) and exit;
# }

sub restApiLog {
	my $msg = shift;
	my $date = date_nospace();
	my $sysdate = sysdate();
	my $engine_log_dir = $VAR{engine_log_dir};
	
	open my $ELOG, ">>", "$engine_log_dir/rest-api-$date.log";
	print $ELOG qq~$sysdate :: $msg\n~;
	close $ELOG;
	## restApiLog("ERROR :: $ticketNumber : ");
	## restApiLog("INFO  :: $ticketNumber : ");
	## restApiLog("WARN  :: $ticketNumber : ");
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
	return my $date_nospace = "$fecha[5]$fecha[4]$fecha[3]";
}

sub randomString {
    my $randomString;
    my @chars = ('a'..'z', 0..9 ,'A'..'Z');
    $randomString .= $chars[int(rand(@chars))] for 1..32;
    
    return $randomString
}

# sub getEncKey {
	## my $o = tie my @array, 'Tie::File', $VAR{enc_key} or die "I can't open yaomiqui encrypted key: $VAR{enc_key}\n";
	# my $o = tie my @array, 'Tie::File', $VAR{enc_key} or restApiLog("ERROR :: $ticketNumber : I can't open yaomiqui encrypted key: " . $VAR{enc_key}) and exit;
	# my $encKey = $array[0];
	# untie @array;
	# return $encKey;
# }


