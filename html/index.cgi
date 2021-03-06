#!/usr/bin/perl
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# This is the main index for Web UI of Yaomiqui 2.0
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
use CGI::Carp qw(fatalsToBrowser);
use strict;
use CGI;
use Tie::File;
use FindBin qw($RealBin);
use lib $RealBin;
use Log::Man;

our(%input, %VAR, %MSG, %PRM, $username, $html, $header, $footer, $module, $module_file, $theme, $dbh, $encKey);
require 'common.pl';
%VAR = get_vars();
$VAR{Version} = '2.4-Stable + Alerts-Mgmt-Beta';
$encKey = getEncKey();
$username = get_session();
$theme = get_theme();
%PRM = get_permissions();
%MSG = loadLang('index');

my $consulta = new CGI;

if ( $ENV{HTTPS} ne 'on' ) {
	print "Content-Type: text/html\n\n";
	print qq~Error: HTTPS is not being used~;
	exit;
}

my @pares = $consulta->param;
foreach my $par ( @pares ){
	$input{"$par"} = $consulta->param("$par");
}

$input{'mod'} = delMalCode($input{'mod'});
$input{'shtl'} = delMalCode($input{'shtl'});
$input{'submod'} = delMalCode($input{'submod'});

$module = $input{'mod'};

require "$VAR{themes_path}/$theme/theme.pl";
$header = header();
$footer = footer();
$header = common_header() . $header;

if ( $username  eq 'Guest' and $module ne 'login' ) {
	$html .= login();
} else {
	
	unless ( $module ) {
		$module = $VAR{'init_mod'};
	}
	
	$module_file = $module . '.pl';
	
	$html .= $header unless $input{'shtl'};
	if ( -e "$VAR{'modules_dir'}/$module_file" ) {
		# $html .= vermod();
		if ( $PRM{$module} ) {
			$html .= vermod();
		} else {
			$html .= qq"<br /><b>Error 401.</b> Access denied: $module => \$PRM{$module} : $PRM{$module}" . "<br />" x 30;
		}
	} else {
		$html .= qq"<br /><b>Error 404.</b> That module doesn't exist: $module" . "<br />" x 30;
	}
	$html .= $footer unless $input{'shtl'};
}

print "X-FRAME-OPTIONS: DENY\n";
print "x-content-type-options: nosniff\n";
print "X-XSS-Protection: 1; mode=block\n";
print "Cache-Control: no-cache\n";
print "Pragma: no-cache\n";
print "Content-Type: text/html\n\n";
print $html;

exit;

sub get_header_footer {
	require "$VAR{themes_path}/$theme/theme.pl";
	my $header = header();
	my $footer = footer();
	
	return ($header, $footer);
}

sub common_header {
	my $header = qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>YAOMIQUI :: Automation Platform for Business Repetitive Tasks</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta name="keywords" content="automation,tasks,repetitive,rpa" />
	<meta name="description" content="Automation for repetitive task" />
	<link rel="icon" type="image/png" href="images/favicon.ico" />
	
	<script type="text/javascript" src="js/xonomy.js"></script>
	<script type="text/javascript" src="js/spec.js"></script>
	<script type="text/javascript" src="js/miquiloniToolTip.js"></script>
	<link rel="stylesheet" type="text/css" href="css/xonomy.css" />
    
    <meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" type="text/css" href="css/w3.css" />
    <link rel="stylesheet" type="text/css" href="css/v-resizable.css" />
    <link rel="stylesheet" type="text/css" href="css/h-resizable.css" />
    
	<link href="themes/$theme/css/style.css" rel="stylesheet">
	~;
    
    if ( $input{mod} =~ /^charts$|^reports$/ ) {
        $header .= qq~
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="ie=edge" />
    
    <link href="js/charts/styles.css" rel="stylesheet">
    
    <!--
    <script>
      window.Promise ||
        document.write(
          '<script src="charts/polyfill.min.js"><\/script>'
        )
      window.Promise ||
        document.write(
          '<script src="charts/classList.min.js"><\/script>'
        )
      window.Promise ||
        document.write(
          '<script src="charts/findIndex.js"><\/script>'
        )
    </script>
    -->

    <script type="text/javascript" src="js/charts/apexcharts.min.js"></script>
        ~;
    }
	
	return  $header;
}
