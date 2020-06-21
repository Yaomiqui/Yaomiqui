%MSG = loadLang('alerts_config');

my $html;

$html .= qq~<div class="contentTitle">Something</div>~ unless $input{'shtl'};

if ( $input{submod} eq 'save_updated_alert' ) {
    if ( $input{idView} ) {
        $input{viewName} = delMalCode($input{viewName});
        $input{severity} = delMalCode($input{severity});
        $input{impact} = delMalCode($input{impact});
        $input{urgency} = delMalCode($input{urgency});
        $input{queue} = delMalCode($input{queue});
        $input{title} = delMalCode($input{title});
        $input{definition} = delMalCode($input{definition});
        $input{description} = delMalCode($input{description});
        
        connected();
        my $sth = $dbh->prepare("UPDATE alertsView SET
        viewName = '$input{viewName}',
        severity = '$input{severity}',
        impact = '$input{impact}',
        urgency = '$input{urgency}',
        queue = '$input{queue}',
        title = '$input{title}',
        definition = '$input{definition}',
        description = '$input{description}'
        WHERE idView = '$input{idView}'");
        $sth->execute();
        $sth->finish;
        $dbh->disconnect if ($dbh);
    }
    
    my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("UPDATE:Alert:idView=$input{idView}");
    
    print "Location: index.cgi?mod=alerts_config&submod=alertViews&idView=$input{idView}\n\n";
}

if ( $input{submod} eq 'save_updated_Trigger' ) {
    if ( $input{idTrigger} ) {
        $input{triggerName} = delMalCode($input{triggerName});
        $input{countToStatusUp} = delMalCode($input{countToStatusUp});
        $input{minutesToStatusDown} = delMalCode($input{minutesToStatusDown});
        $input{minutesToHidden} = delMalCode($input{minutesToHidden});
        $input{dlFirstEscalation} = delMalCode($input{dlFirstEscalation});
        $input{dlSecondEscalation} = delMalCode($input{dlSecondEscalation});
        $input{dlThirdEscalation} = delMalCode($input{dlThirdEscalation});
        $input{idAutoBot} = delMalCode($input{idAutoBot});
        $input{Json} = delMalCode($input{Json});
        
        connected();
        my $sth = $dbh->prepare("UPDATE alertTriggerToAutoBot SET 
        triggerName = '$input{triggerName}',
        countToStatusUp = '$input{countToStatusUp}',
        minutesToStatusDown = '$input{minutesToStatusDown}',
        minutesToHidden = '$input{minutesToHidden}',
        dlFirstEscalation = '$input{dlFirstEscalation}',
        dlSecondEscalation = '$input{dlSecondEscalation}',
        dlThirdEscalation = '$input{dlThirdEscalation}',
        idAutoBot = '$input{idAutoBot}',
        Json = '$input{Json}'
        WHERE idTrigger = '$input{idTrigger}'");
        $sth->execute();
        $sth->finish;
        $dbh->disconnect if ($dbh);
    }
    my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("UPDATE:Trigger:idTrigger=$input{idTrigger}");
    
    print "Location: index.cgi?mod=alerts_config&submod=triggersMan&idTrigger=$input{idTrigger}\n\n";
}

if ( $input{submod} eq 'save_new_alert' ) {
    if ( $input{viewName} ) {
        $input{viewName} = delMalCode($input{viewName});
        $input{severity} = delMalCode($input{severity});
        $input{impact} = delMalCode($input{impact});
        $input{urgency} = delMalCode($input{urgency});
        $input{queue} = delMalCode($input{queue});
        $input{title} = delMalCode($input{title});
        $input{definition} = delMalCode($input{definition});
        $input{description} = delMalCode($input{description});
        
        connected();
        my $sth = $dbh->prepare(qq~INSERT INTO alertsView (viewName, severity, impact, urgency, queue, title, definition, description)
        VALUES ('$input{viewName}', '$input{severity}', '$input{impact}', '$input{urgency}', '$input{queue}', '$input{title}', '$input{definition}', '$input{description}')~);
        $sth->execute();
        $sth->finish;
        $dbh->disconnect if ($dbh);
    }
    
    my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("NEW:Alert:viewName=$input{viewName}");
    
    print "Location: index.cgi?mod=alerts_config&submod=alertViews\n\n";
}

if ( $input{submod} eq 'save_new_Trigger' ) {
    if ( $input{countToStatusUp} and $input{minutesToStatusDown} and $input{minutesToHidden} ) {
        $input{triggerName} = delMalCode($input{triggerName});
        $input{countToStatusUp} = delMalCode($input{countToStatusUp});
        $input{minutesToStatusDown} = delMalCode($input{minutesToStatusDown});
        $input{minutesToHidden} = delMalCode($input{minutesToHidden});
        $input{dlFirstEscalation} = delMalCode($input{dlFirstEscalation});
        $input{dlSecondEscalation} = delMalCode($input{dlSecondEscalation});
        $input{dlThirdEscalation} = delMalCode($input{dlThirdEscalation});
        $input{idAutoBot} = delMalCode($input{idAutoBot});
        $input{Json} = delMalCode($input{Json});
        
        connected();
        my $sth = $dbh->prepare(qq~INSERT INTO alertTriggerToAutoBot (triggerName, countToStatusUp, minutesToStatusDown, minutesToHidden, dlFirstEscalation, dlSecondEscalation, dlThirdEscalation, idAutoBot, Json)
        VALUES ('$input{triggerName}', '$input{countToStatusUp}', '$input{minutesToStatusDown}', '$input{minutesToHidden}', '$input{dlFirstEscalation}', '$input{dlSecondEscalation}', '$input{dlThirdEscalation}', '$input{idAutoBot}', '$input{Json}')~);
        $sth->execute();
        $sth->finish;
        
        my $sth = $dbh->prepare("SELECT idTrigger FROM alertTriggerToAutoBot ORDER BY idTrigger DESC LIMIT 1");
        $sth->execute();
        my ($idTrigger) = $sth->fetchrow_array;
        $sth->finish;
        
        $input{Json} =~ s/\$\{idTrigger\}/$idTrigger/;
        
        my $sth = $dbh->prepare("UPDATE alertTriggerToAutoBot SET Json = '$input{Json}' WHERE idTrigger = '$idTrigger'");
        $sth->execute();
        $sth->finish;
        
        $dbh->disconnect if ($dbh);
    }
    
    my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("NEW:Trigger:triggerName=$input{triggerName}");
    
    print "Location: index.cgi?mod=alerts_config&submod=triggersMan\n\n";
}

unless ( $input{submod} ) {
    $html .= qq~
    <table cellspacing="0" cellpadding="0" border"0">
    <tr>
        <td width="50%" align="center" valign="top" style="padding: 40px;">
            <a href="index.cgi?mod=alerts_config&submod=alertViews">
            <div class="w3-display-container">
              <img src="themes/$theme/images/alertsViewsButton.png" alt="Scalation Management">
              <div class="w3-display-bottomleft w3-container">$MSG{Alert_Views}</div>
            </div>
            </a>
        </td>
        <td width="50%" align="center" valign="top" style="padding: 40px;">
            <a href="index.cgi?mod=alerts_config&submod=triggersMan">
            <div class="w3-display-container">
              <img src="themes/$theme/images/triggersButton.png" alt="Trigger Management">
              <div class="w3-display-bottomleft w3-container">$MSG{Trigger_Scalations}</div>
            </div>
            </a>
        </td>
    </tr>
    </table>
    ~;
}





if ( $input{submod} eq 'alertViews' ) {
    connected();
    my $sth = $dbh->prepare("SELECT * FROM alertsView");
    $sth->execute();
    my $views = $sth->fetchall_arrayref;
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    my $optionAlerts;
    for my $i ( 0 .. $#{$views}) {
        if ( $input{idView} eq $views->[$i][0] ) {
            $optionAlerts .= qq~<option value="$views->[$i][0]" selected>$views->[$i][1]</option>~;
        } else {
            $optionAlerts .= qq~<option value="$views->[$i][0]">$views->[$i][1]</option>~;
        }
    }
    
    $html .= qq~
    <form method="get" action="index.cgi" >
    <input type="hidden" name="mod" value="alerts_config">
    <input type="hidden" name="submod" value="alertViews">
    <select name="idView" onChange="this.form.submit();">
    <option value=""> - $MSG{Please_select_some_View_to_manage} - </option>
    $optionAlerts
    </select>
    </form>
    
    <div class="w3-right-align">
    <form method="get" action="index.cgi" >
    <input type="hidden" name="mod" value="alerts_config">
    <input type="hidden" name="submod" value="NewAlertView">
    <button class="w3-button w3-blue w3-round">$MSG{New_Alert_View}</button>
    </form>
    </div>
    ~;
    
    if ( $input{idView} ) {
        connected();
        my $sth = $dbh->prepare("SELECT * FROM alertsView WHERE idView = '$input{idView}'");
        $sth->execute();
        my $views = $sth->fetchall_arrayref;
        $sth->finish;
        $dbh->disconnect if ($dbh);
        
        $html .= qq~<table cellpadding="0" cellspacing="0" style="margin-bottom: 200px; padding: 20px;" class="w3-panel w3-card">~;
        
        for $i ( 0 .. $#{$views} ) {
            $html .= qq~
            <form method="post" action="index.cgi">
            <input type="hidden" name="mod" value="alerts_config">
            <input type="hidden" name="submod" value="save_updated_alert">
            <input type="hidden" name="idView" value="$input{idView}">
            <tr><td align="right">$MSG{View_Name}: </td><td><input type="text" name="viewName" maxlength="100" required value="$views->[$i][1]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Severity}: </td><td><input type="text" name="severity" maxlength="40" value="$views->[$i][2]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Impact}: </td><td><input type="text" name="impact" maxlength="40" value="$views->[$i][3]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Urgency}: </td><td><input type="text" name="urgency" maxlength="40" value="$views->[$i][4]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Queue}: </td><td><input type="text" name="queue" maxlength="40" value="$views->[$i][5]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Title}: </td><td><input type="text" name="title" maxlength="40" value="$views->[$i][6]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Definition}: </td><td><input type="text" name="definition" maxlength="40" value="$views->[$i][7]" style="width: 400px;"></td></tr>
            <tr><td align="right">$MSG{Description}: </td><td><input type="text" name="description" maxlength="40" value="$views->[$i][8]" style="width: 400px;"></td></tr>
            <tr><td align="right"> &nbsp; </td><td align="right"><br /><br /><input class="blueLightButton" type="submit" value="$MSG{Update}"></td></tr>
            </form>
            ~;
        }
        
        $html .= qq~</table>~;
    }
}

