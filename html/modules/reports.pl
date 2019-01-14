%MSG = loadLang('reports');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Saving_Reports}</div>~ unless $input{'shtl'};

if ( $input{submod} eq 'save_config' ) {
	connected();
	my $sth = $dbh->prepare(qq~UPDATE report SET typeTicket='$input{typeTicket}', averageAttTime='$input{averageAttTime}', costPerHour='$input{costPerHour}', costPerTicket='$input{costPerTicket}' WHERE idReport='$input{idReport}'~);
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	print "Location: index.cgi?mod=reports&submod=edit_config\n\n";
}

if ( $input{submod} eq 'delete_config' ) {
	connected();
	$dbh->do("LOCK TABLES report WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM report WHERE idReport = '$input{idReport}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	$dbh->disconnect if $dbh;
	
	print "Location: index.cgi?mod=reports&submod=edit_config\n\n";
}

if ( $input{submod} eq 'add_config_element' ) {
	connected();
	my $insert_string = "INSERT INTO report (typeTicket, averageAttTime, costPerHour, costPerTicket) VALUES (?, ?, ?, ?)";
	$sth = $dbh->prepare("$insert_string");
	$sth->execute($input{typeTicket}, $input{averageAttTime}, $input{costPerHour}, $input{costPerTicket});
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	print "Location: index.cgi?mod=reports&submod=edit_config\n\n";
}


if ( $input{submod} eq 'edit_config' ) {
	connected();
	my $sth = $dbh->prepare("SELECT DISTINCT(typeTicket) FROM ticket");
	$sth->execute();
	my $TypeTT = $sth->fetchall_arrayref;
	$sth->finish;
	
	$html .= qq~
	$MSG{Information_List_of_Ticket_Types_found}:
	<table cellpadding="0" cellspacing="0" border="0" class="gridTable" >
	~;
	
	for my $i ( 0 .. $#{$TypeTT} ) {
		$html .= qq~<tr> <td class="gridContent">$TypeTT->[$i][0]</td></tr>~;
	}
	
	$html .= qq~</table><br /><br />~;
	
	
	my $sth = $dbh->prepare("SELECT * FROM report");
	$sth->execute();
	my $RPT = $sth->fetchall_arrayref;
	$sth->finish;
	
	$html .= qq~
	$MSG{List_of_Managed_Ticket_Types}:
	<table cellpadding="0" cellspacing="0" border="0" class="gridTable" >
	<tr>
	<td class="gridTitle">$MSG{Ticket_Type}</td>
	<td class="gridTitle">$MSG{Average_attention_Time}</td>
	<td class="gridTitle">$MSG{Cost_per_Hour}</td>
	<td class="gridTitle">$MSG{Cost_per_Ticket}</td>
	<td class="gridTitle"> &nbsp; </td>
	</tr>
	~;
	
	for my $i ( 0 .. $#{$RPT} ) {
		$html .= qq~
		<script type="text/javascript">
		function confirmDelete(delUrl) {
			if (confirm("$MSG{Are_you_sure_to_delete_this} ?")) {
				document.location = delUrl;
			}
		}
		</script>
		
		<form method="post" action="index.cgi">
		<input type="hidden" name="mod" value="reports">
		<input type="hidden" name="submod" value="save_config">
		<input type="hidden" name="idReport" value="$RPT->[$i][0]">
		
		<tr>
		<td class="gridContent"><input type="text" name="typeTicket" value="$RPT->[$i][1]"></td>
		<td class="gridContent"><input type="text" name="averageAttTime" value="$RPT->[$i][2]" style="width: 50px"> / $MSG{hour}</td>
		<td class="gridContent">\$ <input type="text" name="costPerHour" value="$RPT->[$i][3]" style="width: 50px"></td>
		<td class="gridContent">\$ <input type="text" name="costPerTicket" value="$RPT->[$i][4]" style="width: 50px"></td>
		<td class="gridContent">
		<input type="submit" class="blueLightButton" value="Update"></form>
		&nbsp;
		<input type="button" class="blueLightButton" onclick="confirmDelete('index.cgi?mod=reports&submod=delete_config&idReport=$RPT->[$i][0]');" style="background-color: #DB2C2C; border-color: #BB0000" value="$MSG{Delete}" />
		
		</td>
		</tr>
		~;
	}
	
	$html .= qq~
	<form method="post" action="index.cgi">
	<input type="hidden" name="mod" value="reports">
	<input type="hidden" name="submod" value="add_config_element">
	
	<tr>
	<td class="gridContent"><input type="text" name="typeTicket" placeholder="$MSG{Type_a_new_Ticket_type}" required></td>
	<td class="gridContent"><input type="text" name="averageAttTime" style="width: 50px" required> / $MSG{hour}</td>
	<td class="gridContent">\$ <input type="text" name="costPerHour" style="width: 50px" required></td>
	<td class="gridContent">\$ <input type="text" name="costPerTicket" style="width: 50px" required></td>
	<td class="gridContent"><input type="submit" class="blueLightButton" value="New"></td>
	</tr>
	</form>
	~;
	
	$html .= qq~</table>~;
	
	
	$dbh->disconnect if $dbh;
}




unless ( $input{submod} ) {
	my %MON = (
		'01'	=> $MSG{January},
		'02'	=> $MSG{February},
		'03'	=> $MSG{March},
		'04'	=> $MSG{April},
		'05'	=> $MSG{May},
		'06'	=> $MSG{June},
		'07'	=> $MSG{July},
		'08'	=> $MSG{August},
		'09'	=> $MSG{September},
		'10'	=> $MSG{October},
		'11'	=> $MSG{November},
		'12'	=> $MSG{December}
	);
	
	my $month = $input{dateToChart} ? $input{dateToChart} : currentMonth();
	my $year = $input{yearToChart} ? $input{yearToChart} : currentYear();
	
	$html .= qq~
	<form method="get" action="index.cgi" target="_top">
	<input type="hidden" name="mod" value="reports">
	<input type="text" name="yearToChart" value="$year" style="width: 50px">
	<select name="dateToChart" onChange="this.form.submit();">
	~;
	
	for my $day ( sort keys %MON ) {
		if ( $day eq $month ) {
			$html .= qq~<option value="$day" selected>$MON{$day}</option>~;
		} else {
			$html .= qq~<option value="$day">$MON{$day}</option>~;
		}
	}
	
	$html .= qq~</select></form>~;
	$html .= qq~<p align="right" style="padding-right: 100px">
	<input type="button" class="blueLightButton" onclick="location.href='index.cgi?mod=reports&submod=edit_config';" value="Config" />
	</p>~;
	
	$html .= qq~
	<script type="text/javascript">
		google.charts.load('current', {'packages':['bar']});
	</script>
	~;
	
	# $html .= qq~<table cellpadding="0" cellspacing="0" border="0" style="background-color: #FFFFFF">~;
	
	connected();
	my $sth = $dbh->prepare("SELECT DISTINCT(typeTicket) FROM ticket");
	$sth->execute();
	my $TypeTT = $sth->fetchall_arrayref;
	$sth->finish;
	
	# my $qtTt = 3;
	my $qtTt = $#{$TypeTT} + 1;
	my $grid;
	
	for my $i ( 0 .. $#{$TypeTT} )  {
		my $sth = $dbh->prepare("SELECT COUNT(*) FROM ticket WHERE typeTicket = '$TypeTT->[$i][0]' AND initialDate BETWEEN '$year-$month-01 00:00:00' and '$year-$month-31 23:59:59'");
		$sth->execute();
		my ($cnt) = $sth->fetchrow_array;
		$sth->finish;
		
		if ( $cnt ) {
			my $sth = $dbh->prepare("SELECT averageAttTime, costPerHour, costPerTicket FROM report WHERE typeTicket = '$TypeTT->[$i][0]'");
			$sth->execute();
			my $CST = $sth->fetchall_arrayref;
			$sth->finish;
			
			# $html .= qq~$TypeTT->[$i][0] - $cnt - $CST->[0][0] - $CST->[0][1] - $CST->[0][2]<br>~;
			
			my $oldCost = $cnt * $CST->[0][0] * $CST->[0][1];
			my $currentCost = $cnt * $CST->[0][2];
			my $save = $oldCost - $currentCost;
			
			# $html .= qq~$TypeTT->[$i][0] - $oldCost - $currentCost - $save<br>~;
			
			$grid .= qq~['$TypeTT->[$i][0]', $oldCost, $currentCost, $save],~;
		}
		
	}
	
	my $width = 500;
	if ( $qtTt >= 2 ) {
		$width = $width + (($qtTt - 2) * 100);
	}
	# $html .= qq~$qtTt types. Width: $width<br>~;
	
	$html .= qq~
	<script type="text/javascript">
		google.charts.setOnLoadCallback(drawChart);
		
		 function drawChart() {
	        var data = google.visualization.arrayToDataTable([
	          ['$MSG{Ticket_Type}', '$MSG{Old_Cost}', '$MSG{Current_Cost}', '$MSG{Saving}'],
	          $grid
	        ]);
	
	        var options = {
				chart: {
					title: '$MSG{Company_Saving}',
					subtitle: '$MSG{Old_Expenses_Current_costs_and_Saving}: $year-$month',
				},
				colors: ['#4285F4', '#DB4437', '#1AA71A']
	        };
	
	        var chart = new google.charts.Bar(document.getElementById('columnchart_material'));
	
	        chart.draw(data, google.charts.Bar.convertOptions(options));
	      }
	</script>
	
	<div id="columnchart_material" style="width: ${width}px; height: 500px;"></div>
	~;
	
	$dbh->disconnect if ($dbh);
}

# $html .= qq~</table>~;



return $html;
1;

sub currentMonth {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[4] ++;
	if ( $fecha[4] < 10 ) { $fecha[4] = "0$fecha[4]" }
	return $fecha[4];
}

sub currentYear {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	return $fecha[5];
}
