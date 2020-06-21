%MSG = loadLang('accounts_edit');

# use Form::Auto;

my $html;
$html .= qq~<div class="contentTitle">$MSG{User_Accounts_Edition}</div>~ unless $input{'shtl'};

if ( $input{idUser} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM users WHERE idUser = '$input{idUser}'");
	$sth->execute();
	my @data = $sth->fetchrow_array;
	$sth->finish;
	
	my $sth = $dbh->prepare("SELECT permissions.* FROM users, permissions WHERE users.username = '$data[1]' and users.idUser = permissions.idUser");
	$sth->execute();
	my @PRM = $sth->fetchrow_array;
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
		<form method="get" action="index.cgi" target="_top" class="w3-container w3-card-4 w3-light-grey">
		<input type="hidden" name="mod" value="accounts">
		<input type="hidden" name="submod" value="save_record">
		<input type="hidden" name="idUser" value="$data[0]">
        
        <br><p>$MSG{Editing} <b>$data[1]</b></p>
        
        
		
		<table cellpadding="0" cellspacing="0" width="60%">
		
		<tr><td align="right" width="30%">$MSG{Password} <font color="BB0000"><b>*</b></font>: </td><td width="70%"><input type="password" name="pwd1" value="" maxlength="16" placeholder="****************"></td></tr>
		<tr><td align="right" width="30%">$MSG{Password_again} <font color="BB0000"><b>*</b></font>: </td><td width="70%"><input type="password" name="pwd2" value="" maxlength="16" placeholder="****************"></td></tr>
		<tr><td align="right" width="30%">$MSG{Name}: </td><td width="70%"><input class="w3-animate-input" type="text" name="name" value="$data[3]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Last_Name}: </td><td width="70%"><input class="w3-animate-input" type="text" name="lastName" value="$data[4]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Mothers_Last_Name}: </td><td width="70%"><input class="w3-animate-input" type="text" name="mothersLastName" value="$data[5]"></td></tr>
		<tr><td align="right" width="30%">$MSG{ID_Employee}: </td><td width="70%"><input class="w3-animate-input" type="text" name="idEmployee" value="$data[6]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Email}: </td><td width="70%"><input class="w3-animate-input" type="text" name="email" value="$data[7]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Email}: </td><td width="70%"><input class="w3-animate-input" type="text" name="secondaryEmail" value="$data[8]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Phone}: </td><td width="70%"><input class="w3-animate-input" type="text" name="phone" value="$data[9]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Phone}: </td><td width="70%"><input class="w3-animate-input" type="text" name="secondaryPhone" value="$data[10]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Cost_Center_ID}: </td><td width="70%"><input class="w3-animate-input" type="text" name="costCenterId" value="$data[11]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Group_ID}: </td><td width="70%"><input class="w3-animate-input" type="text" name="groupId" value="$data[12]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Group_ID}: </td><td width="70%"><input class="w3-animate-input" type="text" name="secondaryGroupId" value="$data[13]"></td></tr>
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
		<tr><td align="right" width="30%">$MSG{Active}: </td>
		<td width="70%">
		<select name="active">
		$activeSelect
		</select>
		</td></tr>
		~;
		
		my $chk_design = $PRM[4] ? 'checked' : '';
		my $chk_accounts = $PRM[5] ? 'checked' : '';
		my $chk_accounts_edit = $PRM[6] ? 'checked' : '';
		my $chk_tickets = $PRM[8] ? 'checked' : '';
		my $chk_tickets_form = $PRM[9] ? 'checked' : '';
		my $chk_logs = $PRM[10] ? 'checked' : '';
		my $chk_charts = $PRM[11] == 1 ? 'checked' : '';
		my $chk_reports = $PRM[12] ? 'checked' : '';
		my $chk_config = $PRM[14] ? 'checked' : '';
		my $chk_alerts = $PRM[16] ? 'checked' : '';
		my $chk_alerts_config = $PRM[17] ? 'checked' : '';
		
		$html .= qq~
		<tr><td align="right" width="30%"><br />$MSG{PERMISIONS}:<br /><br /></td><td width="70%">&nbsp;</td></tr>
		<tr><td align="right" width="30%">$MSG{Design}: </td><td width="70%"><input type="checkbox" name="design" style="margin: 6px 4px;" value="1" $chk_design></td></tr>
		<tr><td align="right" width="30%">$MSG{Accounts}: </td><td width="70%"><input type="checkbox" name="accounts" style="margin: 6px 4px;" value="1" $chk_accounts></td></tr>
		<tr><td align="right" width="30%">$MSG{Accounts_Edition}: </td><td width="70%"><input type="checkbox" name="accounts_edit" style="margin: 6px 4px;" value="1" $chk_accounts_edit></td></tr>
		<tr><td align="right" width="30%">$MSG{Tickets}: </td><td width="70%"><input type="checkbox" name="tickets" style="margin: 6px 4px;" value="1" $chk_tickets></td></tr>
		<tr><td align="right" width="30%">$MSG{Tickets_Form}: </td><td width="70%"><input type="checkbox" name="tickets_form" style="margin: 6px 4px;" value="1" $chk_tickets_form></td></tr>
		<tr><td align="right" width="30%">$MSG{Logs}: </td><td width="70%"><input type="checkbox" name="logs" style="margin: 6px 4px;" value="1" $chk_logs></td></tr>
		<tr><td align="right" width="30%">$MSG{Reports}: </td><td width="70%"><input type="checkbox" name="reports" style="margin: 6px 4px;" value="1" $chk_reports></td></tr>
		<tr><td align="right" width="30%">$MSG{Config}: </td><td width="70%"><input type="checkbox" name="config" style="margin: 6px 4px;" value="1" $chk_config></td></tr>
        
		<tr><td align="right" width="30%">Alerts: </td><td width="70%"><input type="checkbox" name="alerts" style="margin: 6px 4px;" value="1" $chk_alerts></td></tr>
		<tr><td align="right" width="30%">Alerts_Config: </td><td width="70%"><input type="checkbox" name="alerts_config" style="margin: 6px 4px;" value="1" $chk_alerts_config></td></tr>
		
        <tr><td align="right" width="30%" style="padding-top: 50px;">
            &nbsp;
        </td><td width="70%">
            <div id="myModalRedirectSave" class="confirm"><div class="confirm-content">
			$MSG{Alert}<hr class="confirm-header">
			$MAG{Saving_changes_for_user} $data[1].<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
		<button class="blueLightButton" onClick="return openModal('myModalRedirectSave');">$MSG{Save}</button>
		&nbsp; 
		<a style="margin-left: 50px;" class="redButton" href="index.cgi?mod=accounts&submod=delete_record&idUser=$data[0]" target="_top" onclick="return confirm('$MSG{Are_you_sure_you_want_to_continue_deleting_the_user}: $data[1]?')">$MSG{Delete}</a>
		</td></tr>
        
		</table>
		
		</form>
		
		<br><br>
	~;
	
} else {
	my @themes = `ls $VAR{themes_path}`;
	chomp @themes;
	
	my $themeSelect;
	foreach my $theme ( @themes ) {
		my $selected = $data[14] eq $theme ? 'selected' : '';
		$themeSelect .= qq~<option value="$theme" $selected>$theme</option>~;
	}
	
	my $langageSelect .= '<option value="en_US">en_US</option>';
	$langageSelect .= '<option value="es_MX">es_MX</option>';
	
	my $activeSelect .= '<option value="1">Yes</option>';
	$activeSelect .= '<option value="0">No</option>';
	
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
		<form method="get" action="index.cgi" target="_parent" id="form" class="w3-container w3-card-4 w3-light-grey">
		<input type="hidden" name="mod" value="accounts">
		<input type="hidden" name="submod" value="new_record">
        
        <br><p><b>$MSG{Create_new_user}</b></p>
		
		<table cellpadding="0" cellspacing="0" width="60%">
		
		<tr><td align="right" width="30%">$MSG{Username} <font color="BB0000"><b>*</b></font>: </td><td width="70%"><input class="w3-animate-input" type="text" name="username" maxlength="40"></td></tr>
		<tr><td align="right" width="30%">$MSG{Password} <font color="BB0000"><b>*</b></font>: </td><td width="70%"><input type="password" name="pwd1" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">$MSG{Password_again} <font color="BB0000"><b>*</b></font>: </td><td width="70%"><input type="password" name="pwd2" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">$MSG{Name}: </td><td width="70%"><input class="w3-animate-input" type="text" name="name"></td></tr>
		<tr><td align="right" width="30%">$MSG{Last_Name}: </td><td width="70%"><input class="w3-animate-input" type="text" name="lastName"></td></tr>
		<tr><td align="right" width="30%">$MSG{Mothers_Last_Name}: </td><td width="70%"><input class="w3-animate-input" type="text" name="mothersLastName"></td></tr>
		<tr><td align="right" width="30%">$MSG{ID_Employee}: </td><td width="70%"><input class="w3-animate-input" type="text" name="idEmployee"></td></tr>
		<tr><td align="right" width="30%">$MSG{Email}: </td><td width="70%"><input class="w3-animate-input" type="text" name="email"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Email}: </td><td width="70%"><input class="w3-animate-input" type="text" name="secondaryEmail"></td></tr>
		<tr><td align="right" width="30%">$MSG{Phone}: </td><td width="70%"><input class="w3-animate-input" type="text" name="phone"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Phone}: </td><td width="70%"><input class="w3-animate-input" type="text" name="secondaryPhone"></td></tr>
		<tr><td align="right" width="30%">$MSG{Cost_Center_ID}: </td><td width="70%"><input class="w3-animate-input" type="text" name="costCenterId"></td></tr>
		<tr><td align="right" width="30%">$MSG{Group_ID}: </td><td width="70%"><input class="w3-animate-input" type="text" name="groupId"></td></tr>
		<tr><td align="right" width="30%">$MSG{Secondary_Group_ID}: </td><td width="70%"><input class="w3-animate-input" type="text" name="secondaryGroupId"></td></tr>
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
		<tr><td align="right" width="30%">$MSG{Active}: </td>
		<td width="70%">
		<select name="active">
		$activeSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%"><br />$MSG{PERMISIONS}:<br /><br /></td><td width="70%">&nbsp;</td></tr>
		<tr><td align="right" width="30%">$MSG{Design}: </td><td width="70%"><input type="checkbox" name="design" style="margin: 6px 4px;" value="1"></td></tr>
		<tr><td align="right" width="30%">$MSG{Accounts}: </td><td width="70%"><input type="checkbox" name="accounts" style="margin: 6px 4px;" value="1"></td></tr>
		<tr><td align="right" width="30%">$MSG{Accounts_Edition}: </td><td width="70%"><input type="checkbox" name="accounts_edit" style="margin: 6px 4px;" value="1"></td></tr>
		<tr><td align="right" width="30%">$MSG{Tickets}: </td><td width="70%"><input type="checkbox" name="tickets" style="margin: 6px 4px;" value="1" checked></td></tr>
		<tr><td align="right" width="30%">$MSG{Tickets_Form}: </td><td width="70%"><input type="checkbox" name="tickets_form" style="margin: 6px 4px;" value="1" checked></td></tr>
		<tr><td align="right" width="30%">$MSG{Logs}: </td><td width="70%"><input type="checkbox" name="logs" style="margin: 6px 4px;" value="1" checked></td></tr>
		<tr><td align="right" width="30%">$MSG{Charts}: </td><td width="70%"><input type="checkbox" name="charts" style="margin: 6px 4px;" value="1" checked></td></tr>
		<tr><td align="right" width="30%">$MSG{Reports}: </td><td width="70%"><input type="checkbox" name="reports" style="margin: 6px 4px;" value="1" checked></td></tr>
		<tr><td align="right" width="30%">$MSG{Config}: </td><td width="70%"><input type="checkbox" name="config" style="margin: 6px 4px;" value="1"></td></tr>
        
		<tr><td align="right" width="30%">Alerts: </td><td width="70%"><input type="checkbox" name="alerts" style="margin: 6px 4px;" value="1" checked></td></tr>
		<tr><td align="right" width="30%">Alerts_Config: </td><td width="70%"><input type="checkbox" name="alerts_config" style="margin: 6px 4px;" value="1"></td></tr>
		
        <tr><td align="right" width="30%" style="padding-top: 50px;">
            &nbsp;
        </td><td width="70%">
            <div id="myModalRedirectSave" class="confirm"><div class="confirm-content">
			$MSG{Alert}<hr class="confirm-header">
			$MAG{Saving_changes_for_user}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
            </div></div>
            <button class="blueLightButton" onClick="return openModal('myModalRedirectSave');">$MSG{Save}</button>
		</td></tr>
        </table>
        
		</form>
		
		<br><br>
		<br><br>
	~;
}









# unless ( $input{idUser} ) {
	# my $form = Form::Auto->new;
	
	# $html .= Form::Auto->form({
		# method	=> 'get',
		# action	=> 'index.cgi'
	# });
	
	# $html .= Form::Auto->form({
		
	# });
# }
# perl -pi.bak -e 's/;/;\n/g' w2ui-1.4.3.min.css
# perl -pi.bak1 -e 's/\{/\{\n/g' w2ui-1.4.3.min.css
# perl -pi.bak2 -e 's/\}/\n\}\n\n/g' w2ui-1.4.3.min.css




return $html;
1;
