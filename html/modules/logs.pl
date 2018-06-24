%MSG = loadLang('logs');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Logs}</div>~ unless $input{'shtl'};

# $html .= qq~
# <table cellpadding="0" cellspacing="2" border="0" width="100%" height="100%">
	# <tr>
		# <td width="50%">
			
		# </td>
		# <td width="50%">
			
		# </td>
	# </tr>
# </table>
# ~;

unless ( $input{submod} ) {
	$html .= qq~<br>~;
}



if ( $input{submod} eq 'showLogs' ) {
	connected();
	my $sth = $dbh->prepare("SELECT t.numberTicket, t.Subject, a.autoBotName, t.initialDate, a.idAutoBot FROM ticket t, autoBot a WHERE numberTicket = '$input{numberTicket}' AND t.idAutoBotCatched = a.idAutoBot");
	$sth->execute();
	my @TT = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$html .= qq~<p width="100%" align="right" style="padding-right: 80px"><a href="javascript:document.location.reload(true)"><img src="images/refresh-32x35.png" style="width: 20px"></a></p>
	
	<table cellpadding="0" cellspacing="0" border="0" class="gridTable" style="height: 120px">
		<tr><td class="gridTitle">$MSG{Ticket}</td><td class="gridContent"><b>$TT[0]</b></td></tr>
		<tr><td class="gridTitle">$MSG{Subject}</td><td class="gridContent">$TT[1]</td></tr>
		<tr><td class="gridTitle">$MSG{AutoBot_Name}</td><td class="gridContent"><a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$TT[4]" target="_blank">$TT[2]</a></td></tr>
		<tr><td class="gridTitle">$MSG{Initial_Date}</td><td class="gridContent">$TT[3]</td></tr>
	</table>
	~;
	
	connected();
	my $sth = $dbh->prepare("SELECT insertDate, log FROM log WHERE numberTicket = '$input{numberTicket}' ORDER BY idLog ASC");
	$sth->execute();
	my $LOG = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$html .= qq~
	<table cellpadding="0" cellspacing="0" border="0" style="width:auto; height: calc(100% - 150px); background-color: #E7E7E7;">
	<tr><td width="100%" valign="top">
	~;
	
	for my $i ( 0 .. $#{$LOG} ) {
		my $color = '#000000';
		if ( $LOG->[$i][1] =~ /^Comparison\:|Setting value \[|Remote Windows Command \[|Linux Command \[|SendEMAIL|Returned value\: \[/ ) {
			$color = '#969696';
		}
		$LOG->[$i][1] =~ s/\n/<br\/>/g;
		$LOG->[$i][1] =~ s/Final State/<b>Final State<\/b>/;
		$LOG->[$i][1] =~ s/NOTE/<b><i>NOTE<\/i><\/b>/;
		$LOG->[$i][1] =~ s/Value Returned/<b><i>Value Returned<\/i><\/b>/;
		$LOG->[$i][1] =~ s/AutoBot \[(.+)\] Executed/<b><i>AutoBot<\/i><\/b> \[$1\] <b><i>Executed<\/i><\/b>/;
		
		$html .= qq~
		<table cellpadding="0" cellspacing="0" border="0" width="100%" style="padding-top: 8px; background-color: #E7E7E7;">
			<tr>
			<td style="border-bottom: 1px dashed #C9C9C9; padding: 4px 10px 4px 0; color: $color; width: 140px;" valign="top">$LOG->[$i][0]</td>
			<td style="border-bottom: 1px dashed #C9C9C9; padding: 4px 10px 4px 0; color: $color;" valign="top">$LOG->[$i][1]</td>
			</tr>
		</table>
		~;
	}
	
	$html .= qq~
	</tr></table>
	<br><br>
	~;
}



if ( $input{submod} eq 'showJson' ) {
	connected();
	my $sth = $dbh->prepare("SELECT numberTicket, Subject, json FROM ticket WHERE numberTicket = '$input{numberTicket}'");
	$sth->execute();
	my @TT = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$TT[2] =~ s/,/,\n/g;
	$TT[2] =~ s/{/{\n/g;
	$TT[2] =~ s/(\t?)}/\n$1}/g;
	$TT[2] =~ s/},/    },/g;
	$TT[2] =~ s/}\n}/    }\n}/g;
	
	$html .= qq~
	<table cellpadding="0" cellspacing="2" border="0" width="99%" style="height: 100%">
		<tr>
			<td width="100%" valign="top">
				<textarea scrolling="auto" width="100%" style="height: 100%; width: 99%; color: #CEE7DC; background-color: #15283F; font-size: 10px;">$TT[2]</textarea>
			</td>
		</tr>
	</table>
	~;
}





return $html;
1;
