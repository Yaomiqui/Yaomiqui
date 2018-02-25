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


####	THIS IS A TEMPLATE
####	HERE YOU CAN PUT HERE THE CODE FOR CONNECTOR TO YOUR SERVER OR TICKET SYSTEM MANAGEMENT


# system(qq~echo '$json' | curl -H "Content-Type: application/json" -X POST -d \@$RealBin/ticketForm.json "http://127.0.0.1:2050"~);
system(qq~curl -H "Content-Type: application/json" -X POST -d \@$RealBin/ticketForm.json "http://127.0.0.1:2050"~);

exit;





