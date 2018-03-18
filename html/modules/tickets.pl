%MSG = loadLang('tickets');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Overview}</div>~ unless $input{'shtl'};

my $queryLimit;



unless ( $input{submod} ) {
	$html .= qq~<script>setTimeout('document.location.reload()',$VAR{REFRESH_RATE});</script>~;
	
	$html .= paginator();
	
	$html .= qq~
	<table cellpadding="0" cellspacing="0" border="0" width="100%" class="gridTable" style="padding-top: 30px">
		<tr>
			<td class="gridTitle" style="max-width:100px;">$MSG{Ticket_Number}</td>
			<td class="gridTitle" style="max-width:100px;">$MSG{Subject}</td>
			<td class="gridTitle" style="max-width:100px;">$MSG{Insert_Date}</td>
			<td class="gridTitle" style="max-width:100px;">$MSG{Final_Date}</td>
			<td class="gridTitle" style="max-width:50px;">$MSG{Final_State}</td>
			<td class="gridTitle" style="max-width:100%">$MSG{Catched}</td>
		</tr>
	~;
	
	connected();
	my $sth = $dbh->prepare("SELECT numberTicket, Subject, idAutoBotCatched, initialDate, finalDate, finalState FROM ticket ORDER BY initialDate DESC LIMIT $queryLimit");
	$sth->execute();
	my $TT = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	for my $i ( 0 .. $#{$TT} ) {
		
		my $catched = qq~ <a href="launcher.cgi?mod=logs&submod=showJson&numberTicket=$TT->[$i][0]&shtl=1" target="logs">
			<img src="images/json20.png" style="border: 0; width: 18px; height: 14px;">
			</a> &nbsp; &nbsp; $MSG{No} ~;
		if ( $TT->[$i][2] ) {
			# $catched = qq~<a href="launcher.cgi?mod=logs&submod=showLogs&numberTicket=$TT->[$i][0]&shtl=1" target="logs"><font color="#471F6E"><b>$MSG{Yes}</b></font></a>~;
			$catched = qq~
			<a href="launcher.cgi?mod=logs&submod=showJson&numberTicket=$TT->[$i][0]&shtl=1" target="logs">
			<img src="images/json20.png" style="border: 0; width: 18px; height: 14px;">
			</a>
			&nbsp; &nbsp; ~;
			
			if ( $VAR{SHOW_LOGS_IN_FRAME} ) {
				$catched .= qq~<a href="launcher.cgi?mod=logs&submod=showLogs&numberTicket=$TT->[$i][0]&shtl=1" target="logs">~;
			} else {
				$catched .= qq~<a href="index.cgi?mod=logs&submod=showLogs&numberTicket=$TT->[$i][0]" target="_parent">~;
			}
			
			$catched .= qq~<img src="images/log20.png" style="border: 0; width: 18px; height: 14px;">
			</a>
			~;
		}
		
		my $ST;
		if ( $TT->[$i][5] eq 'Resolved' ) {
			$ST = '#0000FF';
		} elsif ( $TT->[$i][5] eq 'Rejected' ) {
			$ST = '#BB0000';
		} elsif ( $TT->[$i][5] eq 'Pending' ) {
			$ST = '#9C7411';
		} elsif ( $TT->[$i][5] eq 'Failed' ) {
			$ST = '#FF0000';
		}
		
		$html .= qq~
		<tr class="gridRowContent">
			<td class="gridContent" style="max-width:100px; color: #2121A1;"><b>$TT->[$i][0]</b></td>
			<td class="gridContent" style="max-width:100px; color: $ST;" title="$TT->[$i][1]">$TT->[$i][1]</td>
			<td class="gridContent" style="max-width:100px; color: $ST;">$TT->[$i][3]</td>
			<td class="gridContent" style="max-width:100px; color: $ST;">$TT->[$i][4]</td>
			<td class="gridContent" style="max-width:50px; color: $ST;">$TT->[$i][5]</td>
			<td class="gridContent" style="max-width:100%;">$catched</td>
		</tr>
		~;
	}
	
	$html .= qq~
	</table>
	~;
}



