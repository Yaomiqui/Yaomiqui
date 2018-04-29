%MSG = loadLang('charts');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Report_Charts}</div>~ unless $input{'shtl'};

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
<input type="hidden" name="mod" value="charts">
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

$html .= qq~
<script type="text/javascript">
	google.charts.load('current', {'packages':['corechart']});
</script>

<table cellpadding="0" cellspacing="0" border="0" style="background-color: #FFFFFF">
~;

connected();
my $sth = $dbh->prepare("SELECT DISTINCT(typeTicket) FROM ticket");
$sth->execute();
my $TypeTT = $sth->fetchall_arrayref;
$sth->finish;

for my $i ( 0 .. $#{$TypeTT} ) {
	# $html .= qq~<b>$MSG{Ticket_Type}: $TypeTT->[$i][0]</b><br>~;
	
	my $sth = $dbh->prepare("SELECT finalState, count(finalState) FROM ticket WHERE typeTicket='$TypeTT->[$i][0]' AND finalDate between '$year-$month-01 00:00:00' and '$year-$month-31 23:59:59' GROUP BY finalState ORDER BY finalState DESC");
	$sth->execute();
	my $typeTicket = $sth->fetchall_arrayref;
	$sth->finish;
	
	my $pieChart = qq~['State', 'Quantity'],\n~;
	
	for my $j ( 0 .. $#{$typeTicket} ) {
		$pieChart .= qq~['$typeTicket->[$j][0]', $typeTicket->[$j][1]],\n~;
	}
	
	# No state:
	my $sth = $dbh->prepare("SELECT COUNT(idTicket) FROM ticket WHERE typeTicket='$TypeTT->[$i][0]' AND initialDate between '$year-$month-01 00:00:00' and '$year-$month-31 23:59:59' AND finalState IS NULL");
	$sth->execute();
	my ($cnt) = $sth->fetchrow_array;
	$sth->finish;
	
	$pieChart .= qq~['No State', $cnt],\n~ if $cnt;
	#
	
	####
	my $sth = $dbh->prepare(qq~SELECT DATE_FORMAT(finalDate, "%M-%d"), finalState, count(finalState) 
	FROM ticket WHERE typeTicket='$TypeTT->[$i][0]' 
	AND finalDate between '$year-$month-01 00:00:00' AND '$year-$month-31 23:59:59' 
	GROUP BY finalState, DATE_FORMAT(finalDate, "%M/%d") 
	ORDER BY DATE_FORMAT(finalDate, "%M-%d") ASC, finalState;~);
	$sth->execute();
	my $A = $sth->fetchall_arrayref;
	$sth->finish;
	
	my $CHRT = {};
	for my $i ( 0 .. $#{$A} ) {
		$CHRT->{$A->[$i][0]}->{$A->[$i][1]} = $A->[$i][2];
	}
	
	my $grid = qq~<table cellpadding="0" cellspacing="0" border="0" class="gridTable" style="margin-right: 40px; margin-top: 40px; ">
	<tr>
	<td class="gridTitle">$MSG{Date}</td>
	<td class="gridTitle">Resolved</td>
	<td class="gridTitle">Rejected</td>
	<td class="gridTitle">Failed</td>
	<td class="gridTitle">Pending</td>
	</tr>~;
	
	foreach my $day ( sort keys %{$CHRT} ) {
		$dayNice = $day;
		$dayNice =~ s/-/ /;
		$grid .= qq~<tr><td class="gridContent">$dayNice</td>~;
		foreach my $state ( 'Resolved', 'Rejected', 'Failed', 'Pending', ) {
			if ( $CHRT->{$day}->{$state} ) {
				$grid .= qq~<td class="gridContent" style="text-align: center">$CHRT->{$day}->{$state}</td>~;
			} else {
				$grid .= qq~<td class="gridContent" style="text-align: center"> &nbsp; </td>~;
			}
			
		}
		$grid .= qq~</tr>~;
	}
	
	$grid .= qq~</table>~;
	####
	
	$html .= qq~
		<script type="text/javascript">
			// PIE CHART
			google.charts.setOnLoadCallback(drawChart$i);
			
			function drawChart$i() {
				var data$i = google.visualization.arrayToDataTable([
					$pieChart
				]);
				
				var options$i = {
					legend: 'right',
					title: 'Percentage by STATE for $TypeTT->[$i][0] Tickets',
					pieHole: 0.3,
					colors: ['#2AB65F', '#2A6AB6', '#A13D3D', '#C48512', '#E9B7C0']
				};
				
				var chart$i = new google.visualization.PieChart(document.getElementById('piechart$i'));
				
				chart$i.draw(data$i, options$i);
			}
			
	    </script>
	    
	    <tr><td valign="top">
	    <div id="piechart$i" style="width: 800px; height: 600px;"></div>
	    </td><td valign="top">
	    $grid
	    </td></tr>
	~;
}

$dbh->disconnect if ($dbh);

$html .= qq~</table>~;


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
