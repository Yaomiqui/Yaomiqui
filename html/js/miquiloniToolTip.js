//######################################################################
// Miquiloni Tooltip 0.1.1
// http://www.miquiloni.org
// 
// This tooltip is not being used by Yaomiqui but we want to do it
// in the future versions
// 
// Copyright (C) 2018 Hugo Maza Moreno
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//######################################################################
window.onload = init;
function init() {
	// if (window.Event) {
		// document.captureEvents(Event.MOUSEMOVE);
	// }
	document.onmousemove = showCoords;
}

var CurX;
var CurY;
var enabletip = false;
var divToShow;

function showCoords(event) {
	divToShow = document.getElementById("miquiloniToolTip");
	// document.body.appendChild(divToShow);
	if (enabletip){
		
		CurX = event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
		CurY = event.clientY + document.body.scrollTop + document.documentElement.scrollTop;
		divToShow.style.visibility = 'visible';
		divToShow.style.opacity = '.97';
		divToShow.style.transition = 'opacity .5s';
		divToShow.style.left = CurX + "px";
		divToShow.style.top = CurY+20 + "px";
	}
}

function showToolTip (thetext, thebordercolor, thebackground, thewidth) {
	if (typeof thebordercolor != "undefined"  && thebordercolor != "") {
		divToShow.style.border= "4px solid " + thebordercolor;
	}
	if (typeof thebackground != "undefined" && thebackground != "") {
		divToShow.style.backgroundColor = thebackground;
	}
	if (typeof thewidth != "undefined" && thewidth != "") {
		divToShow.style.width = thewidth;
	}
	divToShow.innerHTML=thetext;
	enabletip=true;
	return false
}

function hideToolTip () {
	divToShow.style.visibility = 'hidden';
	divToShow.style.opacity = '0';
	divToShow.style.transition = 'opacity .5s';
	divToShow.style.backgroundColor = "#FEFEFE";
	divToShow.style.border= "4px solid #8B0000";
	divToShow.style.width= "200px";
	enabletip=false
}
