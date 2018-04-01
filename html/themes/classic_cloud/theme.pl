sub header {
	my $header;
	
	unless ( $shtl ) {
		$header .= qq~
		<link href="css/stylelauncher.css" rel="stylesheet" type="text/css" />
		
		<script type="text/javascript" src="js/miquiloniToolTip.js"></script>
		<script type="text/javascript" src="js/jquery-1.10.2.min.js"></script>
		
	</head>
<body>
	~;
	} else {
		$header .= qq~
	</head>
<body>
	~;
	}
	
	my ($ahome, $aoverview, $adesign, $aaccounts, $asettings, $atktform, $aabout, $acharts, $areports);
	unless ( $input{mod} ) { $ahome = 'active' }
	if ( $input{mod} eq 'overview' ) { $aoverview = 'active' }
	if ( $input{mod} eq 'design' ) { $adesign = 'active' }
	elsif ( $input{mod} eq 'accounts' ) { $aaccounts = 'active' }
	elsif ( $input{mod} eq 'settings' ) { $asettings = 'active' }
	elsif ( $input{mod} eq 'tickets_form' ) { $atktform = 'active' }
	elsif ( $input{mod} eq 'about' ) { $aabout = 'active' }
	elsif ( $input{mod} eq 'charts' ) { $acharts = 'active' }
	elsif ( $input{mod} eq 'reports' ) { $areports = 'active' }
	
	if ( $username ne 'Guest' ) {
		$header .= qq~
		<ul class="topnavbar">
			<li class="topnavbar" style="margin-left: 40px"><img src="themes/$theme/images/red-home.png" style="height: 18px; padding-top: 8px" align="left"><a href="index.cgi" class="$aoverview">$MSG{Home}</a></li>
			~;
			
			$header .= qq~<li class="topnavbar"><img src="themes/$theme/images/AutoBot32px.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=design" class="$adesign">$MSG{AutoBot_Design}</a></li>~ if $PRM{design};
			$header .= qq~<li class="topnavbar"><img src="themes/$theme/images/ticket-32x32.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=tickets_form" class="$atktform">$MSG{Ticket_Form}</a></li>~ if $PRM{tickets_form};
			$header .= qq~<li class="topnavbar"><img src="themes/$theme/images/pie32x24.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=charts" class="$acharts">$MSG{Charts}</a></li>~ if $PRM{charts};
			$header .= qq~<li class="topnavbar"><img src="themes/$theme/images/bars-32x32.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=reports" class="$areports">$MSG{Reports}</a></li>~ if $PRM{reports};
			$header .= qq~<li class="topnavbar"><img src="themes/$theme/images/system-users-32x32.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=accounts" class="$aaccounts">$MSG{Accounts}</a></li>~ if $PRM{accounts};
			
			$header .= qq~<li class="topnavbar"><img src="themes/$theme/images/user.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=settings" class="$asettings">$MSG{My_Account} [$username]</a></li>
			<li class="topnavbar"><img src="themes/$theme/images/help-yellow-32x32.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=about" class="$aabout">$MSG{About}</a></li>
			<li class="topnavbar" style="float:right"><a href="index.cgi?mod=logout" onclick="return confirm('$MSG{Are_you_sure_you_want_to_log_off} ?')">$MSG{Log_off}</a></li>
		</ul>
		
		<div class="content">
		~;
	}
	
	return $header;
}

sub footer {
	my $footer;
	
	if ( $username ne 'Guest' ) {
		$footer .= qq~
		</div>
</body>
</html>
~;
	}
	return $footer;
}

1;
