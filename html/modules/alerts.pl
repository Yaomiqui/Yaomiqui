%MSG = loadLang('alerts');

my $html;

$html .= qq~<div class="contentTitle">Something</div>~ unless $input{'shtl'};

if ( $input{submod} eq 'silenceAlert' ) {
    connected();
    my $sth = $dbh->prepare("UPDATE alerts SET silenced = '1' WHERE idAlert = '$input{idAlert}'");
    $sth->execute();
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    print "Location: launcher.cgi?mod=alerts&submod=alertView&shtl=1&idView=$input{idView}\n\n";
    
    my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("SILENCE:Alert:idAlert=$input{idAlert}");
}

unless ( $input{submod} ) {
    connected();
    my $sth = $dbh->prepare("SELECT * FROM alertsView");
    $sth->execute();
    my $views = $sth->fetchall_arrayref;
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    my $optionAlerts;
    $optionAlerts .= qq~<option value="all">$MSG{All_alerts}</option>~;
    
    for my $i ( 0 .. $#{$views}) {
        $optionAlerts .= qq~<option value="$views->[$i][0]">$views->[$i][1]</option>~;
    }
    
    $html .= qq~
    <form method="get" action="launcher.cgi" target="AlertListing">
    <input type="hidden" name="mod" value="alerts">
    <input type="hidden" name="submod" value="alertView">
    <input type="hidden" name="shtl" value="1">
    <select name="idView" onChange="this.form.submit();">
    <option value=""> - $MSG{Please_select_some_view} - </option>
    $optionAlerts
    </select>
    </form>
    <br>
    ~;
    
    $html .= qq~
    <script type="text/javascript" src="js/jquery-resizable.js"></script>
    
    <div style="height: calc(100% - 88px); width: 100%; position: relative;">
        <div class="vertical">
            <div class="top">
                <iframe name="AlertListing" style="width: 100%; height: 100%; border: 0; overflow-y: scroll !important;" scrolling="yes" frameborder="0" scrolling="yes"></iframe>
            </div>
            <div class="splitter-horizontal"> : : : : : : : : </div>
            <div class="bottom">
                <iframe name="AlertDetail" style="width: 100%; height: 100%; border: 0 overflow-y: scroll !important;" scrolling="yes" frameborder="0" scrolling="yes"></iframe>
            </div>
        </div>
    </div>
    
    <script type="text/javascript">
        \$(".top").resizable({
           handleSelector: ".splitter-horizontal",
           resizeWidth: false
         });
    </script>
    ~;
}