if ( $input{submod} eq 'NewAlertView' ) {
    $html .= qq~$MSG{Please_fill_some_data_you_want_to_filter_to_create_a_new_Alert_View}<br><br>
    <table cellpadding="0" cellspacing="0" style="margin-bottom: 200px; padding: 20px;" class="w3-panel w3-card">~;
    
    $html .= qq~
    <form method="post" action="index.cgi">
    <input type="hidden" name="mod" value="alerts_config">
    <input type="hidden" name="submod" value="save_new_alert">
    <tr><td align="right">$MSG{View_Name}: </td><td><input type="text" name="viewName" maxlength="100" required style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Severity}: </td><td><input type="text" name="severity" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Impact}: </td><td><input type="text" name="impact" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Urgency}: </td><td><input type="text" name="urgency" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Queue}: </td><td><input type="text" name="queue" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Title}: </td><td><input type="text" name="title" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Definition}: </td><td><input type="text" name="definition" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right">$MSG{Description}: </td><td><input type="text" name="description" maxlength="40" style="width: 400px;"></td></tr>
    <tr><td align="right"> &nbsp; </td><td align="right"><br /><br /><input class="blueLightButton" type="submit" value="$MSG{Create_New}"></td></tr>
    </form>
    ~;
    
    $html .= qq~</table>~;
}






