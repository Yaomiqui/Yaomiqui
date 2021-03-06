%MSG = loadLang('overview');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Overview}</div>~ unless $input{'shtl'};

# $html .= qq~
# <div style="width: auto; height: 89%; background-color: ##efefef;">

# </div>
# ~;

connected();
my $sth = $dbh->prepare("SELECT DISTINCT(typeTicket) FROM ticket");
$sth->execute();
my $STS = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);


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

my $year = $input{year} ? $input{year} : currentYear();
my $month = $input{month} ? $input{month} : currentMonth();
my $page = $input{page} || 1;

$input{year} = delMalCode($input{year});
$input{month} = delMalCode($input{month});
$input{page} = delMalCode($input{page});
$input{state} = delMalCode($input{state});

$html .= qq~
<table cellpadding="0" cellspacing="2" border="0" width="100%">
	<tr>
		<td width="100%">
		~;

$html .= qq~
			<form method="get" action="launcher.cgi" target="ticket">
			<input type="hidden" name="mod" value="tickets">
			<input type="hidden" name="submod" value="findTicket">
			<input type="hidden" name="page" value="$page">
			<input type="hidden" name="shtl" value="1">
			<input type="text" name="year" value="$year" style="width: 60px">
			<select name="month" onChange="this.form.submit();">
~;

for my $monNum ( sort keys %MON ) {
	if ( $monNum eq $month ) {
		$html .= qq~<option value="$monNum" selected>$MON{$monNum}</option>~;
	} else {
		$html .= qq~<option value="$monNum">$MON{$monNum}</option>~;
	}
}

$html .= qq~
			</select>
			<select name="state" onChange="this.form.submit();">
			<option value="">$MSG{All_States}</option>
			<option value="Resolved">Resolved</option>
			<option value="Failed">Failed</option>
			<option value="Rejected">Rejected</option>
			<option value="Pending">Pending</option>
			<option value="Canceled">Canceled</option>
			</select>
			
			<select name="typeTicket" onChange="this.form.submit();">
			<option value="">$MSG{All_Types}</option>
~;


for my $i ( 0 .. $#{$STS} ) {
	if ( $STS->[$i][0] eq $input{typeTicket} ) {
		$html .= qq~<option value="$STS->[$i][0]" selected>$STS->[$i][0]</option>~;
	} else {
		$html .= qq~<option value="$STS->[$i][0]">$STS->[$i][0]</option>~;
	}
}


$html .= qq~
			</select>
			&nbsp; 
			$MSG{or_find_Ticket}: <input type="text" name="ftt" maxlength="100" style="width:200px" placeholder="$MSG{Type_a_ticket_Number}" > &nbsp;
			<input class="blueLightButton" type="submit" value="$MSG{Search}">
			</form>
            
            </td>
            </tr>
            </table>
            <br/>~;
			
$html .= qq~
<script type="text/javascript" src="js/jquery-resizable.js"></script>

<div class="horizontal">
    <div class="izquierda">
        <iframe class="content" name="ticket" id="ticket" scrolling="auto" src="launcher.cgi?mod=tickets&submod=findTicket&year=$year&month=$month&state=&ftt=&page=$page&shtl=1" frameborder="0" width="100%" height="100%"></iframe>
    </div>
    <div class="splitter"></div>
    <div class="derecha">
        <iframe class="content" name="logs" id="logs" scrolling="auto" frameborder="0" width="100%" style="height: 100%;"></iframe>
    </div>
<div>

<script type="text/javascript">
    \$(".izquierda").resizable({
        handleSelector: ".splitter",
        resizeHeight: false
    });
</script>
~;
# left

# src="launcher.cgi?mod=logs&shtl=1"
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
