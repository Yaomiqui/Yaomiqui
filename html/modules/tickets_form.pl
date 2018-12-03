%MSG = loadLang('ticket_form');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Ticket_Form_for_manual_capture}</div>~ unless $input{'shtl'};


if ( $input{submod} eq 'insertTicket' ) {
	open(TEMPLATE, ">../ticketForm.json");
	print TEMPLATE $input{formTicket};
	close TEMPLATE;
}


open(TEMPLATE, "<../ticketForm.json");
my $jsonTemplate = join('', <TEMPLATE>);
close TEMPLATE;

$html .= qq~
$MSG{All_changes_you_make_here}<br><br>

<script>
	function openModal(modalId) {
		document.getElementById(modalId).style.display = "block";
	}
	function closeModal(modalId) {
		document.getElementById(modalId).style.display = "none";
	}
	function openModalRedirect(modalId, htmlink, targetLink) {
		document.getElementById(modalId).style.display = "block";
		window.open(htmlink, targetLink);
	}
	function openModalCloseAndRedirect(modalIdToOpen, modalIdToClose, htmlink, targetLink) {
		document.getElementById(modalIdToClose).style.display = "none";
		document.getElementById(modalIdToOpen).style.display = "block";
		window.open(htmlink, targetLink);
	}
</script>

<form method="post" action="index.cgi">
<input type="hidden" name="mod" value="tickets_form">
<input type="hidden" name="submod" value="insertTicket">
<div><textarea name="formTicket" style="width: 70%; height: 400px; color: #B8DCCD; background-color: #15283F; font-size: 12px; border-color: #7F7F7F">$jsonTemplate</textarea></div><br><br>

<div id="myModalRedirectSave" class="confirm"><div class="confirm-content">
	$MSG{Alert}<hr class="confirm-header">
	$MSG{Sending_form}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
</div></div>
<button class="blueLightButton" onClick="return openModal('myModalRedirectSave');">$MSG{Insert_New_Ticket}</button>

</form>
~;



if ( $input{submod} eq 'insertTicket' ) {
	
	my $comm = `../loader.pl`;
	use JSON;
	my $json = eval { decode_json $comm };
	$comm = JSON->new->pretty->encode($json);
	
	# $html .= qq~<br><br><br>$MSG{Execution_Results}:<br><br><pre style="width: 70%; min-height: 50px; color: #4D4D4D; background-color: #ECECEC; font-size: 12px; padding: 2px; border: 1px solid #D4D4D4">~ . $comm . qq~</pre><br><br><br><br><br>~;
	$html .= qq~<br><br><br>$MSG{Execution_Results}:<br><br><pre style="width: 70%; color: #4D4D4D; background-color: #ECECEC; font-size: 12px; padding: 2px; border: 1px solid #D4D4D4">~ . $comm . qq~</pre><br><br><br><br><br>~;
	
	# print "Location: index.cgi?mod=tickets_form\n\n";
}


return $html;
1;
