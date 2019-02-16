my $user = $input{user};
my $pass = $input{pass};
my $vendor = "yaomiqui";

use Math::Random::ISAAC;
my $rng = Math::Random::ISAAC->new(time());
my $prnrand = $rng->irand();
my @PRNG = split //, $prnrand;

my @chars = ('a'..'z',@PRNG,'A'..'Z');
my $num_sesion;
$num_sesion .= $chars[int(rand(@chars))] for 1..32;

print "Location: index.cgi\n\n" unless $user;
print "Location: index.cgi?user=$user\n\n" unless $pass;

connected();
my $sth = $dbh->prepare("SELECT username, password, active FROM users WHERE username = '$user'");
$sth->execute();
my ($user_registred, $crypt_passwd, $active) = $sth->fetchrow_array;
$sth->finish;
$dbh->disconnect if ($dbh);

if ( $active ) {
	use Crypt::Babel;
	my $crypt = new Babel;
	
	if ( $user_registred eq $user) {
		if ( $crypt_passwd eq $crypt->encode($pass, $encKey) ) {
			my $cookie;
			if ( $VAR{COOKIE_TERM} ) {
				$cookie = new CGI::Cookie(
					-name    	=> $vendor,
					-value   	=> $num_sesion,
					-httponly	=> true,
					-secure		=>  1,
					-expires 	=> $VAR{COOKIE_TERM}
				);
			} else {
				$cookie = new CGI::Cookie(
					-name    	=> $vendor,
					-value   	=> $num_sesion,
					-httponly	=> true,
					-secure		=>  1
				);
			}
			print "Set-Cookie: $cookie\n";
			
			set_session_in_file($user);
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $user_registred);
			$log->Log("Login From IP " . $ENV{REMOTE_ADDR});
			print "Location: index.cgi\n\n";
		} else {
			print "Location: index.cgi?user=$input{user}\n\n";
		}
	}
	
	sub set_session_in_file {
		my $user = shift;
		
		open(SESSION, "<$VAR{session_file}") or no_open_file();
		my @SESSION = <SESSION>;
		close SESSION;
		
		open(SESSION, ">$VAR{session_file}") or no_open_file();
		foreach my $e ( @SESSION ) {
			chomp($e);
			unless ( $e =~ /\|$user$/ ) {
				print SESSION $e . "\n";
			}
		}
		print SESSION $num_sesion . '|' . $user . "\n";
		close SESSION;
	}
} else {
	print "Location: index.cgi?user=$input{user}\n\n";
}

sub no_open_file {
	print "Content-Type: text/html\n\n";
	die "I can't open session file $VAR{session_file}";
}

1;