# if ( $input{idView} ) {
if ( $input{submod} eq 'alertView' ) {
    connected();
    my $sth = $dbh->prepare("SELECT * FROM alertsView WHERE idView = '$input{idView}'");
    $sth->execute();
    my ($no, $no1, $severity, $impact, $urgency, $queue, $title, $definition, $description) = $sth->fetchrow_array;
    $sth->finish;
    
    my $idView = $input{idView};
    my $refreshRate = $VAR{REFRESH_RATE} * 5;
    
    $html .= qq~
	<script>
		function startRefresh() {
		    \$.get('', function(data) {
		        \$(document.body).html(data);    
		    });
		}
		\$(function() {
		    setTimeout(startRefresh,$refreshRate);
		});
	</script>
	~;
    
    $html .= qq~
    <script type="text/javascript" src="js/sorTable.js"></script>
    <table class="w3-table w3-bordered" style="background-color: #F4F4F4; border-top: 1px solid #E5E5E5;">
    <tr>
       <th><input type="text" placeholder="$MSG{Search_for_Title}.." id="myInput" onkeyup="myFunction()" style="width: 400px; margin-top: 0px; margin-bottom: 0px;"></th>
    </tr>
    </table>
    
	<table cellpadding="0" cellspacing="0" border="0" class="sortable" id="myTable" style="border-top: 1px solid #FFFFFF;">
	<thead>
		<tr>
            <th style="color: #7F7F7F;">$MSG{Alert_ID}</th>
            <th>$MSG{Qty}</th>
            <th>$MSG{Insert_Date}</th>
            <th>$MSG{Queue}</th>
            <th>$MSG{Severity}</th>
            <th>$MSG{Title}</th>
            <th>$MSG{Definition}</th>
            <th>$MSG{Description}</th>
		</tr>
	</thead>
	~;
    
    my $AND;
    $AND .= qq~severity = '$severity' AND ~ if $severity;
    $AND .= qq~impact = '$impact' AND ~ if $impact;
    $AND .= qq~urgency = '$urgency' AND ~ if $urgency;
    $AND .= qq~queue = '$queue' AND ~ if $queue;
    $AND .= qq~title = '$title' AND ~ if $title;
    $AND .= qq~definition = '$definition' AND ~ if $definition;
    $AND .= qq~description = '$description' AND ~ if $description;
    $AND = '' if $idView eq 'all';
    
    my $sth = $dbh->prepare("SELECT A.*, T.countToStatusUp, T.minutesToStatusDown FROM alerts as A, alertTriggerToAutoBot as T WHERE $AND A.idTrigger = T.idTrigger");
    $sth->execute();
    my $alert = $sth->fetchall_arrayref;
    $sth->finish;
    
    if ( $alert ) {
		for my $i ( 0 .. $#{$alert} ) {
            
            ####
            my $lastDate = $alert->[$i][3];
            my $minutesToStatusDown = $alert->[$i][15];
            
            my $sysdate = sysdate();
            my ($year, $month, $day, $hour, $min, $seg) = parseDataDate($sysdate);
            
            my $totalMinutes;
            my ($lyear, $lmonth, $lday, $lhour, $lmin, $lseg) = parseDataDate($lastDate);
            
            use Date::Calc qw(Delta_DHMS);
            my ($tday, $thour, $tmin, $tsec) = Delta_DHMS($lyear, $lmonth, $lday, $lhour, $lmin, $lseg, $year, $month, $day, $hour, $min, $seg);
            
            $totalMinutes = $tmin;
            $totalMinutes += $tday * 24 * 60;
            $totalMinutes += $thour * 60;
            $totalMinutes += ($tsec * (100 / 60)) / 100;
            $totalMinutes = sprintf("%.2f", $totalMinutes);
            # print "TOTAL MINUTES DIFF: $totalMinutes\n";
            ####
            
			my $colorSeverity = '#DD0000' if $alert->[$i][5] eq '0';
            $colorSeverity = '#C7241D' if $alert->[$i][5] eq '1';
            $colorSeverity = '#D87212' if $alert->[$i][5] eq '2';
            $colorSeverity = '#CBCB1A' if $alert->[$i][5] eq '3';
            $colorSeverity = '#489AE6' if $alert->[$i][5] eq '4';
            
            my $color = '#1777D4';
            my $limit = $alert->[$i][14];   # countToStatusUp
            $color = '#C76700' if $alert->[$i][1] >= $limit;
            $limit = $limit + 1;
            $color = '#FF0000' if $alert->[$i][1] >= $limit;
            my $colorSilenceLink = '#008000';
            if ( $totalMinutes >= $minutesToStatusDown ) {
                $color = '#7FBE7F';
                $colorSeverity = '#7FBE7F';
                $colorSilenceLink = '#7FBE7F';
            }
            if ( $alert->[$i][13] eq '1' ) {
                $color = '#A0A0A0';
                $colorSeverity = '#A0A0A0';
                $colorSilenceLink = '#A0A0A0';
            }
            
            $alert->[$i][11] = substr($alert->[$i][11], 0, 40);
            
			$html .= qq~<tr class="gridRowContent" style="color: #FF0000; cursor: pointer;" onclick="window.parent.AlertDetail.location='launcher.cgi?mod=alerts&submod=ViewAlertDetail&shtl=1&idAlert=$alert->[$i][0]'; target='AlertDetail';">
            <td class="gridContent" style="color: #7F7F7F;">$alert->[$i][0]</td>
            <td class="gridContent" style="color: $color;">$alert->[$i][1]</td>
            <td class="gridContent" style="color: $color;">$alert->[$i][2]</td>
            <td class="gridContent" style="color: $color; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">$alert->[$i][8]</td>
            <td class="gridContent" style="color: $colorSeverity; font-weight: bold">$alert->[$i][5]</td>
			<td class="gridContent" style="color: $color; overflow: hidden; text-overflow: ellipsis">$alert->[$i][9]</th>
			<td class="gridContent" style="color: $color; overflow: hidden; text-overflow: ellipsis">$alert->[$i][10]</td>
			<td class="gridContent" style="color: $color; overflow: hidden; text-overflow: ellipsis">$alert->[$i][11]
            <a style="float: right; color: $colorSilenceLink;" href="index.cgi?mod=alerts&submod=silenceAlert&idView=$idView&idAlert=$alert->[$i][0]" onclick="return confirm('$MSG{Are_you_sure_to_Silence_this_Alert}?')">$MSG{Silence}</a>
            </td>
			</tr>~;
		}
	}
	
	$dbh->disconnect if ($dbh);
    
	$html .= qq~</table><br>
    <script>
    function myFunction() {
      var input, filter, table, tr, td, i;
      input = document.getElementById("myInput");
      filter = input.value.toUpperCase();
      table = document.getElementById("myTable");
      tr = table.getElementsByTagName("tr");
      for (i = 0; i < tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[4];
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


if ( $input{submod} eq 'ViewAlertDetail' ) {
    # $html .= qq~Alert Deyail: idAlert = '$input{idAlert}'<br>~;
    
    connected();
    my $sth = $dbh->prepare(qq~SELECT * FROM alerts as A, scalation as S WHERE A.idAlert = '$input{idAlert}' AND S.idAlert = A.idAlert~);
    $sth->execute();
    my @alert = $sth->fetchrow_array;
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    $html .= qq~
    <div class="w3-container">
        <p >$MSG{Description}:</p>
        <p>$alert[11]</p>
    </div>
    
    <table callpadding="0" cellspacing="0" border="0" width="100%" style="margin-top: 2px; border-top: 1px solid #BFBFBF"><tr>
        <td style="border-right: 1px solid #BFBFBF;" width="50%" valign="top">
            <table callpadding="0" cellspacing="6" border="0">
                <tr>
                  <td>$MSG{Title}:</td><td>$alert[9]</td>
                </tr>
                <tr>
                  <td>$MSG{Definition}:</td><td>$alert[10]</td>
                </tr>
                <tr>
                  <td>$MSG{Insert_Date}:</td><td>$alert[2]</td>
                </tr>
                <tr>
                  <td>$MSG{Last_Event_Date}:</td><td>$alert[3]</td>
                </tr>
                <tr>
                  <td>$MSG{Queue}:</td> <td>$alert[8]</td>
                </tr>
                <tr>
                  <td>$MSG{Severity}:</td><td>$alert[5]</td>
                </tr>
                <tr>
                  <td>$MSG{Impact}:</td><td>$alert[6]</td>
                </tr>
                <tr>
                  <td>$MSG{Urgency}:</td><td>$alert[7]</td>
                </tr>
            </table>
        </td>
        <td width="50%" valign="top">
            <table callpadding="0" cellspacing="6" border="0">
                <tr>
                  <td>$MSG{First} $MSG{Scalation}:</td><td>$alert[16]</td>
                </tr>
                <tr>
                  <td>$MSG{First} $MSG{Scalation} $MSG{Ticket_Number}:</td><td>$alert[17]</td>
                </tr>
                <tr>
                  <td>$MSG{Second} $MSG{Scalation}:</td><td>$alert[18]</td>
                </tr>
                <tr>
                  <td>$MSG{Second} $MSG{Scalation} $MSG{Ticket_Number}:</td><td>$alert[19]</td>
                </tr>
                <tr>
                  <td>$MSG{Third} $MSG{Scalation}:</td><td>$alert[20]</td>
                </tr>
                <tr>
                  <td>$MSG{Third} $MSG{Scalation} $MSG{Ticket_Number}:</td><td>$alert[21]</td>
                </tr>
            </table>
        </td>
    </tr></table>
    ~;
}


return $html;

sub parseDataDate {
    my $date = shift;
    
    $date =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/;  #2020-06-06 10:17:30
    my $yr = $1;
    my $mon = $2;
    my $day = $3;
    my $hr = $4;
    my $min = $5;
    my $seg = $6;
    
    return ($yr, $mon, $day, $hr, $min, $seg)
}

sub generateRandomKey {
	my @chars = ('a'..'z',0..9,'A'..'Z',0..9);
	my $long = shift;
	my $key;
	for ( 1 .. $long ) {
		$key .= $chars[int(rand(@chars))];
	}
	return $key;
}

sub sysdate {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	$fecha[4] ++;
	@fecha = map { if ($_ < 10) { $_ = "0$_"; }else{ $_ } } @fecha;
	return my $sysdate = "$fecha[5]-$fecha[4]-$fecha[3] $fecha[2]:$fecha[1]:$fecha[0]";
}

1;
