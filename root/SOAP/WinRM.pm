package SOAP::WinRM;

=head1 NAME

SOAP::WinRM - Contact Windows Machines running WinRM and run commands using
Windows Remote Shell (WinRS) using SOAP

=cut


use strict;
use warnings;
use Carp qw/ cluck /;
use SOAP::Lite;
use Data::UUID;
use MIME::Base64;
use XML::Simple;
use Data::Dumper;

# Default setup configs
our $DEFAULTS = {
    path                        => "/wsman",
    timeout                     => 60,
    protocol                    => "https",
    domain                      => undef,
    username                    => "Administrator",
    debug                       => undef,
    validate                    => 0,
    running_command_recheck     => 5,
    kerberos                    => undef
};

=head1 VERSION

Version 0.3

=cut

our $VERSION = "0.4";

# The Minimum and Maximum Stack Versions that we support as returned from the identify() method
our $REMOTE_MIN_VERSION = "1.1";
our $REMOTE_MAX_VERSION = "2.0";

# Set SOAP KeepAlive
$SOAP::Constants::PATCH_HTTP_KEEPALIVE = 1;

=head1 SYNOPSIS

  use SOAP::WinRM;

  # Create SOAP::WinRM Object
  my $winrm = SOAP::WinRM->new(
        host            => "192.168.0.1",
        username        => "Administrator",
        password        => "password",
        kerberos        => "MYDOMAIN.COM"
  );

  unless ($winrm) {
        print $SOAP::WinRM::errstr;
        exit;
  }

  # Test the connection to the remote host
  my $test = $winrm->test;
  unless ($test) {
        print $winrm->errstr;
        exit;
  }

  # Check if the remote host is running a compatible version of WinRM
  my $compat = $winrm->test_compatibility;
  unless ($compat) {
    print $winrm->errstr;
    exit;
  }

  # Get the remote host to identify it's OS and WinRM versions
  my $identify = $winrm->identify();
  unless ($identify) {
        print $winrm->errstr;
        exit;
  }
  print "Remote System: " . $identify->{ "wsmid:IdentifyResponse" }{ "wsmid:ProductVendor" } . " " . $identify->{ "wsmid:IdentifyResponse" }{ "wsmid:ProductVersion" } . "\n\n";

  # Send a command to the remote host
  my @execute = $winrm->execute( command => [ "ipconfig" ] );

  unless (defined($execute[0])) {
        print $winrm->errstr;
        exit;
  }

  print "Exit Code: " . $execute[0] . "\n";
  print "STDOUT: " . $execute[1] . "\n";
  print "STDERR: " . $execute[2] . "\n";


=head1 DESCRIPTION

SOAP::WinRM provides an interface to connect to Microsoft's Windows Remote
Management and Windows Remote Shell to enable you to execute commands securely
on a remote Windows Host.

SOAP::WinRM has the following limitations (at present).

=over 4

=item * Only supports HTTP(S) Basic Auth authentication.

=item * Only supports login of users local to the remote host. Login of domain users isn't supported.

=item * UPDATE: Kerberos Authentication was added and we are able to login with domain users.

=item * Only works on WinRM in Windows 2008 R1 Service Pack 1 or Windows 2008 R2

=item * UPDATE: SOAP::WinRM was tested on Windows 2012 r2 and 2019 Std using Powershell 5.x and worked fine

=back

=head1 METHODS

=head2 new()

Instantiate a new SOAP::Lite Object

Accepts a hashref with the following keys

=over 4

=item * host (Mandatory)

Hostname or IP address of the remote host

=item * password (Mandatory)

Password of the username being used to login

=item * username (Optional)

Username of the user to authenticate as, must be a local user to the remote host.
(Default: Administrator)

=item * path (Optional)

The path that Windows Remote Management is listening on (Default: /wsman)

=item * protocol (Optional)

Either http or https (Default: https)


=item * port (Optional)

The port will be automatically determined given the protocol provided, but can be overwritten

