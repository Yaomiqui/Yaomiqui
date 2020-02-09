%MSG = loadLang('config');
my $html;



unless ( $input{submod} ) {
	$html .= qq~<div class="contentTitle">$MSG{Configuration_Variables}</div>~ unless $input{'shtl'};
	
	my %MSG_CNF = msg_config_vars();
	
	connected();
	my $sth = $dbh->prepare("SELECT * FROM configVars");
	$sth->execute();
	my $conf = $sth->fetchall_arrayref;
	$sth->finish;
	
	$html .= qq~<div id="miquiloniToolTip"></div><table cellpadding="0" cellspacing="0" style="padding-bottom: 200px">~;
	for my $i ( 0 .. $#{$conf} ) {
		my $inputVarValue;
		
		if ( $conf->[$i][1] eq 'SHOW_LOGS_IN_FRAME' ) {
			my $selected = $conf->[$i][2] eq '0' ? 'selected' : '';
			$inputVarValue = qq~<select name="varValue"><option value="1">1</option><option value="0" $selected>0</option></select>~;
		}
        elsif ( $conf->[$i][1] eq 'DESIGNER_SET_MODE' ) {
			my $selected = $conf->[$i][2] eq 'laic' ? 'selected' : '';
			$inputVarValue = qq~<select name="varValue"><option value="nerd">nerd</option><option value="laic" $selected>laic</option></select>~;
		}
        elsif ( $conf->[$i][1] eq 'STATUS_AFTER_TIMEOUT' ) {
			my $selected;
			$inputVarValue = qq~<select name="varValue">~;
			foreach my $status ( 'Rejected', 'Resolved', 'Failed', 'Pending', 'Canceled' ) {
				$selected = 'selected' if $selected = $conf->[$i][2] eq $status;
				$inputVarValue .= qq~<option value="$status" $selected>$status</option>~;
			}
			$inputVarValue .= qq~</select>~;
		}
		else {
			$inputVarValue .= qq~<input type="text" name="varValue" value="$conf->[$i][2]">~;
		}
		
		$html .= qq~<tr><td>$conf->[$i][1] &nbsp; </td>
		<td>
			<form method="POST" action="index.cgi">
			<input type="hidden" name="mod" value="config">
			<input type="hidden" name="submod" value="save_config">
			<input type="hidden" name="idConfigVar" value="$conf->[$i][0]">
			<img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG_CNF{$conf->[$i][1]}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
			$inputVarValue
		</td>
		<td>
		&nbsp; <button class="blueLightButton">$MSG{Save}</button>
		</form>
		</td>
		~;
	}
	$html .= qq~</table>~;
}


if ( $input{submod} eq 'save_config' ) {
	connected();
	my $sth = $dbh->prepare(qq~UPDATE configVars SET varValue='$input{varValue}' WHERE idConfigVar='$input{idConfigVar}'~);
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("UPDATE:configVars:varValue=$input{varValue}");
	
	print "Location: index.cgi?mod=config\n\n";
}


if ( $input{submod} eq 'save_env_var' ) {
	connected();
	my $sth = $dbh->prepare(qq~UPDATE environmentVars SET varValue='$input{varValue}' WHERE idEnvVar='$input{idEnvVar}'~);
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("UPDATE:environmentVars:varValue=$input{varValue}");
	
	print "Location: index.cgi?mod=config&submod=configEnvVars\n\n";
}


