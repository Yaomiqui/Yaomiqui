%MSG = loadLang('settings');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Settings_for_some_things}</div>~ unless $input{'shtl'};

unless ( $input{submod} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM users WHERE username = '$username'");
	$sth->execute();
	my @data = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my @themes = `ls $VAR{themes_path}`;
	chomp @themes;
	
	my $selected;
	
	my $themeSelect;
	foreach my $theme ( @themes ) {
		$selected = $data[14] eq $theme ? 'selected' : '';
		$themeSelect .= qq~<option value="$theme" $selected>$theme</option>~;
	}
	$selected = undef;
	
	my @langs = `ls $VAR{lang_dir}`;
	chomp @langs;
	
	my $langageSelect;
	foreach my $lang ( @langs ) {
		$selected = $data[15] eq $lang ? 'selected' : '';
		$langageSelect .= qq~<option value="$lang" $selected>$lang</option>~;
	}
	$selected = undef;
	
	my $activeSelect;
	$selected = $data[16] ? 'selected' : '';
	$activeSelect .= qq~<option value="1" $selected>Yes</option>~;
	$selected = $data[16] ? '' : 'selected';
	$activeSelect .= qq~<option value="0" $selected>No</option>~;
	
	use Crypt::Babel;
	my $crypt = new Babel;
	$data[2]= $crypt->decode($data[2], $encKey);
	
	$html .= qq~
		<script>
		function openModal(modalId) {
				document.getElementById(modalId).style.display = "block";
			}
			function closeModal(modalId) {
				document.getElementById(modalId).style.display = "none";
			}
			function openModalRedirect(modalId, htmlink, targetLink) {
				document.getElementById(modalId).style.display = "block";
				window.open(htmlink, targetLink);
			}
			function openModalCloseAndRedirect(modalIdToOpen, modalIdToClose, htmlink, targetLink) {
				document.getElementById(modalIdToClose).style.display = "none";
				document.getElementById(modalIdToOpen).style.display = "block";
				window.open(htmlink, targetLink);
			}
		</script>
		
		<form method="get" action="index.cgi" target="_top">
		<input type="hidden" name="mod" value="settings">
		<input type="hidden" name="submod" value="save_record">
		<input type="hidden" name="idUser" value="$data[0]">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Edit_my_record}: <b>$data[1]</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		<tr><td align="right" width="30%">$MSG{Password}: </td><td width="70%"><input type="password" name="pwd1" value="$data[2]" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">$MSG{Password_again}: </td><td width="70%"><input type="password" name="pwd2" value="$data[2]" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">$MSG{Name}: </td><td width="70%"><input type="text" name="name" value="$data[3]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Last_Name}: </td><td width="70%"><input type="text" name="lastName" value="$data[4]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Mothers_Last_Name}: </td><td width="70%"><input type="text" name="mothersLastName" value="$data[5]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Email}: </td><td width="70%"><input type="text" name="email" value="$data[7]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Email}: </td><td width="70%"><input type="text" name="secondaryEmail" value="$data[8]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Phone}: </td><td width="70%"><input type="text" name="phone" value="$data[9]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Phone}: </td><td width="70%"><input type="text" name="secondaryPhone" value="$data[10]"></td></tr>
		<!--<tr><td align="right" width="30%">$MSG{Theme}: </td><td width="70%">
		<select name="theme">
		$themeSelect
		</select>
		</td></tr>-->
		<tr><td align="right" width="30%">$MSG{Language}: </td><td width="70%">
		<select name="language">
		$langageSelect
		</select>
		</td></tr>
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter">
		<tr><td>
			<div id="myModalRedirectSave" class="confirm"><div class="confirm-content">
			$MSG{Alert}<hr class="confirm-header">
			$MSG{Sending_form}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
		<button class="blueLightButton" onClick="return openModal('myModalRedirectSave');">$MSG{Save}</button>
		</table>
		
		</form>
		
		<br><br>
		<br><br>
	~;
}


if ( $input{submod} eq 'save_record' ) {
	my $prepare;
	
	if ( $input{pwd1} and ($input{pwd1} eq $input{pwd2}) ) {
		# $prepare = "UPDATE users SET name=?, lastName=?, maidenName=?, idEmployee=?, email=?, secondaryEmail=?, phone=?, secondaryPhone=?, costCenterId=?, groupId=?, secondaryGroupId=?, theme=?, language=?, active=?, password=? WHERE idUser=?";
		use Crypt::Babel;
		my $crypt = new Babel;
		my $pwdEnc = $crypt->encode($input{pwd1}, $encKey);
		
		connected();
		my $sth = $dbh->prepare("UPDATE users SET 
		password='$pwdEnc',
		name='$input{name}',
		lastName='$input{lastName}',
		mothersLastName='$input{mothersLastName}',
		email='$input{email}',
		secondaryEmail='$input{secondaryEmail}',
		phone='$input{phone}',
		secondaryPhone='$input{secondaryPhone}',
		
		language='$input{language}'
		WHERE idUser='$input{idUser}'");
		$sth->execute();
		$sth->finish;
		$dbh->disconnect if $dbh;
		#theme='$input{theme}',
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("UPDATE:MyAccount:name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};theme=$input{theme};language=$input{language}");
		
		print "Location: index.cgi?mod=settings\n\n";
		
		
	} else {
		$html .= qq~<font color="#BB0000">Passwords does not match</font>~;
	}
}


return $html;
1;

