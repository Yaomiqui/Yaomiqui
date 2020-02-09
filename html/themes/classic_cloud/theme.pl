########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# Classic Cloud theme
# 
# Yaomiqui and its logo are registered trademark by Hugo Maza Moreno
# Copyright (C) 2019
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################
sub header {
	my $header;
	
	unless ( $shtl ) {
		$header .= qq~
	<link href="themes/$theme/css/stylelauncher.css" rel="stylesheet" type="text/css" />
	<script type="text/javascript">if (top != self) top.location.href = location.href;</script>
	<script type="text/javascript" src="js/miquiloniToolTip.js"></script>
	<script type="text/javascript" src="js/jquery-1.10.2.min.js"></script>
	<script type="text/javascript" src="js/sorTable.js"></script>
	</head>
<body>
	~;
	} else {
		$header .= qq~
	</head>
<body>
	~;
	}
	
	my ($ahome, $aoverview, $adesign, $aaccounts, $asettings, $atktform, $aabout, $acharts, $areports, $aconfig);
	unless ( $input{mod} ) { $ahome = 'active' }
	if ( $input{mod} eq 'overview' ) { $aoverview = 'active' }
	if ( $input{mod} eq 'design' ) { $adesign = 'active' }
	elsif ( $input{mod} =~ /^accounts$|^accounts_edit$|^my_account$/ ) { $aaccounts = 'active' }
	elsif ( $input{mod} eq 'settings' ) { $asettings = 'active' }
	elsif ( $input{mod} eq 'tickets_form' ) { $atktform = 'active' }
	elsif ( $input{mod} eq 'about' ) { $aabout = 'active' }
	elsif ( $input{mod} =~ /^charts|reports$/ ) { $acharts = 'active' }
	elsif ( $input{mod} eq 'config' ) { $aconfig = 'active' }
	# elsif ( $input{mod} eq 'charts' ) { $acharts = 'active' }
	
	if ( $username ne 'Guest' ) {
		$header .= qq~
		<ul class="topnavbar">
			<li class="topnavbar" style="margin-left: 20px"><a href="index.cgi" class="$acharts">$MSG{Home}</a></li>
			~;
			
            $header .= qq~<li class="topnavbar"><a href="index.cgi?mod=overview" class="$aoverview">$MSG{Overview}</a></li>~ if $PRM{overview};
			$header .= qq~<li class="topnavbar"><a href="index.cgi?mod=design" class="$adesign">$MSG{AutoBot_Design}</a></li>~ if $PRM{design};
			$header .= qq~<li class="topnavbar"><a href="index.cgi?mod=tickets_form" class="$atktform">$MSG{Ticket_Form}</a></li>~ if $PRM{tickets_form};
			# $header .= qq~<li class="topnavbar"><a href="index.cgi?mod=charts" class="$acharts">$MSG{Charts}</a></li>~ if $PRM{charts};
			# $header .= qq~<li class="topnavbar"><a href="index.cgi?mod=reports" class="$areports">$MSG{Reports}</a></li>~ if $PRM{reports};
			$header .= qq~<li class="topnavbar"><a href="index.cgi?mod=my_account" class="$aaccounts">$MSG{Accounts}</a></li>~;
			$header .= qq~<li class="topnavbar"><a href="index.cgi?mod=config" class="$aconfig">Config</a></li>~ if $PRM{config};
			# $header .= qq~<li class="topnavbar"><a href="index.cgi?mod=settings" class="$asettings">$MSG{My_Account} [$username]</a></li>~};
			
			$header .= qq~
			<li class="topnavbar"><a href="index.cgi?mod=about" class="$aabout">$MSG{About}</a></li>
			<li class="topnavbar" style="float:right"><font color="#FFFFCC">[$username on $VAR{ENVIRONMENT}]</font> <a href="index.cgi?mod=logout" onclick="return confirm('$MSG{Are_you_sure_you_want_to_log_off} ?')">$MSG{Log_off}</a></li>
		</ul>
		
		<ul class="leftnavbar">
		~;
		
		my ($abotlist, $crnewabot, $timeline, $reports, $charts, $myaccount, $accounts, $accounts_edit, $about, $cryptPasswd);
		unless ( $input{submod} ) { $list = 'active' }
		
		if ( $input{mod} eq 'overview' ) {
			$header .= qq~
			<li class="leftnavbar"><a href="index.cgi?mod=overview&submod=" class="$list">$MSG{Overview}</a></li>~;
		}
		if ( $input{mod} eq 'design' ) {
			$crnewabot = 'active' if $input{submod} eq 'new_autoBot_from_xml';
			$cryPassabot = 'active' if $input{submod} eq 'cryptPasswd';
			$header .= qq~
			<li class="leftnavbar"><a href="index.cgi?mod=design" class="$list">$MSG{Autobots_List}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=design&submod=new_autoBot_from_xml" class="$crnewabot">$MSG{Autobot_Migration}</a></li>~;
			$header .= qq~<li class="leftnavbar"><a href="index.cgi?mod=design&submod=cryptPasswd" class="$cryPassabot">$MSG{Encrypt_Password}</a></li>~;
		}
		if ( $input{mod} eq 'tickets_form' ) {
			$header .= qq~
			<li class="leftnavbar"><a href="index.cgi?mod=tickets_form" class="$list">$MSG{Ticket_Form}</a></li>~;
		}
		if ( $input{mod} eq 'logs' ) {
			unless ( $input{timeLine} ) { $list = 'active' }
			if ( $input{timeLine} eq 'true' ) { $timeline = 'active' }
			$header .= qq~
			<li class="leftnavbar"><a href="index.cgi?mod=logs&submod=showLogs&numberTicket=$input{numberTicket}&timeLine=" class="$list">$MSG{Standard_View}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=logs&submod=showLogs&numberTicket=$input{numberTicket}&timeLine=true" class="$timeline">$MSG{Time_Line}</a></li>~;
		}
		if ( $input{mod} =~ /^charts|reports$/ ) {
			if ( $input{mod} eq 'charts' ) { $charts = 'active' }
			if ( $input{mod} eq 'reports' ) { $reports = 'active' }
			$header .= qq~<li class="leftnavbar"><a href="index.cgi?mod=charts" class="$charts">$MSG{Charts}</a></li>~ if $PRM{charts};
			$header .= qq~<li class="leftnavbar"><a href="index.cgi?mod=reports" class="$reports">$MSG{Saving_Reports}</a></li>~ if $PRM{reports};
		}
		if ( $input{mod} =~ /^accounts$|^accounts_edit$|^my_account$/ ) {
			if ( $input{mod} eq 'my_account' ) { $myaccount = 'active' }
			if ( $input{mod} eq 'accounts' ) { $accounts = 'active' }
			if ( $input{mod} eq 'accounts_edit' ) { $accounts_edit = 'active' unless $input{idUser} }
			$header .= qq~<li class="leftnavbar"><a href="index.cgi?mod=my_account" class="$myaccount">$MSG{My_Account}</a></li>~;
            $header .= qq~<li class="leftnavbar"><a href="index.cgi?mod=accounts" class="$accounts">$MSG{Accounts_List}</a></li>~ if $PRM{accounts};
			$header .= qq~<li class="leftnavbar"><a href="index.cgi?mod=accounts_edit" class="$accounts_edit">$MSG{New_User}</a></li>~ if $PRM{accounts_edit};
            
		}
		if ( $input{mod} eq 'about' ) {
			if ( $input{submod} eq 'license' ) { $about = 'active' }
			$header .= qq~
			<li class="leftnavbar"><a href="index.cgi?mod=about" class="$list">$MSG{About_Yaomiqui}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=about&submod=license" class="$about">$MSG{License}</a></li>~;
		}
		if ( $input{mod} eq 'config' ) {
			$configEnvVars = 'active' if $input{submod} eq 'configEnvVars';
			$header .= qq~
			<li class="leftnavbar"><a href="index.cgi?mod=config" class="$list">$MSG{Config_Variables}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=config&submod=configEnvVars" class="$configEnvVars">$MSG{Environment_Variables}</a></li>~;
		}
		
		$header .= qq~
		<li class="leftnavbar" style="opacity: 0.40; filter: alpha(opacity=40)">
		<p align="center" style="font-size: 110%; font-weight: bold; color: #000;">
		<img src="images/logo.png" style="padding-top:80px; width: 150px">
		<br><br><br><br>
		</li>
		<li class="leftnavbar" style="opacity: 0.25; filter: alpha(opacity=25)">
		<p align="center" style="font-size: 110%; font-weight: bold; color: #000;">
		Powered by:<br>
		<img src="themes/$theme/images/YaomiquiLogoTransparent.png" style="padding-top:10px;"><br/>YAOMIQUI</p>
		<p align="center" style="font-size: 100%; color: #000;">Automation Platform</p>
		</li>
		~;
		$header .= qq~
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
