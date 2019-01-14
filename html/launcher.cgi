#!/usr/bin/perl
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# This is the secondary index for Web UI of Yaomiqui 1.0
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
use FindBin qw($RealBin);
use CGI;
# use Page::Paginator;
use Tie::File;

our(%input, %VAR, %MSG, %PRM, $username, $html, $header, $footer, $module, $module_file, $theme, $dbh, $encKey);
my $VERSION = 0.1;
require 'common.pl';
%VAR = get_vars();
$encKey = getEncKey();
$username = get_session();
$theme = get_theme();
%PRM = get_permissions();

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
$module = $input{'mod'};

$header = header();
$footer = footer();

if ( $username  eq 'Guest' and $module ne 'login' ) {
	$html .= $header . $footer;
} else {
	
	unless ( $module ) {
		$module = $VAR{'init_mod'};
	}
	
	$module_file = $module . '.pl';
	
	if ( -e "$VAR{'modules_dir'}/$module_file" ) {
		$html .= $header;
		if ( $PRM{$module} ) {
			$html .= vermod();
		} else {
			$html .= qq"<br /><b>Error 401.</b> Access denied: $module => \$PRM{$module} : $PRM{$module}" . "<br />" x 30;
		}
		$html .= $footer;
	} else {
		$html .= $header;
		$html .= qq"<br /><b>Error 404.</b> The module '$module' doesn't exists." . "<br />" x 30;
		$html .= $footer;
	}
}

print "Content-Type: text/html\n\n";
print $html;

exit;



sub header {
	my $header = qq~
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<link href="themes/$theme/css/style.css" rel="stylesheet">
<link href="themes/$theme/css/stylelauncher.css" rel="stylesheet" type="text/css" />

<script type="text/javascript" src="js/miquiloniToolTip.js"></script>
<script type="text/javascript" src="js/jquery-1.10.2.min.js"></script>

</head>
<body>
	~; #http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js
}

sub footer {
	my $footer = qq~</body></html>~;
	return $footer;
}
