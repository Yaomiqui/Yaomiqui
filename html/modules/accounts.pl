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
	
	if ( $username ne 'admin' and $input{idUser} eq '1' ) {
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("UPDATE:Account:idUser=$input{idUser};HACKING ATTEMPT! $username tried to modify the admin user record!");
		
		$html .= qq~<font color="#BB0000">You cannot edit admin record</font> &nbsp; &nbsp; <a href="javascript: window.history.back();">Go Back</a>~;
	}
	elsif ( $input{pwd1} eq $input{pwd2} ) {
		
		use Crypt::Babel;
		my $crypt = new Babel;
		my $pwdEnc = $crypt->encode($input{pwd1}, $encKey);
		
		$input{costCenterId} = '0' unless $input{costCenterId};
		$input{groupId} = '0' unless $input{groupId};
		$input{secondaryGroupId} = '0' unless $input{secondaryGroupId};
		
		$input{name} = delMalCode($input{name});
		$input{lastName} = delMalCode($input{lastName});
		$input{mothersLastName} = delMalCode($input{mothersLastName});
		$input{email} = delMalCode($input{email});
		$input{secondaryEmail} = delMalCode($input{secondaryEmail});
		$input{phone} = delMalCode($input{phone});
		$input{secondaryPhone} = delMalCode($input{secondaryPhone});
		$input{idEmployee} = delMalCode($input{idEmployee});
		$input{costCenterId} = delMalCode($input{costCenterId});
		$input{groupId} = delMalCode($input{groupId});
		$input{secondaryGroupId} = delMalCode($input{secondaryGroupId});
		
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
		$input{config} = '0' unless $input{config};
		$input{alerts} = '0' unless $input{alerts};
		$input{alerts_config} = '0' unless $input{alerts_config};
		
		my $sth1 = $dbh->prepare("UPDATE permissions SET 
		design='$input{design}',
		accounts='$input{accounts}',
		accounts_edit='$input{accounts_edit}',
		tickets='$input{tickets}',
		tickets_form='$input{tickets_form}',
		logs='$input{logs}',
		charts='1',
		reports='$input{reports}',
		config='$input{config}',
		my_account='1',
        alerts='$input{alerts}',
        alerts_config='$input{alerts_config}' 
		WHERE idUser='$input{idUser}'");
		$sth1->execute();
		$sth1->finish;
		
		$dbh->disconnect if $dbh;
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("UPDATE:Account:idUser=$input{idUser};name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};idEmployee=$input{idEmployee};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};costCenterId=$input{costCenterId};groupId=$input{groupId};secondaryGroupId=$input{secondaryGroupId};theme=$input{theme};language=$input{language};active=$input{active};lxcservers=$input{lxcservers};lxcservers_edit=$input{lxcservers_edit};provisioning=$input{provisioning};accounts=$input{accounts};accounts_edit=$input{accounts_edit};containers=$input{containers};containers_edit=$input{containers_edit};sectors=$input{sectors};migration=$input{migration};keypairs=$input{keypairs};distros=$input{distros}");
		
		print "Location: index.cgi?mod=accounts_edit&idUser=$input{idUser}\n\n";
		
		
	} else {
		$html .= qq~<font color="#BB0000">$MSG{Passwords_does_not_match}</font> &nbsp; &nbsp; <a href="javascript: window.history.back();">Go Back</a>~;
	}
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
                
                $input{username} = delMalCode($input{username});
                $input{name} = delMalCode($input{name});
                $input{lastName} = delMalCode($input{lastName});
                $input{mothersLastName} = delMalCode($input{mothersLastName});
                $input{email} = delMalCode($input{email});
                $input{secondaryEmail} = delMalCode($input{secondaryEmail});
                $input{phone} = delMalCode($input{phone});
                $input{secondaryPhone} = delMalCode($input{secondaryPhone});
                $input{idEmployee} = delMalCode($input{idEmployee});
                $input{costCenterId} = delMalCode($input{costCenterId});
                $input{groupId} = delMalCode($input{groupId});
                $input{secondaryGroupId} = delMalCode($input{secondaryGroupId});
				
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
				$input{config} = '0' unless $input{config};
				$input{alerts_config} = '0' unless $input{alerts_config};
				
				$insert_string = qq~INSERT INTO permissions (
				idUser, design, accounts, accounts_edit, tickets, tickets_form, logs, charts, reports, config, alerts, alerts_config
				) VALUES (
				'$idUserNew',
				'$input{design}',
				'$input{accounts}',
				'$input{accounts_edit}',
				'$input{tickets}',
				'$input{tickets_form}',
				'$input{logs}',
				'$input{charts}',
				'$input{reports}',
				'$input{config}',
				'$input{alerts}',
				'$input{alerts_config}')~;
				$sth = $dbh->prepare("$insert_string");
				$sth->execute();
				$sth->finish;
						$html .= "<br>$insert_string<br><br>";
				
				$dbh->disconnect if $dbh;
				
				my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
				$log->Log("NEW:Account:idUser=$input{idUser};username=$input{username};name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};idEmployee=$input{idEmployee};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};costCenterId=$input{costCenterId};groupId=$input{groupId};secondaryGroupId=$input{secondaryGroupId};theme=$input{theme};language=$input{language};active=$input{active};lxcservers=$input{lxcservers};lxcservers_edit=$input{lxcservers_edit};provisioning=$input{provisioning};accounts=$input{accounts};accounts_edit=$input{accounts_edit};containers=$input{containers};containers_edit=$input{containers_edit};sectors=$input{sectors};migration=$input{migration};keypairs=$input{keypairs};distros=$input{distros}");
				
				print "Location: index.cgi?mod=accounts_edit&idUser=$idUserNew\n\n";
				
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


unless ( $input{submod} ) {
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
	
	
	
	# $html .= qq~
	# <table cellpadding="0" cellspacing="0" border="0" width="100%" class="gridTable" style="width: 100%; background-color: #FFFFFF">
		# <tr>
			# <td class="gridTitle">$MSG{User_Name}</td>
			# <td class="gridTitle">$MSG{Name}</td>
			# <td class="gridTitle">$MSG{Last_Name}</td>
			# <td class="gridTitle">$MSG{Mothers_Last_Name}</td>
			# <td class="gridTitle">$MSG{Email}</td>
			# <td class="gridTitle">$MSG{Active}</td>
		# </tr>
	# ~;
	$html .= qq~
    <script type="text/javascript" src="js/sorTable.js"></script>
    <table class="w3-table w3-bordered" style="background-color: #F4F4F4; border-top: 1px solid #E5E5E5;">
    <tr>
       <th><input type="text" placeholder="Search for User Name..." id="myInput" onkeyup="myFunction()" style="width: 400px; margin-top: 0px; margin-bottom: 0px;"></th>
    </tr>
    </table>
	<table cellpadding="0" cellspacing="0" border="0" class="sortable" id="myTable" style="border-top: 1px solid #FFFFFF;">
		<thead>
			<tr>
			<th>$MSG{User_Name}</th>
			<th>$MSG{Name}</th>
			<th>$MSG{Last_Name}</th>
			<th>$MSG{Mothers_Last_Name}</th>
			<th>$MSG{Email}</th>
			<th>$MSG{Active}</th>
			</tr>
		</thead>
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
    <script>
    function myFunction() {
      var input, filter, table, tr, td, i;
      input = document.getElementById("myInput");
      filter = input.value.toUpperCase();
      table = document.getElementById("myTable");
      tr = table.getElementsByTagName("tr");
      for (i = 0; i < tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[0];
        if (td) {
          txtValue = td.textContent || td.innerText;
          if (txtValue.toUpperCase().indexOf(filter) > -1) {
            tr[i].style.display = "";
          } else {
            tr[i].style.display = "none";
          }
        }
      }
    }
    </script>
	~;
}

return $html;
1;
