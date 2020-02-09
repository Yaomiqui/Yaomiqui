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


$html .= qq~<div style="text-align: right; width: 100%;"><a href="index.cgi?mod=charts&submod=viewTable&yearToChart=$input{yearToChart}&dateToChart=$input{dateToChart}" style="padding-right: 40px">$MSG{Show_as_Tables}</a></div>~ if $input{submod} ne 'viewTable';

$html .= qq~
<table cellpadding="0" cellspacing="0" border="0" style="background-color: #FFFFFF">
~;

connected();
my $sth = $dbh->prepare("SELECT DISTINCT(typeTicket) FROM ticket WHERE finalDate between '$year-$month-01 00:00:00' and '$year-$month-31 23:59:59'");
$sth->execute();
my $TypeTT = $sth->fetchall_arrayref;
$sth->finish;

for my $i ( 0 .. $#{$TypeTT} ) {
	# $html .= qq~<b>$MSG{Ticket_Type}: $TypeTT->[$i][0]</b><br>~;
	
	my $sth = $dbh->prepare("SELECT finalState, count(finalState) FROM ticket WHERE typeTicket='$TypeTT->[$i][0]' AND finalDate between '$year-$month-01 00:00:00' and '$year-$month-31 23:59:59' GROUP BY finalState ORDER BY finalState DESC");
	$sth->execute();
	my $typeTicket = $sth->fetchall_arrayref;
	$sth->finish;
	
    my $total;
    my $series;
    my $labels;
	
	for my $j ( 0 .. $#{$typeTicket} ) {
		# $pieChart .= qq~['$typeTicket->[$j][0]', $typeTicket->[$j][1]],\n~;
        $series .= qq~$typeTicket->[$j][1], ~;
        $labels .= qq~'$typeTicket->[$j][0]', ~;
        $total += $typeTicket->[$j][1];
	}
	
	# No state:
	my $sth = $dbh->prepare("SELECT COUNT(idTicket) FROM ticket WHERE typeTicket='$TypeTT->[$i][0]' AND initialDate between '$year-$month-01 00:00:00' and '$year-$month-31 23:59:59' AND finalState IS NULL");
	$sth->execute();
	my ($cnt) = $sth->fetchrow_array;
	$sth->finish;
	
    $series .= qq~$cnt, ~;
    $labels .= qq~'No State', ~;
    $total += $cnt;
    
    $series =~ s/, $//;
    $labels =~ s/, $//;
	
    if ( $input{submod} eq 'viewTable' ) {
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
        
        my $grid = qq~<br><br>$MSG{Ticket_Type}: <b>$TypeTT->[$i][0]<br> <br>
        <table cellpadding="0" cellspacing="0" border="0" class="gridTable" style="margin-right: 40px;">
        <tr>
        <td class="gridTitle">$MSG{Date}</td>
        <td class="gridTitle">Resolved</td>
        <td class="gridTitle">Rejected</td>
        <td class="gridTitle">Failed</td>
        <td class="gridTitle">Pending</td>
        <td class="gridTitle">Canceled</td>
        </tr>~;
        
        foreach my $day ( sort keys %{$CHRT} ) {
            $dayNice = $day;
            $dayNice =~ s/-/ /;
            $grid .= qq~<tr><td class="gridContent">$dayNice</td>~;
            foreach my $state ( 'Resolved', 'Rejected', 'Failed', 'Pending', 'Canceled' ) {
                if ( $CHRT->{$day}->{$state} ) {
                    $grid .= qq~<td class="gridContent" style="text-align: center">$CHRT->{$day}->{$state}</td>~;
                } else {
                    $grid .= qq~<td class="gridContent" style="text-align: center"> &nbsp; </td>~;
                }
                
            }
            $grid .= qq~</tr>~;
        }
        
        $grid .= qq~</table>~;
        
        $html .= qq~
        </td><td valign="top">
	    $grid
	    </td></tr>
        ~;
        
    } else {
        ############################
        my $sth = $dbh->prepare(qq~SELECT DATE_FORMAT(finalDate, "%M"), DATE_FORMAT(finalDate, "%d"), finalState, count(finalState) 
        FROM ticket WHERE typeTicket='$TypeTT->[$i][0]' 
        AND finalDate between '$year-$month-01 00:00:00' AND '$year-$month-31 23:59:59' 
        GROUP BY finalState, DATE_FORMAT(finalDate, "%M/%d") 
        ORDER BY DATE_FORMAT(finalDate, "%M-%d") ASC, finalState;~);
        $sth->execute();
        my $A = $sth->fetchall_arrayref;
        $sth->finish;
        
        my $month;
        my $CHRT = {};
        for my $i ( 0 .. $#{$A} ) {
            $CHRT->{$A->[$i][1]}->{$A->[$i][2]} = $A->[$i][3];
            $month = $A->[$i][0];
        }
        
        # {
        #     name: "Resolved",
        #     data: [28, 29, 33, 36, 32, 32, 33]
        # },
        
        # categories: ['01', '02', '03', '04', '05', '06', '07'],
        
        my $lineSeries;
        my $max;
        foreach my $state ( 'Resolved', 'Rejected', 'Failed', 'Pending', 'Canceled' ) {
            my $name = qq~"$state"~;
            my $categories;
            my $data;
            
            ## days
            foreach my $day ( sort keys %{$CHRT} ) {
                $categories .= $day . ", ";
            }
            $categories =~ s/, $//;
            
            ## quantities
            foreach my $day ( sort keys %{$CHRT} ) {
                $data .= $CHRT->{$day}->{$state} . ", ";
                $max = $CHRT->{$day}->{$state} if $CHRT->{$day}->{$state} >= $max;
            }
            $data =~ s/, $//;
            $data = '[' . $data . ']';
            
            $lineSeries .= '{ name: ' . $name . ', data: ' . $data . '},';
        }
        $lineSeries =~ s/,$//;
        ############################
	
        $html .= qq~
	    <tr><td valign="top" style="padding-bottom: 15px; padding-top: 15px;">
    <div id="chart$i" style="padding-left: 10px; padding-top: 10px; margin-right: 20px; background: #FFFFFF; border: 1px solid #DDDDDD; box-shadow: 0 22px 35px -16px rgba(0,0,0, 0.1);"></div>
      <script>
        var options = {
          series: [$series],
          chart: {
            animations: {
            enabled: false,
            easing: 'easeinout',
            speed: 800,
            animateGradually: {
              enabled: false,
                delay: 150
              },
              dynamicAnimation: {
                enabled: false,
                speed: 350
              }
            },
            width: 380,
            height: 300,
            type: 'pie',
          },
          colors: ['#008FFB', '#BB3636', '#FF4560', '#FEB019', '#00E396', '#B39342'],
          title: {
            text: '$MSG{Ticket_Type} $TypeTT->[$i][0]. Total: $total on $month',
            align: 'left'
          },
          labels: [$labels],
          responsive: [{
            breakpoint: 480,
              options: {
                chart: {
                  width: 200
                },
              legend: {
                position: 'bottom'
              }
            }
          }]
        };

        var chart = new ApexCharts(document.querySelector("#chart$i"), options);
        chart.render();
      </script>
        
	    </td>~;
        
        if ( $input{showLineCharts} eq 'y' ) {
            $html .= qq~<td valign="top" style="padding-bottom: 15px; padding-top: 15px;">
    <div id="chart_$i" style="padding-left: 10px; padding-top: 10px; margin-right: 20px; background: #FFFFFF; border: 1px solid #DDDDDD; box-shadow: 0 22px 35px -16px rgba(0,0,0, 0.1);"></div>
    <script>
        var options = {
          series: [
          $lineSeries
        ],
          chart: {
          animations: {
            enabled: false,
            easing: 'easeinout',
            speed: 800,
            animateGradually: {
              enabled: false,
                delay: 150
              },
              dynamicAnimation: {
                enabled: false,
                speed: 350
              }
            },
          
          width: 650,
          height: 296,
          type: 'line',
          dropShadow: {
            enabled: true,
            color: '#000',
            top: 18,
            left: 7,
            blur: 10,
            opacity: 0.2
          },
          toolbar: {
            show: false
          }
        },
        colors: ['#008FFB', '#BB3636', '#FF4560', '#FEB019', '#00E396'],
        dataLabels: {
          enabled: false,
        },
        stroke: {
          curve: 'smooth'
        },
        title: {
          text: '$MSG{Ticket_Type} $TypeTT->[$i][0]',
          align: 'left'
        },
        grid: {
          borderColor: '#e7e7e7',
          row: {
            colors: ['#f3f3f3', 'transparent'], // takes an array which will be repeated on columns
            opacity: 0.5
          },
        },
        markers: {
          size: 1
        },
        xaxis: {
          categories: [$categories],
          title: {
            text: '$month'
          }
        },
        yaxis: {
          title: {
            text: 'Tickets Quantity'
          },
          min: 0,
          max: $max
        },
        legend: {
          position: 'top',
          horizontalAlign: 'right',
          floating: true,
          offsetY: -25,
          offsetX: -5
        }
        };

        var chart = new ApexCharts(document.querySelector("#chart_$i"), options);
        chart.render();
    </script>~;
        }
        else {
            $html .= qq~<td style="padding-bottom: 15px; padding-top: 15px;">
            <div class="sampleChartImg">
              <div class="sampleChartBtn">
               <a class="showCharts" style="color: #4D4D4D;" href="index.cgi?mod=charts&yearToChart=$input{yearToChart}&dateToChart=$input{dateToChart}&showLineCharts=y">$MSG{Show_Line_Charts}</a>
              </div>
            </div>
            ~;
        }
        
	    $html .= qq~</td></tr>~;
    }
}

$dbh->disconnect if ($dbh);

$html .= qq~</table><br><br>~;

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
