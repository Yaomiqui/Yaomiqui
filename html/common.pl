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

sub get_theme {
	my $module = shift;
	my $theme = 'classic_cloud';
	
	if ( $username ne 'Guest' ) {
		connected();
		my $sth = $dbh->prepare("SELECT theme FROM users WHERE username = '$username'");
		$sth->execute();
		($theme) = $sth->fetchrow_array;
		$sth->finish;
		$dbh->disconnect if ($dbh);
	}
	return $theme;
}

sub getEncKey {
	my $o = tie my @array, 'Tie::File', $VAR{enc_key} or die "I can't open yaomiqui encrypted key: $VAR{enc_key}\n";
	my $encKey = $array[0];
	untie @array;
	return $encKey;
}

sub connected {
	use DBI;
	$dbh = DBI->connect("DBI:mysql:$VAR{'DB'}:$VAR{'DBHOST'}", $VAR{'DBUSER'}, $VAR{'DBPASSWD'}) or die "Error... $DBI::errstr mysql_error()<br>";
}

sub get_permissions {
	connected();
	my $sth = $dbh->prepare("SELECT permissions.* FROM users, permissions WHERE users.username = '$username' and users.idUser = permissions.idUser");
	$sth->execute();
	my @perm = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my %PERM;
	$PERM{login} = 1;
	$PERM{logout} = 1;
	$PERM{init} = $perm[2];
	$PERM{overview} = $perm[3];
	$PERM{design} = $perm[4];
	$PERM{accounts} = $perm[5];
	$PERM{accounts_edit} = $perm[6];
	$PERM{settings} = $perm[7];
	$PERM{tickets} = $perm[8];
	$PERM{tickets_form} = $perm[9];
	$PERM{logs} = $perm[10];
	$PERM{charts} = $perm[11];
	$PERM{reports} = $perm[12];
	$PERM{about} = $perm[13];
	
	return %PERM;
}

sub vermod {
	require "$VAR{'modules_dir'}/$module_file";
}

