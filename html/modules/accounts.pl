%MSG = loadLang('accounts');

my $html;
$html .= qq~<div class="contentTitle">$MSG{User_Accounts}</div>~ unless $input{'shtl'};



if ( $input{submod} eq 'delete_record' ) {
	connected();
	$dbh->do("LOCK TABLES users WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM users WHERE idUser = '$input{idUser}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	$dbh->do("LOCK TABLES permissions WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM permissions WHERE idUser = '$input{idUser}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("DELETE:Account:idUser=$input{idUser}");
	
	print "Location: index.cgi?mod=accounts\n\n";
}



if ( $input{submod} eq 'save_record' ) {
	my $prepare;
	
	# if ( $input{pwd1} ) {
		if ( $input{pwd1} eq $input{pwd2} ) {
			# $prepare = "UPDATE users SET name=?, lastName=?, maidenName=?, idEmployee=?, email=?, secondaryEmail=?, phone=?, secondaryPhone=?, costCenterId=?, groupId=?, secondaryGroupId=?, theme=?, language=?, active=?, password=? WHERE idUser=?";
			use Crypt::Babel;
			my $crypt = new Babel;
			my $pwdEnc = $crypt->encode($input{pwd1}, $encKey);
			
			$input{costCenterId} = '0' unless $input{costCenterId};
			$input{groupId} = '0' unless $input{groupId};
			$input{secondaryGroupId} = '0' unless $input{secondaryGroupId};
			
			$input{name} =~ s/<|>|script|alert//gi;
			$input{lastName} =~ s/<|>|script|alert//gi;
			$input{mothersLastName} =~ s/<|>|script|alert//gi;
			$input{email} =~ s/<|>|script|alert//gi;
			$input{secondaryEmail} =~ s/<|>|script|alert//gi;
			$input{phone} =~ s/<|>|script|alert//gi;
			$input{secondaryPhone} =~ s/<|>|script|alert//gi;
			$input{idEmployee} =~ s/<|>|script|alert//gi;
			$input{costCenterId} =~ s/<|>|script|alert//gi;
			$input{groupId} =~ s/<|>|script|alert//gi;
			$input{secondaryGroupId} =~ s/<|>|script|alert//gi;
			
			connected();
			
			my $sth;
			if ( $input{pwd1} ) {
				$sth = $dbh->prepare("UPDATE users SET 
				password='$pwdEnc',
				name='$input{name}',
				lastName='$input{lastName}',
				mothersLastName='$input{mothersLastName}',
				idEmployee='$input{idEmployee}',
				email='$input{email}',
				secondaryEmail='$input{secondaryEmail}',
				phone='$input{phone}',
				secondaryPhone='$input{secondaryPhone}',
				costCenterId='$input{costCenterId}',
				groupId='$input{groupId}',
				secondaryGroupId='$input{secondaryGroupId}',
				theme='classic_cloud',
				language='$input{language}',
				active='$input{active}' 
				WHERE idUser='$input{idUser}'");
			} else {
				$sth = $dbh->prepare("UPDATE users SET 
				name='$input{name}',
				lastName='$input{lastName}',
				mothersLastName='$input{mothersLastName}',
				idEmployee='$input{idEmployee}',
				email='$input{email}',
				secondaryEmail='$input{secondaryEmail}',
				phone='$input{phone}',
				secondaryPhone='$input{secondaryPhone}',
				costCenterId='$input{costCenterId}',
				groupId='$input{groupId}',
				secondaryGroupId='$input{secondaryGroupId}',
				theme='classic_cloud',
				language='$input{language}',
				active='$input{active}' 
				WHERE idUser='$input{idUser}'");
			}
			
			$sth->execute();
			$sth->finish;
			
			$input{design} = '0' unless $input{design};
			$input{accounts} = '0' unless $input{accounts};
			$input{accounts_edit} = '0' unless $input{accounts_edit};
			$input{tickets} = '0' unless $input{tickets};
			$input{tickets_form} = '0' unless $input{tickets_form};
			$input{logs} = '0' unless $input{logs};
			$input{charts} = '0' unless $input{charts};
			$input{reports} = '0' unless $input{reports};
			
			my $sth1 = $dbh->prepare("UPDATE permissions SET 
			design='$input{design}',
			accounts='$input{accounts}',
			accounts_edit='$input{accounts_edit}',
			tickets='$input{tickets}',
			tickets_form='$input{tickets_form}',
			logs='$input{logs}',
			charts='$input{charts}',
			reports='$input{reports}'
			WHERE idUser='$input{idUser}'");
			$sth1->execute();
			$sth1->finish;
			
			$dbh->disconnect if $dbh;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("UPDATE:Account:idUser=$input{idUser};name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};idEmployee=$input{idEmployee};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};costCenterId=$input{costCenterId};groupId=$input{groupId};secondaryGroupId=$input{secondaryGroupId};theme=$input{theme};language=$input{language};active=$input{active};lxcservers=$input{lxcservers};lxcservers_edit=$input{lxcservers_edit};provisioning=$input{provisioning};accounts=$input{accounts};accounts_edit=$input{accounts_edit};containers=$input{containers};containers_edit=$input{containers_edit};sectors=$input{sectors};migration=$input{migration};keypairs=$input{keypairs};distros=$input{distros}");
			
			print "Location: index.cgi?mod=accounts&idUser=$input{idUser}\n\n";
			
			
		} else {
			$html .= qq~<font color="#BB0000">$MSG{Passwords_does_not_match}</font>~;
		}
	# } else {
		# $html .= qq~<font color="#BB0000">$MSG{Passwords_are_mandatory}</font>~;
	# }
}



if ( $input{submod} eq 'new_record' ) {
	
	if ( $input{username} and $input{pwd1} and $input{pwd2} ) {
		if ( $input{pwd1} eq $input{pwd2} ) {
			
			connected();
			$sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$input{username}'");
			$sth->execute();
			my ($idUserTest) = $sth->fetchrow_array;
			$sth->finish;
			
			unless ($idUserTest) {
				use Crypt::Babel;
				my $crypt = new Babel;
				my $pwdEnc = $crypt->encode($input{pwd1}, $encKey);
				
				$input{costCenterId} = '0' unless $input{costCenterId};
				$input{groupId} = '0' unless $input{groupId};
				$input{secondaryGroupId} = '0' unless $input{secondaryGroupId};
				
				$input{username} =~ s/<|>|script|alert//gi;
				$input{name} =~ s/<|>|script|alert//gi;
				$input{lastName} =~ s/<|>|script|alert//gi;
				$input{mothersLastName} =~ s/<|>|script|alert//gi;
				$input{email} =~ s/<|>|script|alert//gi;
				$input{secondaryEmail} =~ s/<|>|script|alert//gi;
				$input{phone} =~ s/<|>|script|alert//gi;
				$input{secondaryPhone} =~ s/<|>|script|alert//gi;
				$input{idEmployee} =~ s/<|>|script|alert//gi;
				$input{costCenterId} =~ s/<|>|script|alert//gi;
				$input{groupId} =~ s/<|>|script|alert//gi;
				$input{secondaryGroupId} =~ s/<|>|script|alert//gi;
				
				# $dbh->do("LOCK TABLES users WRITE");
				my $insert_string = qq~INSERT INTO users (
				username, password, name, lastName, mothersLastName, idEmployee, email, secondaryEmail, phone, secondaryPhone, costCenterId, groupId, secondaryGroupId, theme, language, active
				) VALUES (
				'$input{username}',
				'$pwdEnc',
				'$input{name}',
				'$input{lastName}', 
				'$input{mothersLastName}',
				'$input{idEmployee}',
				'$input{email}',
				'$input{secondaryEmail}',
				'$input{phone}', 
				'$input{secondaryPhone}',
				'$input{costCenterId}',
				'$input{groupId}',
				'$input{secondaryGroupId}',
				'classic_cloud',
				'$input{language}',
				'$input{active}')~;
				$sth = $dbh->prepare($insert_string);
				$sth->execute();
				$sth->finish;
				# $dbh->do("UNLOCK TABLES");
						$html .= "$insert_string<br>";
				
				$sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$input{username}'");
				$sth->execute();
				my ($idUserNew) = $sth->fetchrow_array;
				$sth->finish;
				
				$input{design} = '0' unless $input{design};
				$input{accounts} = '0' unless $input{accounts};
				$input{accounts_edit} = '0' unless $input{accounts_edit};
				$input{tickets} = '0' unless $input{tickets};
				$input{tickets_form} = '0' unless $input{tickets_form};
				$input{logs} = '0' unless $input{logs};
				$input{charts} = '0' unless $input{charts};
				$input{reports} = '0' unless $input{reports};
				
				$insert_string = qq~INSERT INTO permissions (
				idUser, design, accounts, accounts_edit, tickets, tickets_form, logs, charts, reports
				) VALUES (
				'$idUserNew',
				'$input{design}',
				'$input{accounts}',
				'$input{accounts_edit}',
				'$input{tickets}',
				'$input{tickets_form}',
				'$input{logs}',
				'$input{charts}',
				'$input{reports}')~;
				$sth = $dbh->prepare("$insert_string");
				$sth->execute();
				$sth->finish;
						$html .= "<br>$insert_string<br><br>";
				
				$dbh->disconnect if $dbh;
				
				my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
				$log->Log("NEW:Account:idUser=$input{idUser};username=$input{username};name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};idEmployee=$input{idEmployee};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};costCenterId=$input{costCenterId};groupId=$input{groupId};secondaryGroupId=$input{secondaryGroupId};theme=$input{theme};language=$input{language};active=$input{active};lxcservers=$input{lxcservers};lxcservers_edit=$input{lxcservers_edit};provisioning=$input{provisioning};accounts=$input{accounts};accounts_edit=$input{accounts_edit};containers=$input{containers};containers_edit=$input{containers_edit};sectors=$input{sectors};migration=$input{migration};keypairs=$input{keypairs};distros=$input{distros}");
				
				print "Location: index.cgi?mod=accounts\n\n";
				
			} else {
				$html .= qq~<font color="#BB0000">$MSG{Username_alredy_exists}</font><br /><br /><br /><br />~;
			}
		} else {
			$html .= qq~<font color="#BB0000">$MSG{Passwords_does_not_match}</font><br /><br /><br /><br />~;
		}
	} else {
		$html .= qq~<font color="#BB0000">$MSG{User_Name_and_Passwords_are_mandatory}</font><br /><br /><br /><br />~;
	}
}



	connected();
	$sth = $dbh->prepare("SELECT * FROM users WHERE username NOT IN ('Guest', 'admin') ORDER BY username");
	# $sth = $dbh->prepare("SELECT * FROM users ORDER BY username");
	$sth->execute();
	my $users = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	# $html .= qq~
	# <script language=javascript> 
		# function popUpUserEdition (URL){
			# window.open(URL,"edition_frame","width=820,height=600,top=10,left=100,directories=0,titlebar=0,toolbar=0,location=0,status=0,menubar=0,scrollbars=auto'); return false;")
		# }
	# </script>
	
	# <p align="right" style="padding: 0 50px 8px 0;">
	# <button class="blueLightButton" onclick="javascript:popUpUserEdition('launcher.cgi?mod=accounts_edit&idUser=&shtl=1')">$MSG{New_user}</button>
	# </p>
	$html .= qq~
	<table cellpadding="0" cellspacing="0" border="0" width="100%" class="gridTable" style="width: 100%; background-color: #FFFFFF">
		<tr>
			<td class="gridTitle">$MSG{User_Name}</td>
			<td class="gridTitle">$MSG{Name}</td>
			<td class="gridTitle">$MSG{Last_Name}</td>
			<td class="gridTitle">$MSG{Mothers_Last_Name}</td>
			<td class="gridTitle">$MSG{Email}</td>
			<td class="gridTitle">$MSG{Active}</td>
		</tr>
	~;

	for my $i ( 0 .. $#{$users} ) {
		$users->[$i][16] = 1 ? 'Yes' : 'No';
		$html .= qq~
		<tr class="gridRowContent">
			<td class="gridContent"><a href="index.cgi?mod=accounts_edit&idUser=$users->[$i][0]">$users->[$i][1]</a></td>
			<td class="gridContent">$users->[$i][3]</td>
			<td class="gridContent">$users->[$i][4]</td>
			<td class="gridContent">$users->[$i][5]</td>
			<td class="gridContent">$users->[$i][7]</td>
			<td class="gridContent">$users->[$i][16]</td>
		</tr>
		~;
	}
	
	$html .= qq~
	</table>
	<br /><br />
	~;

return $html;
1;
