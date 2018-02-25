#!/usr/bin/perl
########################################################################
# Yaomiqui is a Web UI for AUTOMATION
# Copyright (C) 2017  Hugo Maza M.
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
use strict;
use FindBin qw($RealBin);


my $status = `$RealBin/insertTicket status`;
$status =~ s/\n//;

if ( $status eq 'insertTicket is not running' ) {
	my $comm = system("$RealBin/insertTicket start");
	
	if ( $comm ) {
		my $recomm = system("$RealBin/insertTicket restart");
		
		if ( $recomm ) {
			my $lstnErr = "Error: I can't start insertTicket. Then, I can't process tickets. Bye";
			print $lstnErr . "\n";
			my $logLine = sysdate() . " : insertTicket : " . $lstnErr;
			`echo '$logLine' >> $$RealBin/logs/insertTicket.log`;
			exit;
		}
	}
}


exit;


