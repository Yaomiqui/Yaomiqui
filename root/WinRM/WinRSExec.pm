package WinRM::WinRSExec;

########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# This is the WinRM connector for Windows remote machines
# The automation Power for Yaomiqui Automation Platform
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

=head1 NAME

WinRM::WinRSExec - Connects with Windows Machines running WinRM

Based on CURL runs remote commands using Windows Remote Shell (WinRS)

=cut

our $VERSION = '0.2';

=head1 VERSION

Version 0.2

Adding simple step logs

=cut

=head1 SYNOPSIS
 
 use WinRM::WinRSExec;
 
 my $winrm = WinRM::WinRSExec->new({
     host            => "WINDOWSADSERVER",
     protocol        => "http",
     timeout	        => 60,
     domain          => 'DOMAIN.LOCAL',
     username        => 'my.AD.user',
     password        => 'mYp4ssw0rd',
     kerberos        => 1
 });
 
 my $command = 'PowerShell -Command "&{Get-Host;}"';
 
 $winrm->execute({
     command => $command
 });
 
 print "STD OUT:\n" . $winrm->response . "\n";
 print "STD ERR:\n" . $winrm->error . "\n";
 print "STD LOG:\n" . $winrm->logger . "\n";    # Optional use
 
=cut

use strict;
use FindBin qw($RealBin);
use lib $RealBin;
use XML::Simple;
use MIME::Base64;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = shift;
	
    my $self = bless {
        host        => $self->{ host },
        protocol    => $self->{ protocol } || 'http',
        timeout     => $self->{ timeout } || 60,
        domain      => $self->{ domain } || undef,
        path        => $self->{ path } || '/wsman',
        username    => $self->{ username } || 'Administrator',
        password    => $self->{ password } || undef,
        kerberos    => $self->{ kerberos } || undef
    }, $class;
    
    return $self;
}

=head1 DESCRIPTION

WinRM::WinRSExec provides an interface to connect to Microsoft's Windows
Remote Management using Windows Remote Shell to enable you to execute
commands securely on any remote Windows Host.

WinRM::WinRSExec has the following specs:

=over 4

=item * Supports HTTP protocol.

=item * Supports HTTPS protocol.

=item * Supports Basic Authentication.

=item * Supports Kerberos Authentication (as well as NTLM).

=back

=head1 METHODS

=head2 new()

Initiate a new WinRM::WinRSExec Object

Accepts a hashref with the following keys

=over 4

=item * host (Mandatory)

Hostname or IP address of the remote host

=item * password (Mandatory for basic Authentication)

Password of the username being used to login

=item * username (Mandatory for basic Authentication)

Username of the user to authenticate as, may be a local or AD user (Kerberos) from remote host. (Default: Administrator)

=item * path (Optional)

Path where Windows Remote Management is listening on (Default: /wsman)

=item * protocol (Optional)

Either http or https (Default: http)

=item * timeout (Optional)

The timeout in seconds of a WinRM::WinRS exec. (Default: 60)

=back

=head2 response()

Returns the last response message encountered by a WinRM object

=head2 error()

Returns the last error message encountered by a WinRM object

=head2 logger()

Returns simple logs messages collected step by step

=cut