if ( $input{submod} eq 'configEnvVars' ) {
	$html .= qq~<div class="contentTitle">$MSG{Environment_Variables}</div>~ unless $input{'shtl'};
	
	connected();
	my $sth = $dbh->prepare("SELECT * FROM environmentVars");
	$sth->execute();
	my $conf = $sth->fetchall_arrayref;
	$sth->finish;
	
	$html .= qq~<table cellpadding="0" cellspacing="0">~;
	for my $i ( 0 .. $#{$conf} ) {
		$html .= qq~<tr>
		<td>$conf->[$i][1]
			<form method="POST" action="index.cgi">
			<input type="hidden" name="mod" value="config">
			<input type="hidden" name="submod" value="save_env_var">
			<input type="hidden" name="idEnvVar" value="$conf->[$i][0]">
		</td>
		<td>
			<input type="text" name="varValue" value="$conf->[$i][2]">
		</td>
		<td>
			&nbsp; <button class="blueLightButton">$MSG{Save}</button>
		</form>
		</td>
		<td>
			<a class="redButton" href="index.cgi?mod=config&submod=delete_record&idEnvVar=$conf->[$i][0]" target="_top" onclick="return confirm('$MSG{Are_you_sure_you_want_to_continue_deleting_this_record}: $conf->[$i][1] ?')">$MSG{Delete}</a>
		</td>
		</tr>
		~;
	}
	
	$html .= qq~<tr><td><br><br><br>$MSG{Create_New_Variable}:</td><td>&nbsp;</td><td>&nbsp;</td></tr>
	<tr><td>
		<form method="POST" action="index.cgi">
		<input type="hidden" name="mod" value="config">
		<input type="hidden" name="submod" value="add_new_env_var">
		<input type="text" name="varName" value="">
	</td>
	<td>
		<input type="text" name="varValue" value="">
	</td>
	<td>
	&nbsp; <button class="blueLightButton">$MSG{Create_New}</button>
	</form>
	</td>
	<td>&nbsp;</td></tr>
	~;
	
	$html .= qq~</table>~;
}


if ( $input{submod} eq 'add_new_env_var' ) {
	if ( $input{varName} ) {
		connected();
		my $insert_string = "INSERT INTO environmentVars (varName, varValue) VALUES (?, ?)";
		$sth = $dbh->prepare("$insert_string");
		$sth->execute($input{varName}, $input{varValue});
		$sth->finish;
		$dbh->disconnect if $dbh;
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("NEW:environmentVars:varName=$input{varName},varValue=$input{varValue}");
	}
	
	print "Location: index.cgi?mod=config&submod=configEnvVars\n\n";
}


if ( $input{submod} eq 'delete_record' ) {
	connected();
	$dbh->do("LOCK TABLES environmentVars WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM environmentVars WHERE idEnvVar = '$input{idEnvVar}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("DELETE:environmentVars:idEnvVar=$input{idEnvVar}");
	
	print "Location: index.cgi?mod=config&submod=configEnvVars\n\n";
}


return $html;
1;


sub msg_config_vars {
	my %AS = (
		'PROC_MAX_PARALLEL'		=> $MSG{PROC_MAX_PARALLEL},
		'SHOW_LOGS_IN_FRAME'	=> $MSG{SHOW_LOGS_IN_FRAME},
		'SHOW_PER_PAGE'			=> $MSG{SHOW_PER_PAGE},
		'REFRESH_RATE'			=> $MSG{REFRESH_RATE},
		'DESIGNER_SET_MODE'		=> $MSG{DESIGNER_SET_MODE},
		'CRITICAL_PROC'			=> $MSG{CRITICAL_PROC},
		'COOKIE_TERM'			=> $MSG{COOKIE_TERM},
		'STATUS_AFTER_TIMEOUT'	=> $MSG{STATUS_AFTER_TIMEOUT},
		'CONNECTTIMEOUT'		=> $MSG{CONNECTTIMEOUT},
		'TIMEOUT'				=> $MSG{TIMEOUT},
		'SSH_TIMEOUT'			=> $MSG{SSH_TIMEOUT},
		'ENVIRONMENT'			=> $MSG{ENVIRONMENT},
		'WINRM_CONNECTOR'		=> $MSG{WINRM_CONNECTOR},
		'WINRM_PROTOCOL'		=> $MSG{WINRM_PROTOCOL}
	);
	
	return %AS;
}