if ( $input{submod} eq 'triggersMan' ) {
    connected();
    my $sth = $dbh->prepare("SELECT * FROM alertTriggerToAutoBot");
    $sth->execute();
    my $views = $sth->fetchall_arrayref;
    $sth->finish;
    $dbh->disconnect if ($dbh);
    
    my $optionAlerts;
    for my $i ( 0 .. $#{$views}) {
        if ( $input{idTrigger} eq $views->[$i][0] ) {
            $optionAlerts .= qq~<option value="$views->[$i][0]" selected>[$views->[$i][0]] $views->[$i][1]</option>~;
        } else {
            $optionAlerts .= qq~<option value="$views->[$i][0]">[$views->[$i][0]] $views->[$i][1]</option>~;
        }
    }
    
    $html .= qq~
    <form method="get" action="index.cgi" >
    <input type="hidden" name="mod" value="alerts_config">
    <input type="hidden" name="submod" value="triggersMan">
    <select name="idTrigger" onChange="this.form.submit();">
    <option value=""> - $MSG{Please_select_some_Trigger_to_manage} - </option>
    $optionAlerts
    </select>
    </form>
    
    <div class="w3-right-align">
    <form method="get" action="index.cgi" >
    <input type="hidden" name="mod" value="alerts_config">
    <input type="hidden" name="submod" value="NewTrigger">
    <button class="w3-button w3-blue w3-round">$MSG{New_Trigger}</button>
    </form>
    </div>
    ~;
    
    if ( $input{idTrigger} ) {
        connected();
        my $sth = $dbh->prepare("SELECT * FROM alertTriggerToAutoBot WHERE idTrigger = '$input{idTrigger}'");
        $sth->execute();
        my $views = $sth->fetchall_arrayref;
        $sth->finish;
        $dbh->disconnect if ($dbh);
        
        $html .= qq~<div id="miquiloniToolTip"></div>
        <font style="color: #0505DA; font-size: 120%">idTrigger: <b>$views->[$i][0]</b></font><br/>
        <table cellpadding="0" cellspacing="0" style="margin-bottom: 200px; padding: 20px;" class="w3-panel w3-card">~;
        
        for $i ( 0 .. $#{$views} ) {
            $html .= qq~
            <form method="post" action="index.cgi">
            <input type="hidden" name="mod" value="alerts_config">
            <input type="hidden" name="submod" value="save_updated_Trigger">
            <input type="hidden" name="idTrigger" value="$input{idTrigger}">
            
            <tr><td align="right">$MSG{Trigger_Name}: </td><td><input type="text" name="triggerName" maxlength="40" value="$views->[$i][1]" style="width: 400px;"> &nbsp; 
            </td></tr>
            
            <tr><td align="right">$MSG{Count_To_Status_Up}: </td><td><input type="text" name="countToStatusUp" maxlength="2" required value="$views->[$i][2]" style="width: 400px;"> &nbsp; 
            <img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG{Counter_of_times_the_alert_should_appear_to_INCREASE}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
            </td></tr>
            
            <tr><td align="right">$MSG{Minutes_To_Status_Down}: </td><td><input type="text" name="minutesToStatusDown" maxlength="2" value="$views->[$i][3]" style="width: 400px;"> &nbsp; 
            <img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG{Minutes_quantity_that_must_elapse_DECREASE}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
            </td></tr>
            
            <tr><td align="right">$MSG{Minutes_To_Hidden}: </td><td><input type="text" name="minutesToHidden" maxlength="2" value="$views->[$i][4]" style="width: 400px;"> &nbsp; 
            <img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG{Minutes_quantity_that_must_elapse_before_alert_hidden}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
            </td></tr>
            
            <tr><td align="right">$MSG{Distribution_List_of_First_Escalation}: </td><td><input type="text" name="dlFirstEscalation" maxlength="255" value="$views->[$i][5]" style="width: 400px;"></td></tr>
            
            <tr><td align="right">$MSG{Distribution_List_of_Second_Escalation}: </td><td><input type="text" name="dlSecondEscalation" maxlength="255" value="$views->[$i][6]" style="width: 400px;"></td></tr>
            
            <tr><td align="right">$MSG{Distribution_List_of_Third_Escalation}: </td><td><input type="text" name="dlThirdEscalation" maxlength="255" value="$views->[$i][7]" style="width: 400px;"></td></tr>
            
            <tr><td align="right">$MSG{ID_AutoBot_to_trigger}: <br/><br/></td><td><input type="text" name="idAutoBot" maxlength="40" value="$views->[$i][8]" style="width: 400px;"> &nbsp; <br/><br/>
            </td></tr>
            
            <tr><td align="right" valign="top">$MSG{JSON_to_send_to_the_Autobot}: </td><td><textarea id="w3review" name="Json" rows="20" style="width: 600px; font-family: monospace; resize: both; color: #00007D;">$views->[$i][9]</textarea>
            </td></tr>
            
            <tr><td align="right"> &nbsp; </td><td align="right"><br /><br /><input class="blueLightButton" type="submit" value="$MSG{Update}"></td></tr>
            </form>
            ~;
        }
        
        $html .= qq~
        <tr><td align="right"> &nbsp; </td><td align="left"><br /><br />
        <b>[[AUTOMATED-DATA]]</b> $MSG{includes_the_following_Json_variables}:<br><br>
        <pre style="font-family: monospace; color: #00007D;">
    "idAlert": "",
    "escalationNumber": "[1 or 2 or 3]",
    "dlFirstEscalation": "",
    "dlSecondEscalation": "",
    "dlThirdEscalation": "",
    "insertDate": "",
    "severity": "",
    "impact": "",
    "urgency": "",
    "title": "",
    "definition": "",
    "description": ""</pre>
        </td></tr>
        </table>~;
    }
}

