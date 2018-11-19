%MSG = loadLang('overview');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Overview}</div>~ unless $input{'shtl'};

# $html .= qq~
# <div style="width: auto; height: 89%; background-color: ##efefef;">

# </div>
# ~;

# <script type="text/javascript">
	# function loadPageContents() {
		# var AJAX = getAJAX();
		# AJAX.open('GET','./',true);
		# AJAX.onreadystatechange = function() {
			# if(this.readyState==4 && this.responseText) {
				# document.getElementById('ticketList').innerHTML = this.responseText;
				# loadingPage = setTimeout('loadPageContents()',1000);
			# }
		# }
		# AJAX.send(null);
	# }
# </script>


$html .= qq~
<script type="text/javascript">
	setInterval(abc, 1000);
	
	function abc() {
		var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
				document.getElementById("ticketList").innerHTML = this.responseText;
			}
		};
		xhttp.open("GET", "launcher.cgi?mod=tickets&shtl=1", true);
		xhttp.send();
	}
</script>

<table cellpadding="0" cellspacing="2" border="0" width="100%" style="min-height: 400px; height: calc(100% - 62px);">
	<tr>
		<td width="65%" valign="top" style="height: calc(100% - 62px);">
			<form method="post" action="launcher.cgi" target="ticket">
			<input type="hidden" name="shtl" value="1">
			<input type="hidden" name="mod" value="tickets">
			<input type="hidden" name="submod" value="findTicket">
			$MSG{Search_Ticket}: &nbsp; <input type="text" name="ftt" maxlength="100" placeholder="$MSG{Type_a_ticket_Number}" required> &nbsp; 
			<input class="blueLightButton" type="submit" value="$MSG{Search}">
			</form>
			<br>
			
			<iframe name="ticket" id="ticketList" scrolling="auto" src="launcher.cgi?mod=tickets&shtl=1" frameborder="0" width="100%" height="100%"></iframe>
		</td>
		<td width="35%" valign="top" style="height: calc(100% - 62px);">
			<iframe name="logs" scrolling="auto" frameborder="0" width="100%" style="height: calc(100% + 40px); background-color: #E0E0E0;"></iframe>
		</td>
	</tr>
</table>
~;
# src="launcher.cgi?mod=logs&shtl=1"
return $html;
1;