=item * timeout (Optional)

The timeout in seconds of a WinRM/WinRS call. (Default: 60)

=item * debug (Optional)

The value of the debug setting, suitable values are 0,1,2.
0 = No Debug
1 = Gentle Debugging
2 = Full Debugging including all SOAP::Lite Output

=item * validate (Optional)

If this value is set, after the object is instantiated, the constructor will run test() and
test_compatibility() methods to ensure the remote host is there and we can talk to it.
This lets your calling script know that when it gets the object back it's good to go and doesn't
need to wait until it's made the first call to find out it's not connected to the remote host.
This is optional as it will add extra overhead to every instantiation.

=cut

sub new {
    my $class = shift;
    my $vars = $_[0] && ref($_[0]) eq "HASH" ? shift : { @_ };


    $vars->{ $_ } ||= $DEFAULTS->{ $_ }
            foreach ("path","username","debug","protocol","timeout");

    $SOAP::WinRM::DEBUG = ($vars->{ debug } && $vars->{ debug } =~ /^\d+$/) ? $vars->{ debug } : 0;
    _debug("DEBUG level set to $SOAP::WinRM::DEBUG");
    $SOAP::WinRM::errstr = "";


    # Basic error checking on passed vars
    $vars->{ host } ||
    do { _set_errstr("Require hostname or IP address of host to connect to."); return undef };
    $vars->{ password } ||
    do { _set_errstr("Require password for the $vars->{ username } user."); return undef };
    $vars->{ path } = "/".$vars->{ path }
    unless ($vars->{ path } =~ m[^/]);
    do { _set_errstr("Timeout must be an integer"); return undef }
    unless ($vars->{ timeout } =~ /^\d+$/);
    do { _set_errstr("Protocol must be http or https, default is $DEFAULTS->{ protocol }."); return undef }
        unless ($vars->{ protocol } =~ /^http(s)?$/);


    $vars->{ port } = $vars->{ protocol } eq "https" ? "5986" : "5985"
        unless ($vars->{ port });

    bless $vars, $class;
    if ($vars->{ validate }) {
        _debug("Validating object..");
        foreach my $method ("test","test_compatibility") {
            my $check = $vars->$method();
            return undef unless ($check);
        }
    }
    return $vars;

}






=back

=head2 get_url()

Returns the URI that the remote host is using for WinRM requests
=cut

sub get_url {
    my $self = shift;
    return $self->{ protocol } . "://" . $self->{ host } . ":" . $self->{ port } . $self->{ path };
}



=head2 errstr()

Returns the last error message encountered by a WinRM object
=cut

sub errstr {
    my $self = shift;
    return $SOAP::WinRM::errstr || undef;
}





=head2 timeout()

Returns the current timeout for the object. If supplied with an integer, the timeout is updated
=cut

sub timeout {
    my $self = shift;
    my $new_timeout = shift || undef;
    if ($new_timeout) {
        if ($new_timeout !~ /^\d+$/) {
            warn "Timeout value must be an integer";
        } else {
            $self->{ timeout } = $new_timeout;
        }
    }
    return $self->{ timeout };
}





=head2 test_compatibility()

The original WinRM release < Stack 2.0 used a slightly different SOAP layout and I can't see
much point in supporting it, this method checks if the remote host is running Stack 2.0 or
greater so will play nicely with us.

Returns 1 or undef depending on compatibility.
=cut

sub test_compatibility {
    my $self = shift;
    my $id = $self->identify();
    if ($id) {
        if ($id->{ "wsmid:IdentifyResponse" } && $id->{ "wsmid:IdentifyResponse" }{ "wsmid:ProductVersion" }) {
            if ($id->{ "wsmid:IdentifyResponse" }{ "wsmid:ProductVersion" } =~ /Stack: (\d+\.\d+)$/) {
                my $remote_version = $1;
                if (($remote_version >= $REMOTE_MIN_VERSION) && ($remote_version <= $REMOTE_MAX_VERSION)) {
                    return 1;
                }
                _set_errstr("Remote host WinRM Stack version $remote_version is not between supported versions of $REMOTE_MIN_VERSION and $REMOTE_MAX_VERSION");
                return undef;
            }
            _set_errstr("Remote host WinRM did not return a valid Stack Version");
            return undef;
        } else {
            _set_errstr("Failed to get valid identify response from host");
            return undef;
        }

    }
    # Don't set errstr, if there's no response, this will have already been set by the
    # _make_call method, so just return undef
    return undef;
}