if ( $input{submod} eq 'findTicket' ) {
	$html .= qq~
	<table cellpadding="0" cellspacing="2" border="0" width="100%" class="gridTable">
		<tr>
			<td class="gridTitle" style="max-width:100px;">$MSG{Ticket_Number}</td>
			<td class="gridTitle" style="max-width:100px;">$MSG{Subject}</td>
			<td class="gridTitle" style="max-width:100px;">$MSG{Insert_Date}</td>
			<td class="gridTitle" style="max-width:100px;">$MSG{Final_Date}</td>
			<td class="gridTitle" style="max-width:50px;">$MSG{Final_State}</td>
			<td class="gridTitle" style="max-width:100%">$MSG{Catched}</td>
		</tr>
	~;
	
	connected();
	my $sth = $dbh->prepare("SELECT numberTicket, Subject, idAutoBotCatched, initialDate, finalDate, finalState FROM ticket WHERE numberTicket LIKE '%$input{ftt}%' ORDER BY initialDate DESC");
	$sth->execute();
	my $TT = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	for my $i ( 0 .. $#{$TT} ) {
		
		my $catched = qq~ <a href="launcher.cgi?mod=logs&submod=showJson&numberTicket=$TT->[$i][0]&shtl=1" target="logs">
			<img src="images/json20.png" style="border: 0; width: 18px; height: 14px;">
			</a> &nbsp; &nbsp; $MSG{No} ~;
		if ( $TT->[$i][2] ) {
			# $catched = qq~<a href="launcher.cgi?mod=logs&submod=showLogs&numberTicket=$TT->[$i][0]&shtl=1" target="logs"><font color="#471F6E"><b>$MSG{Yes}</b></font></a>~;
			$catched = qq~
			<a href="launcher.cgi?mod=logs&submod=showJson&numberTicket=$TT->[$i][0]&shtl=1" target="logs">
			<img src="images/json20.png" style="border: 0; width: 18px; height: 14px;">
			</a>
			&nbsp; &nbsp; ~;
			
			if ( $VAR{SHOW_LOGS_IN_FRAME} ) {
				$catched .= qq~<a href="launcher.cgi?mod=logs&submod=showLogs&numberTicket=$TT->[$i][0]&shtl=1" target="logs">~;
			} else {
				$catched .= qq~<a href="index.cgi?mod=logs&submod=showLogs&numberTicket=$TT->[$i][0]" target="_parent">~;
			}
			
			$catched .= qq~<img src="images/log20.png" style="border: 0; width: 18px; height: 14px;">
			</a>
			~;
		}
		
		my $ST;
		if ( $TT->[$i][5] eq 'Resolved' ) {
			$ST = '#0000FF';
		} elsif ( $TT->[$i][5] eq 'Rejected' ) {
			$ST = '#BB0000';
		} elsif ( $TT->[$i][5] eq 'Pending' ) {
			$ST = '#9C7411';
		} elsif ( $TT->[$i][5] eq 'Failed' ) {
			$ST = '#FF0000';
		}
		
		$html .= qq~
		<tr>
			<td class="gridContent" style="max-width:100px; color: #2121A1;"><b>$TT->[$i][0]</b></td>
			<td class="gridContent" style="max-width:100px; color: $ST;">$TT->[$i][1]</td>
			<td class="gridContent" style="max-width:100px; color: $ST;">$TT->[$i][3]</td>
			<td class="gridContent" style="max-width:100px; color: $ST;">$TT->[$i][4]</td>
			<td class="gridContent" style="max-width:50px; color: $ST;">$TT->[$i][5]</td>
			<td class="gridContent" style="max-width:100%;">$catched</td>
		</tr>
		~;
	}
	
	$html .= qq~
	</table>
	~;
}


sub paginator {
	connected();
	my $sth = $dbh->prepare("SELECT COUNT(idTicket) FROM ticket");
	$sth->execute();
	my $totalTkt = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $page = $input{page} || 1;
	
	my $totPages = $totalTkt / $VAR{SHOW_PER_PAGE};
	$totPages = int ($totPages + 1) if $totPages > int($totPages);
	
	my $fromRec = ($page - 1) * $VAR{SHOW_PER_PAGE};
	
	my $return = qq~<div style="padding: 4px 0 3px 8px; position: fixed; width: 100%; background-color: #F9F9F9; border-bottom: 1px solid #E5E5E5">
	<table cellpadding="0" cellspacing="0" border="0" style=""><tr>~;
	
	## Very first ticket
	if ( $page == 1 ) {
		$return .= qq~
		<td style="padding-right: 10px">
			<input class="greyButton" type="button" value=" << " />
		</td>
		~;
	} else {
		$return .= qq~
		<td style="padding-right: 10px">
			<form><input class="blueLightButton" type="button" value=" << " onclick="window.location.href='launcher.cgi?mod=tickets&page=1&shtl=1'" /></form>
		</td>
		~;
	}
	
	## Before
	if ( $page == 1 ) {
		$return .= qq~
		<td style="padding-right: 10px">
			<input class="greyButton" type="button" value=" &nbsp;&nbsp; " />
		</td>
		~;
	} else {
		my $beforePage = $page - 1;
		$return .= qq~
		<td style="padding-right: 10px">
			<form><input class="blueLightButton" type="button" value=" $beforePage " onclick="window.location.href='launcher.cgi?mod=tickets&page=$beforePage&shtl=1'" /></form>
		</td>
		~;
	}
	
	## Current Ticket
	$return .= qq~
		<td style="padding-right: 10px">
			<input class="greyButton" type="button" style="font-weight: bold; background-color: #969696;" value=" $page " />
		</td>
		~;
	
	## After
	if ( $page == $totPages or $totPages <= 1 ) {
		$return .= qq~
		<td style="padding-right: 10px">
			<input class="greyButton" type="button" value=" &nbsp;&nbsp; " />
		</td>
		~;
	} else {
		my $afterPage = $page + 1;
		$return .= qq~
		<td style="padding-right: 10px">
			<form><input class="blueLightButton" type="button" value=" $afterPage " onclick="window.location.href='launcher.cgi?mod=tickets&page=$afterPage&shtl=1'" /></form>
		</td>
		~;
	}
	
	
	$queryLimit = "$fromRec, $VAR{SHOW_PER_PAGE}";
	
	## Very last ticket
	if ( $page == $totPages or $totPages <= 1 ) {
		$return .= qq~
		<td style="padding-right: 10px">
			<input class="greyButton" type="button" value=" >> " />
		</td>
		~;
	} else {
		$return .= qq~
		<td style="padding-right: 10px">
			<form><input class="blueLightButton" type="button" value=" >> " onclick="window.location.href='launcher.cgi?mod=tickets&page=$totPages&shtl=1'" /></form>
		</td>
		~;
	}
		
	$return .= qq~<td>$MSG{Showing} $VAR{SHOW_PER_PAGE} $MSG{records_page_Total}: $totalTkt $MSG{records_in} $totPages $MSG{pages}</td></tr></table></div>~;
	
	return $return;
	
	# SELECT name, cost FROM test LIMIT 100, 20
	# This will display records 101-120
}


return $html;
1;
