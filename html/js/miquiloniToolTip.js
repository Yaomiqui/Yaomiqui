/* Miquiloni Tooltip 0.1.1 (c) http://www.miquiloni.org, hugo.maza@gmail.com */
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
