package Log::Man;
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# Loging module
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

our $VERSION = '0.1';
use strict;
use Tie::File;

sub new {
	my $class = shift;
	my ($logDir, $logFile, $user) = @_;
	
	my $self = {
		dir		=> $logDir,
		file	=> $logFile,
		user	=> $user
	};
	bless( $self, $class );
	
	return $self;
}

sub Log {
	my $self = shift;
	my $msg = shift;
	
	my $currentLogfile = $self->{dir}  . '/' . file_date() . '_' . $self->{file};
	$msg = formatted_datetime() . ' : ' . $self->{user} . ' :' . $msg;
	
	my $o = tie my @array, 'Tie::File', $currentLogfile, or die "I can't open $currentLogfile";
	push @array, $msg;
	untie @array;
	
	return $msg;
}

sub formatted_datetime {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	
	return "$year-$mon-$mday $hour:$min:$sec";
}

sub file_date {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	
	return "$year$mon$mday";
}


1;