sub execute {
    my $self = shift;
    my $vars = shift;
    
    # Basic error checking on passed vars
    unless ( $self->{ host } ) {
        $self->{ error } = "Require hostname or IP address of host to connect to.";
        $self->{ log } .= sysdate() . "Leaving because host is missing" . "\n";
        return;
    }
    unless ( $self->{ kerberos } ) {
        unless ( $self->{ password } ) {
            $self->{ error } = "Require password for $self->{ username } user with Basic Authentication.";
            $self->{ log } .= sysdate() . "Leaving because password is missing" . "\n";
            return;
        }
    }
    
    $vars->{ command } =~ s/\r?\n//g;
    $vars->{ command } =~ s/\&/\&amp;/g;
    $vars->{ command } =~ s/\</\&lt;/g;
    $vars->{ command } =~ s/\>/\&gt;/g;
    $vars->{ command } =~ s/\'/\&apos;/g;
    $vars->{ command } =~ s/\"/\&quot;/g;
    
    $self->{ command } = $vars->{ command };
    
    my $authentication = $self->authentication;
    my $host = $self->host;
    
    ## LOGS
    if ( $self->{ kerberos } ) {
        $self->{ log } .= sysdate() . "Using Kerberos authentication" . "\n";
    }
    else {
         $self->{ log } .= sysdate() . "Using Basic authentication" . "\n";
    }
    $self->{ log } .= sysdate() . "Connecting to " . $host . "\n";
    
    
    ## Four steps
    foreach my $step ( 'CreateShell', 'ExecuteCommand', 'ReceiveOutput', 'DeleteShell' ) {
        $self->{ log } .= sysdate() . "Entering to $step step" . "\n";
        $self->{ xmlSend } = $self->$step;
        my $xml = $self->curlResponse;
        
        if ( $step eq 'CreateShell' ) {
            $self->{ MessageID } = $xml->{ 's:Header' }->{ 'a:MessageID' };
            $self->{ ShellId } = $xml->{ 's:Body' }->{ 'rsp:Shell' }->{ 'rsp:ShellId' };
            $self->{ log } .= sysdate() . "Shell Id gotten: " . $self->{ ShellId } . "\n";
        }
        
        if ( $self->{ ShellId } ) {
            if ( $step eq 'ExecuteCommand' ) {
                $self->{ CommandId } = $xml->{ 's:Body' }->{ 'rsp:CommandResponse' }->{ 'rsp:CommandId' };
                $self->{ log } .= sysdate() . "Command Id gotten: " . $self->{ CommandId } . "\n";
            }
        }
        else {
            ## ShellId error
            $self->{ error } = "Can't get Shell Id";
            $self->{ log } .= sysdate() . "Leaving. Can't get Shell Id" . "\n";
            return;
        }
        
        if ( $self->{ CommandId } ) {
            if ( $step eq 'ReceiveOutput' ) {
                $self->{ state } = $xml->{ 's:Body' }->{ 'rsp:ReceiveResponse' }->{ 'rsp:CommandState' }->{ 'State' };
                
                unless ( $self->{ state } =~ /CommandState\/Done$/ ) {
                    foreach ( 0 .. $self->{ timeout } ) {
                        my $xmlSt = $self->curlResponse;
                        
                        if ( $xmlSt->{ 's:Body' }->{ 'rsp:ReceiveResponse' }->{ 'rsp:CommandState' }->{ 'State' } =~ /CommandState\/Done$/ ) {
                            $self->{ state } = $xmlSt->{ 's:Body' }->{ 'rsp:ReceiveResponse' }->{ 'rsp:CommandState' }->{ 'State' };
                            last;
                        }
                        
                        sleep 1;
                    }
                }
                
                my $content = $xml->{ 's:Body' }->{ 'rsp:ReceiveResponse' }->{ 'rsp:Stream' };
                $self->{ log } .= sysdate() . "Getting response" . "\n";
                
                foreach my $i ( 0 .. $#{$content} ) {
                    if ( $content->[$i]->{ 'Name' } eq 'stdout' ) {
                        $self->{ response } .= decode_base64( $content->[$i]->{ 'content' } );
                    }
                    elsif ( $content->[$i]->{ 'Name' } eq 'stderr' ) {
                        $self->{ error } .= decode_base64( $content->[$i]->{ 'content' } );
                    }
                }
            }
        }
        
        if ( $step eq 'DeleteShell' ) {
            if ( $xml->{ 's:Header' }->{ 'a:Action' } =~ /DeleteResponse$/ ) {
                $self->{ log } .= sysdate() . "Shell Id " . $self->{ ShellId } . " deleted" . "\n";
            }
        }
    }
}

sub response {
    my $self = shift;
    return $self->{ response };
}

sub error {
    my $self = shift;
    return $self->{ error };
}