if ( $input{submod} eq 'NewTrigger' ) {
    $html .= qq~<div id="miquiloniToolTip"></div><table cellpadding="0" cellspacing="0" style="margin-bottom: 200px; padding: 20px;" class="w3-panel w3-card">~;
        
    $html .= qq~
    $MSG{fill_some_data_you_want_to_create_a_new_Trigger}<br><br>
    <br>
    <form method="post" action="index.cgi">
    <input type="hidden" name="mod" value="alerts_config">
    <input type="hidden" name="submod" value="save_new_Trigger">
    
    <tr><td align="right">$MSG{Trigger_Name}: <br/><br/></td><td><input type="text" name="triggerName" maxlength="40" style="width: 400px;"> &nbsp; <br/><br/>
    </td></tr>
    
    <tr><td align="right">$MSG{Count_To_Status_Up}: </td><td><input type="text" name="countToStatusUp" maxlength="2" required style="width: 400px;"> &nbsp; 
    <img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG{Counter_of_times_the_alert_should_appear_to_INCREASE}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
    </td></tr>
    
    <tr><td align="right">$MSG{Minutes_To_Status_Down}: </td><td><input type="text" name="minutesToStatusDown" maxlength="2" required style="width: 400px;"> &nbsp; 
    <img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG{Minutes_quantity_that_must_elapse_DECREASE}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
    </td></tr>
    
    <tr><td align="right">$MSG{Minutes_To_Hidden}: </td><td><input type="text" name="minutesToHidden" maxlength="2" required style="width: 400px;"> &nbsp; 
    <img src="../images/help_blue.png" width="16" onMouseOver="showToolTip('$MSG{Minutes_quantity_that_must_elapse_before_alert_hidden}', '#111165', '#E8FCE8', '300px');" onMouseout="hideToolTip();" />
    </td></tr>
    
    <tr><td align="right">$MSG{Distribution_List_of_First_Escalation}: </td><td><input type="text" name="dlFirstEscalation" maxlength="255" style="width: 400px;"></td></tr>
    
    <tr><td align="right">$MSG{Distribution_List_of_Second_Escalation}: </td><td><input type="text" name="dlSecondEscalation" maxlength="255" style="width: 400px;"></td></tr>
    
    <tr><td align="right">$MSG{Distribution_List_of_Third_Escalation}: </td><td><input type="text" name="dlThirdEscalation" maxlength="255" style="width: 400px;"></td></tr>
    
    <tr><td align="right">I$MSG{ID_AutoBot_to_trigger}: <br/><br/></td><td><input type="text" name="idAutoBot" maxlength="40" style="width: 400px;"> &nbsp; <br/><br/>
    </td></tr>
    
    <tr><td align="right" valign="top">$MSG{JSON_to_send_to_the_Autobot}: </td><td><textarea id="w3review" name="Json" rows="20" style="width: 600px; font-family: monospace; resize: both; color: #00007D;" readonly>{
  "ticket": {
    "number": "\${randomNumber}",
    "sys_id": "\${randomSysId}",
    "subject": "Escalation for Trigger \${idTrigger}",
    "state": "",
    "type": "",
    [[AUTOMATED-DATA]]
	},
  "data": {
    
  }
}</textarea>
    </td></tr>
    
    <tr><td align="right"> &nbsp; </td><td align="right"><br /><br /><input class="blueLightButton" type="submit" value="$MSG{Create_New_Trigger}"></td></tr>
    </form>
    ~;
        
        $html .= qq~
        <tr><td align="right"> &nbsp; </td><td align="left"><br /><br />
        <b>[[AUTOMATED-DATA]]</b> $MSG{includes_the_following_Json_variables}:<br><br>
        <pre style=" font-family: monospace; color: #00007D;"">
    "idAlert": "",
    "escalationNumber": "[1 or 2 or 3]",
    "dlFirstEscalation": "",
    "dlSecondEscalation": "",
    "dlThirdEscalation": "",
    "insertDate": "",
    "severity": "",
    "impact": "",
    "urgency": "",
    "title": "",
    "definition": "",
    "description": ""</pre>
        </td></tr>
        </table>~;
}





return $html;

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
