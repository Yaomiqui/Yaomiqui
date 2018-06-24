my $user = $input{user};
my $pass = $input{pass};
my $vendor = "yaomiqui";
my $num_sesion = rand(10);

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
			# print "Set-Cookie: $vendor=$num_sesion \n";
			$cookie = new CGI::Cookie(
				-name    => $vendor,
				-value   => $num_sesion,
				-expires =>  $VAR{COOKIE_TERM},
			);
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
		# use Tie::File;
		# tie @array, 'Tie::File', $VAR{session_file} or no_open_file();
		# push @array, $num_sesion . '|' . shift . "\n";
		# untie @array;
		open(SESSION, ">>$VAR{session_file}") or no_open_file();
			print SESSION $num_sesion . '|' . shift . "\n";
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