sub curlResponse {
    my $self = shift;
    my $xmlSend = $self->{ xmlSend };
    my $host = $self->host;
    my $authentication = $self->authentication;
    
    my $curl = qq~curl -k $authentication -H 'Content-Type: application/soap+xml;charset=UTF-8' -d '$xmlSend' -X POST --url '$host' 2>/dev/null~;
    my $response = `$curl`;
    my $xml = eval { XMLin($response) };
    
    return $xml;
}

sub host {
    my $self = shift;
    
    my $host;
    my $port = $self->{ protocol } eq 'https' ? 5986 : 5985;
    if ( $self->{ domain } ) {
        $host = $self->{ protocol } . '://' . $self->{ host } . '.' . $self->{ domain } . ':' . $port . $self->{ path };
    } else {
        $host = $self->{ protocol } . '://' . $self->{ host } . ':' . $port . $self->{ path };
    }
    
    return $host;
}

sub authentication {
    my $self = shift;
    
    my $authentication = '-u ' . $self->{ username } . ':' .  $self->{ password };
    
    if ( $self->{ kerberos } ) {
        $authentication = '--negotiate -u :';
    }
    
    return $authentication;
}

sub logger {
    my $self = shift;
    return $self->{ log };
}

sub sysdate {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	$fecha[4] ++;
	@fecha = map { if ($_ < 10) { $_ = "0$_"; } else { $_ } } @fecha;
	return "$fecha[5]-$fecha[4]-$fecha[3] $fecha[2]:$fecha[1]:$fecha[0]" . ' : ';
}

sub CreateShell {
    my $self = shift;
    my $endPoint = $self->host;
    my $timeout = $self->{ timeout };
    
    my $xml = qq~<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
<s:Header>
<wsa:To>
$endPoint
</wsa:To>
<wsman:ResourceURI s:mustUnderstand="true">
http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
</wsman:ResourceURI>
<wsa:ReplyTo>
<wsa:Address s:mustUnderstand="true">
http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
</wsa:Address>
</wsa:ReplyTo>
<wsa:Action s:mustUnderstand="true">
http://schemas.xmlsoap.org/ws/2004/09/transfer/Create
</wsa:Action>
<wsman:MaxEnvelopeSize s:mustUnderstand="true">153600</wsman:MaxEnvelopeSize>
<wsa:MessageID>uuid:AF6A2E07-BA33-496E-8AFA-E77D241A2F2F</wsa:MessageID>
<wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
<wsman:OptionSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<wsman:Option Name="WINRS_NOPROFILE">TRUE</wsman:Option>
<wsman:Option Name="WINRS_CODEPAGE">437</wsman:Option>
</wsman:OptionSet>
<wsman:OperationTimeout>
PT$timeout.000S
</wsman:OperationTimeout>
</s:Header>
<s:Body>
<rsp:Shell xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell">
<rsp:Environment>
<rsp:Variable Name="test">
1
</rsp:Variable>
</rsp:Environment>
<rsp:InputStreams>stdin</rsp:InputStreams>
<rsp:OutputStreams>
stdout stderr
</rsp:OutputStreams>
</rsp:Shell>
</s:Body>
</s:Envelope>
~;
    $xml =~ s/\n//g;
    return $xml;
}

