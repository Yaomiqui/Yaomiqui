#!/usr/bin/perl
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# This is the GENERIC ticket loader for Yaomiqui TicketForm
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
use strict;
use FindBin qw($RealBin);
use lib $RealBin;

####	THIS IS A TEMPLATE
####	HERE YOU CAN PUT HERE THE CODE FOR CONNECTOR TO YOUR SERVER OR TICKET SYSTEM MANAGEMENT

my $results = `curl -k -H "Content-Type: application/json" -X PUT -d \@$RealBin/ticketForm.json --url "https://127.0.0.1/generic-api.cgi/insertTicket/"`;

print $results;

# In the same way, you can use the REST API for insert tickets:
# (You don't need user and password when uses localhost)
# system(qq~curl -k -H "Content-Type: application/json" -X PUT -d \@$RealBin/ticketForm.json --url "https://localhost/generic-api.cgi/insertTicket/"~);

# Or sending data directly instead reading the file:
# system(qq~curl -k -H "Content-Type: application/json" -X PUT -d '{"ticket":{"number":"INC000001","sys_id":"abcdefghij1234567890","subject":"MY SUBJECT FOR TEST","state":"new","type":"INCIDENT"},"data":{"task":"demo task"}}' --url "https://localhost/generic-api.cgi/insertTicket/"~);


exit;