sub loadLang {
	my $module = shift;
	my $lang = 'en_US';
	
	if ( $username ne 'Guest' ) {
		connected();
		my $sth = $dbh->prepare("SELECT language FROM users WHERE username = '$username'");
		$sth->execute();
		($lang) = $sth->fetchrow_array;
		$sth->finish;
		$dbh->disconnect if ($dbh);
	}
	
	open (LANGFILE, "<$VAR{lang_dir}/$lang") or "Error: I can't open $lang file. $!";
	my @array = <LANGFILE>;
	close LANGFILE;
	chomp @array;
	
	my %MSG;
	my $takeLang;
	
	foreach my $line( @array ) {
		$line =~ s/\n$//;
		$line =~ s/^\s+//;
		$line =~ s/\s+\n//;
		$line =~ s/\n\n/\n/;
		$line =~ s/\s+\=\s+/\=/;
		next if $line =~ /^#/;
		
		if ( $line eq "\[$module\]" ) {
			$takeLang = 1;
			next;
		}
		
		if ( $takeLang ) {
			if ( $line =~ /^\[/ ) {
				return %MSG;
				last;
			}
			
			my ($key, $val) = split(/\=/, $line, 2);
			$MSG{$key} = $val;
		}
	}
}
sub crypt_ {my $text=shift;$text =~ tr{\x20-\x7d}{\x4f-\x7d\x20-\x4e};return $text}
sub get_session {
	my $vendor = "yaomiqui";
	my $cookie_sesion;
	my $username = 'Guest';
	
	my @nvpairs=split(/; /, $ENV{HTTP_COOKIE});
	foreach my $pair (@nvpairs) {
		#yaomiqui=jk345k34h3l
		my ($cookie_vendor, $coockie_datos) = split(/=/, $pair);
		if ($cookie_vendor eq $vendor)	{
			$cookie_sesion = $coockie_datos;
		}
	}
	
	open (SESSION, "<$VAR{session_file}");	#session|username
		while (<SESSION>) {
			my ($session, $usernamesession) = split(/\|/, $_);
			chomp $usernamesession;
			if ( $session eq $cookie_sesion ) {
				$username = $usernamesession;
				last;
			}
		}
	close SESSION;
	
	return $username;
}

sub get_cookie_Sector {
	my $vendor = "yaomiquiSector";
	my $cookie_Sector;
	
	my @nvpairs=split(/; /, $ENV{HTTP_COOKIE});
	
	foreach my $pair (@nvpairs) {
		#yaomiquiSector=1
		my ($cookie_vendor, $coockie_datos) = split(/=/, $pair);
		if ($cookie_vendor eq $vendor)	{
			$cookie_Sector = $coockie_datos;
		}
	}
	
	return $cookie_Sector;
}

sub set_cookie_Sector {
	my $vendor = "yaomiquiSector";
	my $cookie_Sector = shift;
	
	# use CGI qw/:standard/;
    use CGI::Cookie;
    
	$c = CGI::Cookie->new(
		-name    =>  $vendor,
		-value   =>  $cookie_Sector,
		-expires =>  '+3M'
	);
	
	 print "Set-Cookie: $c\n";
}

sub login {
	return qq~
	<!DOCTYPE HTML PUBLIC "//W3C//DTD HTML 4.01//EN">
	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>LogIn :: YAOMIQUI :: Automation Tool</title>
			<meta name="keywords" content="automation,tasks,repetitive" />
			<meta name="description" content="Automation for repetitive task" />
		</head>
		<style>
			html {
				font-family: verdana, sans, sans-serif, helvetica;
				font-size: 95%;
				color: #292929;
				margin: 0px;
				padding: 0px;
			}
	
			body {
				font-family: verdana, sans, sans-serif, helvetica;
				font-size: 95%;
				color: #292929;
				margin: 0px;
				padding: 0px;
				background-color: #E9E9E9;
			}
			.topContent {
				border-radius: 10px 10px 0px 0px;
				background: #25414E;
				width: 500px;
				margin: auto;
				margin-top: 150px;
				color: #FFF;
				font-size: 14px;
				font-weight: bold;
				padding: 12px 20px;
				border: 1px solid #417690;
			}
			.content {
				border-radius: 0px 0px 10px 10px;
				background: #417690;
				width: 500px;
				margin: auto;
				color: #FFF;
				padding: 70px 20px;
				border: 1px solid #417690;	/*4183F4*/
				/*min-height: 100px;*/
				/*vertical-align: middle;*/
				text-align: center;
			}
			input[type=text] {
				padding: 8px 10px;
				border: 1px solid #E5E5E5;
				border-radius: 4px;
				width: 200px;
				-webkit-transition: 0.5s;
				transition: 0.5s;
				outline: none;
			}
			input[type=text]:focus { 
				background-color: #F4FCFF;
				border: 1px solid #BDBDBD;
			}
			input[type=password] {
				padding: 8px 10px;
				border: 1px solid #E5E5E5;
				border-radius: 4px;
				width: 200px;
				-webkit-transition: 0.5s;
				transition: 0.5s;
				outline: none;
			}
			input[type=password]:focus { 
				background-color: #F4FCFF;
				border: 1px solid #BDBDBD;
			}
			input[type=button], input[type=submit], input[type=reset] {
				padding: 6px 10px;
				border-radius: 2px;
				border: 1px solid #D3D3D3;
				background-color: #E2E2E2;
				cursor: pointer;
			}
		</style>
		<body>
			<div class="topContent">
				$MSG{Yaomiqui_Login}
			</div>
			
			<div class="content">
				<form method="post" action="index.cgi">
				<input type="hidden" name="mod" value="login">
				<table cellpadding="0" cellspacing="0" align="center" style="margin: auto;">
					<tr><td align="left">$MSG{Username}</td></tr>
					<tr><td align="left"><input type="text" name="user" value="$input{user}" class="LogIn" autofocus placeholder="Your username..."></td></tr>
					<tr><td align="left">&nbsp;</td></tr>
					<tr><td align="left">$MSG{Password}</td></tr>
					<tr><td align="left"><input type="password" name="pass" class="LogIn" placeholder="Your password..."></td></tr>
					<tr><td align="left">&nbsp;</td></tr>
					<tr><td align="right"><input type="submit" value="       $MSG{Log_In}       "></td></tr>
				</table>
				</form>
			</div>
			
		</body>
	</html>
	 ~;
}

1;
