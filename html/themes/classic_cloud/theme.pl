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
	
	my ($acharts, $areports, $aoverview, $adesign, $amigrate, $acryptPasswd, $aticketsForm, $amyAccount, $aaccounts, $aaccountsNew, $aaconfigVars, $aconfigEnvVars, $aabout, $alicense);
	my ($prilink, $seclink, $trdlink);
    if ( $input{mod} eq 'charts' ) {
        $acharts = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{Dashboard};
        if ( $input{submod} eq 'viewTable' ) {
            $prilink = qq~<a href="index.cgi?mod=charts" style="color: #FFF; text-decoration: underline;">$MSG{Dashboard}</a>~;
            $seclink = '&nbsp; <b>></b> &nbsp;' . 'Table View'
        }
    }
    if ( $input{mod} eq 'reports' ) {
        $areports = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{Saving_Reports};
        if ( $input{submod} eq 'edit_config' ) {
            $prilink = qq~<a href="index.cgi?mod=reports" style="color: #FFF; text-decoration: underline;">$MSG{Saving_Reports}</a>~;
            $seclink = '&nbsp; <b>></b> &nbsp;' . 'Config'
        }
    }
    if ( $input{mod} eq 'overview' ) {
        $aoverview = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{Overview};
    }
    if ( $input{mod} eq 'logs' ) {
        $aoverview = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{Overview};
        if ( $input{submod} eq 'showLogs' ) {
            if ( $input{timeLine} eq 'true' ) {
                $prilink = qq~<a href="index.cgi?mod=overview" style="color: #FFF; text-decoration: underline;">$MSG{Overview}</a>~;
                $seclink = '&nbsp; <b>></b> &nbsp;' . qq~<a href="index.cgi?mod=logs&submod=showLogs&numberTicket=$input{numberTicket}" style="color: #FFF; text-decoration: underline;">$MSG{Standard_View}</a>~ . '&nbsp; <b>></b> &nbsp;' . $MSG{Time_Line};
            }
            else {
                $prilink = qq~<a href="index.cgi?mod=overview" style="color: #FFF; text-decoration: underline;">$MSG{Overview}</a>~;
                $seclink =  '&nbsp; <b>></b> &nbsp;' . $MSG{Standard_View} . '&nbsp; <b>></b> &nbsp;' . qq~<a href="index.cgi?mod=logs&submod=showLogs&timeLine=true&numberTicket=$input{numberTicket}" style="color: #FFF; text-decoration: underline;">$MSG{Time_Line}</a>~;
            }
            
        }
    }
    if ( $input{mod} eq 'design' ) {
        $adesign = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{AutoBot_Design};
        if ( $input{submod} eq 'edit_autobot' ) {
            $prilink = qq~<a href="index.cgi?mod=design" style="color: #FFF; text-decoration: underline;">$MSG{AutoBot_Design}</a>~;
            $seclink = '&nbsp; <b>></b> &nbsp;' . 'Editing Auto-Bot'
        }
        elsif ( $input{submod} eq 'new_autoBot_from_xml' ) {
            $adesign = '';
            $amigrate = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = qq~<a href="index.cgi?mod=design" style="color: #FFF; text-decoration: underline;">$MSG{AutoBot_Design}</a>~;
            $seclink = '&nbsp; <b>></b> &nbsp;' . $MSG{Autobot_Migration}
        }
        elsif ( $input{submod} eq 'cryptPasswd' ) {
            $adesign = '';
            $acryptPasswd = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = qq~<a href="index.cgi?mod=design" style="color: #FFF; text-decoration: underline;">$MSG{AutoBot_Design}</a>~;
            $seclink = '&nbsp; <b>></b> &nbsp;' . $MSG{Encrypt_Password}
        }
    }
    if ( $input{mod} eq 'tickets_form' ) {
        $aticketsForm = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{Ticket_Form};
    }
    if ( $input{mod} eq 'my_account' ) {
        $amyAccount = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{My_Account};
    }
    if ( $input{mod} eq 'accounts' ) {
        $aaccounts = $VAR{COLOR_ACTIVE_SIDEBAR};
        $prilink = $MSG{Accounts_List};
    }
    if ( $input{mod} eq 'accounts_edit' ) {
        if ( $input{idUser} ) {
            $aaccounts = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = qq~<a href="index.cgi?mod=accounts" style="color: #FFF; text-decoration: underline;">$MSG{Accounts_List}</a>~;
            $seclink = '&nbsp; <b>></b> &nbsp;' . 'Editing'
        }
        else {
            $aaccountsNew = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = $MSG{New_User};
        }
    }
    if ( $input{mod} eq 'config' ) {
        if ( $input{submod} eq 'configEnvVars' ) {
            $aconfigEnvVars = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = $MSG{Environment_Variables};
        }
        else {
            $aaconfigVars = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = $MSG{Config_Variables};
        }
    }
    if ( $input{mod} eq 'about' ) {
        if ( $input{submod} eq 'license' ) {
            $alicense = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = $MSG{License};
        }
        else {
            $aabout = $VAR{COLOR_ACTIVE_SIDEBAR};
            $prilink = $MSG{About_Yaomiqui};
        }
    }
    ################################
	
	if ( $username ne 'Guest' ) {
		$header .= qq~
    <script>
    function w3_close() {
        document.getElementById("mySidebar").style.display = "none";
    }
    function w3_open() {
        if (document.getElementById("mySidebar").style.display == "none") {
            document.getElementById("mySidebar").style.display = "block";
            document.getElementById("main").style.marginLeft = "200px";
            document.getElementById("hamburger").src = "themes/$theme/images/hamLeft.png";
            
        } else {
            document.getElementById("mySidebar").style.display = "none";
            document.getElementById("main").style.marginLeft = "0px";
            document.getElementById("hamburger").src = "themes/$theme/images/hamRight.png";
        }
    }
    </script>
        ~;
        
        ####  SIDEBAR                        w3-animate-left
        $header .= qq~<div class="w3-sidebar w3-animate-opacity w3-bar-block w3-white w3-border-right" style="background-color: #F1F1F1; display:block; margin-top: 38px; overflow: auto; width: 200px" id="mySidebar">~;
        
        # $header .= qq~<button class="w3-bar-item w3-button w3-tiny" onclick="w3_close()"> Close </button>~;
        $header .= qq~
        <a href="index.cgi?mod=charts" class="w3-bar-item w3-button w3-small w3-border-top $acharts">$MSG{Dashboard}</a>
        <a href="index.cgi?mod=reports" class="w3-bar-item w3-button w3-small $areports">$MSG{Saving_Reports}</a>
        <a href="index.cgi?mod=overview" class="w3-bar-item w3-button w3-small w3-border-top $aoverview">$MSG{Overview}</a>~;
        
        $header .= qq~<a href="index.cgi?mod=design" class="w3-bar-item w3-button w3-small w3-border-top $adesign">$MSG{AutoBot_Design}</a>~ if $PRM{design};
        $header .= qq~<a href="index.cgi?mod=design&submod=new_autoBot_from_xml" class="w3-bar-item w3-button w3-small $amigrate">$MSG{Autobot_Migration}</a>~ if $PRM{design};
        $header .= qq~<a href="index.cgi?mod=design&submod=cryptPasswd" class="w3-bar-item w3-button w3-small $acryptPasswd">$MSG{Encrypt_Password}</a>~ if $PRM{design};
        $header .= qq~<a href="index.cgi?mod=tickets_form" class="w3-bar-item w3-button w3-small w3-border-top $aticketsForm">$MSG{Ticket_Form}</a>~ if $PRM{tickets_form};
        $header .= qq~<a href="index.cgi?mod=my_account" class="w3-bar-item w3-button w3-small w3-border-top $amyAccount">$MSG{My_Account}</a>~;
        $header .= qq~<a href="index.cgi?mod=accounts" class="w3-bar-item w3-button w3-small $aaccounts">$MSG{Accounts_List}</a>~ if $PRM{accounts};
        $header .= qq~<a href="index.cgi?mod=accounts_edit" class="w3-bar-item w3-button w3-small $aaccountsNew">$MSG{New_User}</a>~ if $PRM{accounts_edit};
        $header .= qq~<a href="index.cgi?mod=config" class="w3-bar-item w3-button w3-small w3-border-top $aaconfigVars">$MSG{Config_Variables}</a>~ if $PRM{config};
        $header .= qq~<a href="index.cgi?mod=config&submod=configEnvVars" class="w3-bar-item w3-button w3-small $aconfigEnvVars">$MSG{Environment_Variables}</a>~ if $PRM{config};
        
        $header .= qq~<a href="index.cgi?mod=about" class="w3-bar-item w3-button w3-small w3-border-top $aabout">$MSG{About_Yaomiqui}</a>
        <a href="index.cgi?mod=about&submod=license" class="w3-bar-item w3-button w3-small $alicense">$MSG{License}</a>
        
        <div style="opacity:0.3; margin-top: 40px;" class="w3-small" align="center">
        <img src="images/logo.png" alt="Snow" style="width:70%; display: block; margin-left: auto; margin-right: auto;">
            <br><br>Powered by:<br>
            <img src="themes/$theme/images/YaomiquiLogoTransparent.png">
            <br/>YAOMIQUI
            <br>Automation Platform
        </div>
        <br><br><br>
    </div>
		
        <div class="w3-top">
            <div class="w3-bar w3-left-align" style="background-color: #242C3F; padding-right: 50px;">
                <a href="#" class="w3-bar-item w3-button w3-medium" style="margin-right: 40px; margin-left: 50px;" onClick="w3_open()"><img id="hamburger" src="themes/$theme/images/hamLeft.png" style="height: 22px; border: 0px"></a>
                <div class="w3-display-left w3-text-white" style="margin-left: 120px;">$prilink $seclink</div>
                <a href="index.cgi?mod=logout" onclick="return confirm('$MSG{Are_you_sure_you_want_to_log_off} ?')" class="w3-bar-item w3-button w3-right w3-medium"><img src="themes/$theme/images/logout64.png" style="height: 22px; border: 0px;"></a>
                <div class="w3-display-right w3-text-white" style="margin-right: 120px;">[$username on $VAR{ENVIRONMENT}]</div>
            </div>
        </div>
        ~;
    
        ####    MAIN CONTAINER
        # $header .= qq~<div class="w3-container" onclick="w3_close()" style="height: 95%;">~;
        $header .= qq~<div class="w3-container" id="main" style="height: calc(100% - 32px); margin-left: 200px;">~;
    
	}
	
	return $header;
}

sub footer {
	my $footer;
	
	if ( $username ne 'Guest' ) {
		$footer .= qq~
		</div>
		</div>
</body>
</html>
~;
	}
	return $footer;
}

1;