sub ExecuteCommand {
    my $self = shift;
    my $MessageID = $self->{ MessageID };
    my $ShellId = $self->{ ShellId };
    my $endPoint = $self->host;
    my $timeout = $self->{ timeout };
    my $command = $self->{ command };
    
    my $xml = qq~<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
<s:Header>
<wsa:To>
$endPoint
</wsa:To>
<wsman:ResourceURI s:mustUnderstand="true">
http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
</wsman:ResourceURI>
<wsa:ReplyTo>
<wsa:Address s:mustUnderstand="true">
http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
</wsa:Address>
</wsa:ReplyTo>
<wsa:Action s:mustUnderstand="true">
http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Command
</wsa:Action>
<wsman:MaxEnvelopeSize s:mustUnderstand="true">153600</wsman:MaxEnvelopeSize>
<wsa:MessageID>
$MessageID
</wsa:MessageID>
<wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
<wsman:SelectorSet>
<wsman:Selector Name="ShellId">
$ShellId
</wsman:Selector>
</wsman:SelectorSet>
<wsman:OptionSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<wsman:Option Name="WINRS_CONSOLEMODE_STDIN">TRUE</wsman:Option>
</wsman:OptionSet>
<wsman:OperationTimeout>PT$timeout.000S</wsman:OperationTimeout>
</s:Header>
<s:Body>
<rsp:CommandLine xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell">
<rsp:Command>$command</rsp:Command>
</rsp:CommandLine>
</s:Body>
</s:Envelope>
~;
    $xml =~ s/\n//g;
    return $xml;
}

sub ReceiveOutput {
    my $self = shift;
    my $MessageID = $self->{ MessageID };
    my $ShellId = $self->{ ShellId };
    my $endPoint = $self->host;
    my $timeout = $self->{ timeout };
    my $CommandId = $self->{ CommandId };
    
    my $xml = qq~<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
<s:Header>
<wsa:To>
$endPoint
</wsa:To>
<wsa:ReplyTo>
<wsa:Address s:mustUnderstand="true">
http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
</wsa:Address>
</wsa:ReplyTo>
<wsa:Action s:mustUnderstand="true">
http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Receive
</wsa:Action>
<wsman:MaxEnvelopeSize s:mustUnderstand="true">
153600
</wsman:MaxEnvelopeSize>
<wsa:MessageID>
$MessageID
</wsa:MessageID>
<wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
<wsman:ResourceURI xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
</wsman:ResourceURI>
<wsman:SelectorSet xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" xmlns="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
<wsman:Selector Name="ShellId">
$ShellId
</wsman:Selector>
</wsman:SelectorSet>
<wsman:OperationTimeout>
PT$timeout.000S
</wsman:OperationTimeout>
</s:Header>
<s:Body>
<rsp:Receive xmlns:rsp="http://schemas.microsoft.com/wbem/wsman/1/windows/shell" SequenceId="0">
<rsp:DesiredStream CommandId="$CommandId">
stdout stderr
</rsp:DesiredStream>
</rsp:Receive>
</s:Body>
</s:Envelope>
~;
    $xml =~ s/\n//g;
    return $xml;
}

sub DeleteShell {
    my $self = shift;
    my $MessageID = $self->{ MessageID };
    my $ShellId = $self->{ ShellId };
    my $endPoint = $self->host;
    my $timeout = $self->{ timeout };
    
    my $xml = qq~<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
<s:Header>
<wsa:To>
$endPoint
</wsa:To>
<wsa:ReplyTo>
<wsa:Address s:mustUnderstand="true">
http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
</wsa:Address>
</wsa:ReplyTo>
<wsa:Action s:mustUnderstand="true">
http://schemas.xmlsoap.org/ws/2004/09/transfer/Delete
</wsa:Action>
<wsman:MaxEnvelopeSize s:mustUnderstand="true">
153600
</wsman:MaxEnvelopeSize>
<wsa:MessageID>
$MessageID
</wsa:MessageID>
<wsman:Locale xml:lang="en-US" s:mustUnderstand="false" />
<wsman:ResourceURI 
xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd
</wsman:ResourceURI>
<wsman:SelectorSet xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" xmlns="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
<wsman:Selector Name="ShellId">
$ShellId
</wsman:Selector>
</wsman:SelectorSet>
<wsman:OperationTimeout>
PT$timeout.000S
</wsman:OperationTimeout>
</s:Header>
<s:Body></s:Body>
</s:Envelope>
~;
    $xml =~ s/\n//g;
    return $xml;
}

=head1 LICENSE

Copyright (C) Hugo Maza.

https://github.com/HugoMaza

http://yaomiqui.org

This software is released under the GPLv3 License.

http://www.gnu.org/licenses/gpl-3.0.html

=cut