=head2 test()

Test the connection to the Remote host by using an identify call. This does the same as the identify call
=cut

sub test {
    my $self= shift;
    return $self->identify(@_);
}




=head2 identify()

Make an 'identify' call to the remote host, identical to running 'winrm identify' on the remote machine.

Returns a hashref of the result.

=cut

sub identify {
    my $self = shift;
    my $vars = shift || {};

    return $self->_make_call(
        envelope_namespaces     => [
                                        [ 'http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd', 'wsmid'],
                                   ],
        body                    => [
                                        SOAP::Data->name('Identify' => undef)->prefix("wsmid")->type('')
                                   ],
        headers                 => [],
    );
}







=head2 execute()

Run a command on the remote host using WinRS. Accepts a hashref, the command is either a scalar
or an arrayref of the command and arguments to be run.

Returns an array of the exit code, standard out stream and standard error stream.

UPDATE:
We can run Powershell commands like:

PowerShell -Command "Get-Host;"

or better:

PowerShell "&{Get-Host};"

=cut

sub execute {
    my $self = shift;
    my $vars = $_[0] && ref($_[0]) eq "HASH" ? shift : { @_ };

    $vars->{ command } ||= [];
    $vars->{ command } = ref($vars->{ command }) eq "ARRAY" ? $vars->{ command } : [ $vars->{ command } ];
    my $command = join(' ', @{$vars->{ command }});
    
    ## XML special character handling
    $command =~ s/\&/\&amp;/g;
    $command =~ s/\</\&lt;/g;
    $command =~ s/\>/\&gt;/g;
    $command =~ s/\'/\&apos;/g;
    $command =~ s/\"/\&quot;/g;

    unless ($command) {
        _set_errstr("Invalid command to execute");
        return undef;
    }

    my $timeout = $self->timeout;

    my $initiate = $self->_make_call(
        envelope_namespaces     => [
                                        [ 'http://schemas.xmlsoap.org/ws/2004/08/addressing', 'a' ],
                                        [ 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd', 'w' ],
                                   ],
        headers                 => [
                                        SOAP::Header->name('To' => $self->get_url )->prefix("a")->type(''),
                                        SOAP::Header->name('MessageID' => "uuid:" . $self->_new_uuid)->prefix("a")->type(''),
                                        SOAP::Header->name('ResourceURI' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                                        SOAP::Header->name('Action' => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Create")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                        SOAP::Header->name('MaxEnvelopeSize' => "153600")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                                        SOAP::Header->name('Locale' => '')->attr({ "xml:lang" => "en-US","s:mustUnderstand" => "false" })->prefix("w")->type(''),
                                        SOAP::Header->name('OperationTimeout' => "PT$timeout.000S")->prefix("w")->type(''),
                                        SOAP::Header->name("ReplyTo" => \SOAP::Header->value(
                                                SOAP::Header->name('Address' => "http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                                ),
                                        )->prefix("a"),
                                        SOAP::Header->name("OptionSet" =>
                                                \SOAP::Header->value(
                                                        SOAP::Header->name(Option => "FALSE")->attr({ Name => "WINRS_NOPROFILE" })->prefix("w")->type(''),
                                                        SOAP::Header->name(Option => "437")->attr({ Name => "WINRS_CODEPAGE" })->prefix("w")->type(''),
                                                )->type(''),
                                        )->attr({ "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" })->prefix("w")->type(''),
                                   ],
        body                    => [
                                        SOAP::Data->name( "Shell" => 1 )->attr({ "xmlns:rsp" => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell" })->prefix("rsp")->type(''),
                                        SOAP::Data->name( "InputStreams" => "stdin" )->prefix("rsp")->type(''),
                                        SOAP::Data->name( "OutputStreams" => "stdout stderr" )->prefix("rsp")->type(''),
                                   ],
    );

    unless ($initiate &&
            $initiate->{ "x:ResourceCreated" } &&
            $initiate->{ "x:ResourceCreated" }{ "a:ReferenceParameters" } &&
            $initiate->{ "x:ResourceCreated" }{ "a:ReferenceParameters" }{ "w:SelectorSet" } &&
            $initiate->{ "x:ResourceCreated" }{ "a:ReferenceParameters" }{ "w:SelectorSet" }{ "w:Selector" } &&
            $initiate->{ "x:ResourceCreated" }{ "a:ReferenceParameters" }{ "w:SelectorSet" }{ "w:Selector" }{ content }) {
                    _set_errstr("Failed step 1/4 " . $SOAP::WinRM::errstr);
                    return undef;
    }
    my $create_uid = $initiate->{ "x:ResourceCreated" }{ "a:ReferenceParameters" }{ "w:SelectorSet" }{ "w:Selector" }{ content };

    my $send_command = $self->_make_call(
        envelope_namespaces     => [
                                        [ 'http://schemas.xmlsoap.org/ws/2004/08/addressing', 'a' ],
                                        [ 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd', 'w' ],
                                   ],
        headers                 => [
                                        SOAP::Header->name('To' => $self->get_url )->prefix("a")->type(''),
                                        SOAP::Header->name('MessageID' => "uuid:" . $self->_new_uuid)->prefix("a")->type(''),
                                        SOAP::Header->name('ResourceURI' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                                        SOAP::Header->name('Action' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Command")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                        SOAP::Header->name('MaxEnvelopeSize' => "153600")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                                        SOAP::Header->name('Locale' => '')->attr({ "xml:lang" => "en-US","s:mustUnderstand" => "false" })->prefix("w")->type(''),
                                        SOAP::Header->name("SelectorSet" => \SOAP::Header->value(
                                                SOAP::Header->name('Selector' => "$create_uid")->attr({ "Name" => "ShellId" })->prefix("w")->type(''),
                                                ),
                                        )->prefix("w")->type(''),
                                        SOAP::Header->name('OperationTimeout' => "PT$timeout.000S")->prefix("w")->type(''),
                                        SOAP::Header->name("ReplyTo" => \SOAP::Header->value(
                                                SOAP::Header->name('Address' => "http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                                ),
                                        )->prefix("a"),
                                        SOAP::Header->name("OptionSet" =>
                                                \SOAP::Header->value(
                                                        SOAP::Header->name(Option => "TRUE")->attr({ Name => "WINRS_CONSOLEMODE_STDIN" })->prefix("w")->type(''),
                                                )->type(''),
                                        )->attr({ "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" })->prefix("w")->type(''),
                                   ],
        body                    => [
                                        SOAP::Data->name( "CommandLine" => undef )->attr({ "xmlns:rsp" => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell" })->prefix("rsp")->type(''),
                                        SOAP::Data->name( "Command" => $command )->prefix("rsp")->type(''),
                                   ],
    );

    unless ($send_command &&
            $send_command->{ "rsp:CommandResponse" } &&
            $send_command->{ "rsp:CommandResponse" }{ "rsp:CommandId" }) {
                    _set_errstr("Failed step 2/4 " . $SOAP::WinRM::errstr);
                    return undef;
    }
    my $command_uid = $send_command->{ "rsp:CommandResponse" }{ "rsp:CommandId" };


    my $finished = 0;
    my $exit_code = undef;
        my $stream_data = {
                stdout  => '',

                stderr  => '',
        };


    while (!$finished) {

        my $receive_stream = $self->_make_call(
            envelope_namespaces         => [
                            [ 'http://schemas.xmlsoap.org/ws/2004/08/addressing', 'a' ],
                            [ 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd', 'w' ],
                           ],
            headers                     => [
                            SOAP::Header->name('To' => $self->get_url )->prefix("a")->type(''),
                            SOAP::Header->name('ResourceURI' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                            SOAP::Header->name("ReplyTo" => \SOAP::Header->value(
                                SOAP::Header->name('Address' => "http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                ),
                            )->prefix("a"),
                            SOAP::Header->name('Action' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Receive")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                            SOAP::Header->name('MaxEnvelopeSize' => "153600")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                            SOAP::Header->name('MessageID' => "uuid:" . $self->_new_uuid)->prefix("a")->type(''),
                            SOAP::Header->name('Locale' => '')->attr({ "xml:lang" => "en-US","s:mustUnderstand" => "false" })->prefix("w")->type(''),
                            SOAP::Header->name("SelectorSet" => \SOAP::Header->value(
                                SOAP::Header->name('Selector' => "$create_uid")->attr({ "Name" => "ShellId" })->prefix("w")->type(''),
                                ),
                            )->prefix("w")->type(''),
                            SOAP::Header->name("OptionSet" =>
                                \SOAP::Header->value(
                                    SOAP::Header->name(Option => "TRUE")->attr({ Name => "WSMAN_CMDSHELL_OPTION_KEEPALIVE" })->prefix("w")->type(''),
                                )->type(''),
                            )->attr({ "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" })->prefix("w")->type(''),
                            SOAP::Header->name('OperationTimeout' => "PT$timeout.000S")->prefix("w")->type(''),
                           ],
            body                        => [
                            SOAP::Data->name( "Receive" => undef )->attr({ "xmlns:rsp" => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell", SequenceId => 0 })->prefix("rsp")->type(''),
                            SOAP::Data->name( "DesiredStream" => "stdout stderr" )->attr({ CommandId => "$command_uid" })->prefix("rsp")->type(''),
                           ],
        );

        # Check if we have a report on the command's current state
        unless (    $receive_stream &&
                    $receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }) {

                        _set_errstr("Failed step 3/4 " . $SOAP::WinRM::errstr);
                        return undef;
        }

        # Read any command output that we've been sent, for stderr and stdout
        if (    $receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:Stream" } &&
                ref($receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:Stream" }) eq "ARRAY") {
                foreach my $stream (@{$receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:Stream" }}) {
                next unless ($stream->{ CommandId } eq $command_uid);
                        next unless ($stream->{ content });
                        next unless ($stream->{ Name } =~ /^std(out|err)$/);
                $stream_data->{ $stream->{ Name } } .= decode_base64( $stream->{ content } );
                }
        }

        # Check if command has now finished... or whether to send another check
        if (my $command_state = $receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }) {
            _debug("Forcing CommandState to ArrayRef");
            $command_state = (ref($command_state) eq "ARRAY")
                ? $command_state
                : [ $command_state ];

            my $check_command_state = pop(@$command_state);
            unless ($check_command_state) {
                _set_errstr("Failed step 3/4 couldn't pop CommandState");
            }

            if ($check_command_state->{ "State" } =~ /Done$/) {
                $finished = 1;
                $exit_code = $check_command_state->{ "rsp:ExitCode" };
            } elsif ($check_command_state->{ "State" } =~ /Running$/) {
                _debug("Command is still running, rechecking command status in $DEFAULTS->{ running_command_recheck } seconds..");
                sleep $DEFAULTS->{ running_command_recheck };
            } else {
                _set_errstr("Failed step 3/4 Unknown Command State");
                return undef;
            }
        } else {
            _set_errstr("Failed step 3/4 CommandState doesn't exist");
            return undef;
        }

#        if ($receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }{ "State" } =~ /Done$/) {
#            $finished=1;
#            $exit_code = $receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }{ "rsp:ExitCode" };
#        } elsif ($receive_stream->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }{ "State" } =~ /Running$/) {
#            #Command is still running, sleep and give it another shot....
#            _debug("Command is still running, rechecking command status in $DEFAULTS->{ running_command_recheck } seconds..");
#            sleep $DEFAULTS->{ running_command_recheck };
#        } else {
#            _set_errstr("Failed step 3/4 Unknown Command State");
#            return undef;
#        }
    }


    # We've got all we want, close the session
    my $close = $self->_make_call(
        envelope_namespaces     => [
                                        [ 'http://schemas.xmlsoap.org/ws/2004/08/addressing', 'a' ],
                                        [ 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd', 'w' ],
                                   ],
        headers                 => [
                                        SOAP::Header->name('To' => $self->get_url )->prefix("a")->type(''),
                                        SOAP::Header->name('ResourceURI' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                                        SOAP::Header->name("ReplyTo" => \SOAP::Header->value(
                                                SOAP::Header->name('Address' => "http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                                ),
                                        )->prefix("a"),
                                        SOAP::Header->name('Action' => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Receive")->attr({ "s:mustUnderstand" => "true" })->prefix("a")->type(''),
                                        SOAP::Header->name('MaxEnvelopeSize' => "153600")->attr({ "s:mustUnderstand" => "true" })->prefix("w")->type(''),
                                        SOAP::Header->name('MessageID' => "uuid:" . $self->_new_uuid)->prefix("a")->type(''),
                                        SOAP::Header->name('Locale' => '')->attr({ "xml:lang" => "en-US","s:mustUnderstand" => "false" })->prefix("w")->type(''),
                                        SOAP::Header->name("SelectorSet" => \SOAP::Header->value(
                                                SOAP::Header->name('Selector' => "$create_uid")->attr({ "Name" => "ShellId" })->prefix("w")->type(''),
                                                ),
                                        )->prefix("w")->type(''),
                                        SOAP::Header->name("OptionSet" =>
                                                \SOAP::Header->value(
                                                        SOAP::Header->name(Option => "TRUE")->attr({ Name => "WSMAN_CMDSHELL_OPTION_KEEPALIVE" })->prefix("w")->type(''),
                                                )->type(''),
                                        )->attr({ "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" })->prefix("w")->type(''),
                                        SOAP::Header->name('OperationTimeout' => "PT$timeout.000S")->prefix("w")->type(''),
                                   ],
        body                    => [
                                        SOAP::Data->name( "Receive" => undef )->attr({ "xmlns:rsp" => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell", SequenceId => 0 })->prefix("rsp")->type(''),
                                        SOAP::Data->name( "DesiredStream" => "stdout stderr" )->attr({ CommandId => "$command_uid" })->prefix("rsp")->type(''),
                                   ],
    );

    my $close_command_state = (ref($close) eq "ARRAY")
        ? $close
        : [ $close ];

    my $check_close_command_state = pop(@$close_command_state);
    unless ($check_close_command_state) {
        _set_errstr("Failed step 4/4 couldn't pop final CommandState");
        return undef;
    }

    unless (defined($check_close_command_state->{ "rsp:ExitCode" })) {
        my $add_error = '';
        if ($check_close_command_state->{ "rsp:ExitCode" }) {
            $add_error = "Completed WinRM request but final call returned non-zero value";
            _set_errstr("Failed step 4/4 $add_error - " . $SOAP::WinRM::errstr);
            return undef;
        }
    }

#    unless ($close &&
#        $close->{ "rsp:ReceiveResponse" } &&
#        $close->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" } &&
#        defined($close->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }{ "rsp:ExitCode" })) {
#
#        my $add_error = '';
#        $add_error = "Completed WinRM request but final call returned non-zero value"
#                if ($close->{ "rsp:ReceiveResponse" }{ "rsp:CommandState" }{ "rsp:ExitCode" });
#        _set_errstr("Failed step 4/4 $add_error - " . $SOAP::WinRM::errstr);
#        return undef;
#    }

    return wantarray
        ? ($exit_code, $stream_data->{ stdout }, $stream_data->{ stderr })
        : $exit_code;
}


=head2 _make_call()

UPDATE:
We added Kerberos Authentication for Login with Domains Users.

You only needs to configure Kwerberos on your Linux Sever.
Something like:

~$ vi /etc/krb5.conf
[realms]
    EXAMPLE.COM = {
        kdc = ad.example.com:88
        admin_server = ad.exampe.com:749
    }
[domain.realm]
    example.com = EXAMPLE.COM
    example.com = EXAMPLE.COM

Then...

~$ kinit testuser@EXAMPLE.COM

=cut


sub _make_call {
    my $self = shift;
    my $vars = $_[0] && ref($_[0]) eq "HASH" ? shift : { @_ };

    # Get Timout
    my $timeout = $self->timeout;

    my $headers = $vars->{ headers } || [];
    my $body = $vars->{ body } || [];
    my $new_connection = $vars->{ new_connection } || undef;

    # Any extra namespaces
    my $envelope_namespaces = $vars->{ envelope_namespaces } || [];


    # Create Soap Object and set vars
    my $request = $self->_soap_object;
    $request->proxy($self->get_url, timeout => $timeout);
    $request->envprefix("s");
    $request->readable(1);

    # soapversion not required anymore, setting Content-Type header performs better
    # $request->soapversion("1.2");
    $request->transport->http_request->header('Content-Type' => 'application/soap+xml');

    # Set specific namespaces that WinRM requires
    my $serializer = $request->serializer();
    $serializer->register_ns( 'http://www.w3.org/2003/05/soap-envelope', 's' );
    foreach my $envelope_namespace (@$envelope_namespaces) {
            $serializer->register_ns( @$envelope_namespace );
    }

    # Set Authorization
    our $username = $self->{ username };
    our $password = $self->{ password };
    
    
    
    ## Added for Kerberos Authentication ##
    my $domain = $self->{ domain };
    
    if ( $domain ) {
        if ( $self->{ kerberos } ) {
            use Authen::Simple::Kerberos;
            
            my $kerberos = Authen::Simple::Kerberos->new(
                realm => $domain
            );
            
            unless ( $kerberos->authenticate( $username, $password ) ) {
                _set_errstr( ": Returned code: 401 (401 Unauthorized)" );
                return undef;
            }
        }
        else {
            ## NTLM Authentication. (Maybe I don't do that in close future)
            _set_errstr( ": Returned code: TLM authentication is not implemented yet" );
            return undef;
        }
    }
    ## Added for Kerberos Authentication ##
    
    
    
    sub SOAP::Transport::HTTP::Client::get_basic_credentials {
        return $username => $password;
    }



    # If the calling method specifies an ARRAYREF of SOAP::Header objects,
    # the header block of the SOAP call will be created for that, however if
    # there are no headers required, WinRM will error about invalid or missing headers
    # so we throw in some dummy headers
    unless (scalar(@$headers)) {
        $headers = [ SOAP::Header->name('WinRM' => "Is a pain")->type('') ];
    }

    # Make Call
    my $response = undef;
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm ($timeout+2);
        $response = $request->call(
            @$headers,
            @$body,
        );
        alarm 0;
    };

    if ($@) {
        _set_errstr("Failed to contact WinRM: $@");
        return undef;
    }

    do { _set_errstr("Failed to contact $self->{ host } - Connection timed out"); return undef }
    unless $response;


    # We've discovered a fault, try and get as much information about it as possible
    if ($response->fault) {
        if ($response->faultstring) {
            _set_errstr("Failed to contact WinRM: " . $response->faultstring);
            return undef;
        }
        my $rm_error = $response->fault;
        _debug($rm_error);

        my $error = "";
        $error .= $rm_error->{ Reason }{ Text } if ($rm_error->{ Reason }{ Text });
        $error .= $rm_error->{ Detail }{ WSManFault }{ Message } if ($rm_error->{ Detail }{ WSManFault }{ Message });
        _set_errstr($error);
        return undef;
    }


    # It appears that SOAP::SOM isn't very good at parsing complex Data structures, vital data is missing,
    # Instead, fetch the raw XML and use XML::Simple to get a data structure
    if (    $response &&
            $response->{ _context } &&
            $response->{ _context }{ _transport } &&
            $response->{ _context }{ _transport }{ _proxy } &&
            $response->{ _context }{ _transport }{ _proxy }{ _http_response } &&
            $response->{ _context }{ _transport }{ _proxy }{ _http_response }{ _content }) {
                    my $xml = eval {
                            XMLin($response->{ _context }{ _transport }{ _proxy }{ _http_response }{ _content });
                    };
                    if ($@) {
                            _set_errstr("Failed to parse SOAP respose: $@");
                            return undef;
                    }
                    # print "BODY: " . Dumper($xml->{ "s:Body" }) . "\n";
                    return $xml->{ "s:Body" };
    }
    _set_errstr("Failed to locate XML response");
    return undef;
}

sub _new_uuid {
    my $self = shift;
    my $ug = new Data::UUID;
    return $ug->create_str;
}

sub _set_errstr {
    my $error = shift || "Unknown error";
    $SOAP::WinRM::errstr = $error;
    cluck $error if ($SOAP::WinRM::DEBUG);
    return 1;
}

sub _soap_object {
    my $self = shift;
    my $new_connection = shift;

    if (!$self->{ SOAPOBJ } || $new_connection) {
        $self->{ SOAPOBJ } = SOAP::Lite->new();
        SOAP::Lite->import(+trace => 'all') if ($SOAP::WinRM::DEBUG && $SOAP::WinRM::DEBUG > 1);
    }

    return $self->{ SOAPOBJ };
}

# Output Debug information depending on DEBUG level
sub _debug {
    return 1
        unless $SOAP::WinRM::DEBUG;
    my $message = shift || "Unknown Message";
    warn $message;
}



1;





=head1 WINRM SETUP

I strongly recomment using HTTPS and not HTTP so that there is some security when
contacting remote hosts. Not doing so could reveal usernames and passwords to
anyone intercepting the traffic.

Do the following to setup WinRM so that SOAP::WinRM can connect to it.

=over 4

=item * Support for WinRM Stack 1.1 is enabled, but from what I can see the 1.1
stack is buggy, ideally update to 2.0, and if possible to Windows 2008R2

=item * Create a certificate (can be self signed) to secure connection using HTTPS
and add it into your local computer's certificate store.

=item * Configure WinRM

  winrm quickconfig -transport:https

=item * Set WinRM to allow HTTP Basic Auth Authentication.

  winrm set winrm/config/service/auth @{Basic="true"}

=item * Open Firewall

=back

Your WinRM setup is setup for HTTPS connections using Basic Auth.

=head1 Command Timeout

Executing commands are limited by the winrm/config/MaxTimeoutms value, if you get a
response advising the the OperationTimeout value was reached, increase the timeout value
used on the SOAP::WinRM object AND increase the value on the remote server

  winrm get winrm/config | fndstr MaxTimeoutms
       MaxTimeoutms = 60000

  winrm set winrm/config @{MaxTimeoutms="100000"}

  winrm get winrm/config | fndstr MaxTimeoutms
       MaxTimeoutms = 100000


=head1 BUGS

=over 4

=item * None reported yet... give it time

=back

=head1 TODO

=over 4

=item * Implement Kerberos Authentication to allow domain admin login

=item * UPDATE: Kerberos Authentication was Implemented to allow domain admin login

=item * Implement NTLM authentication

=back

=head1 LICENSE

Copyright (C) Alasdair Keyes.

New Features like Kerberos and use of PowerShell character filters: Hugo Maza

This software is released under the GPLv2 License
http://opensource.org/licenses/GPL-2.0
