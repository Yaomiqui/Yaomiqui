%MSG = loadLang('init');

my $html = qq~<!--This is the empty content for initial module-->~;

$html .= qq~

<script type="text/javascript">
	function lxcServerMgmt(){	//Define arbitrary function to run desired DHTML Window widget codes
		ajaxwin=dhtmlwindow.open("ajaxbox1", "iframe", "launcher.cgi?mod=lxcservers", "$MSG{LXC_Server_Management}", "width=1200px,height=300px,left=100px,top=100px,resize=1,scrolling=1", "recal")
		//ajaxwin.onclose=function(){
			//return window.confirm("Close LXC Servers Management Window?")	 //Run custom code when window is about to be closed
		//}
	}
	
	function myAccountMgmt(){
		ajaxwin=dhtmlwindow.open("ajaxbox2", "iframe", "launcher.cgi?mod=myaccount", "$MSG{My_Account_Management}", "width=360px,height=220px,left=500px,top=100px,resize=1,scrolling=1", "recal")
	}
	
	function accountsMgmt(){
		ajaxwin=dhtmlwindow.open("ajaxbox3", "iframe", "launcher.cgi?mod=accounts", "$MSG{Managing_User_Accounts}", "width=900px,height=400px,left=300px,top=100px,resize=1,scrolling=1", "recal")
	}
	
	function provisioning(){
		ajaxwin=dhtmlwindow.open("ajaxbox4", "iframe", "launcher.cgi?mod=provisioning", "$MSG{Provisioning}", "width=900px,height=400px,left=300px,top=100px,resize=1,scrolling=1", "recal")
	}
	
	function overview(){
		ajaxwin=dhtmlwindow.open("ajaxbox5", "iframe", "launcher.cgi?mod=overview", "$MSG{Overview}", "width=900px,height=400px,left=300px,top=100px,resize=1,scrolling=1", "recal")
	}
	
	function settings(){
		ajaxwin=dhtmlwindow.open("ajaxbox6", "iframe", "launcher.cgi?mod=settings", "$MSG{Settings_for_some_things}", "width=600px,height=400px,left=300px,top=50px,resize=1,scrolling=1", "recal")
	}
	
	
	function documentation(){
		ajaxwin=dhtmlwindow.open("ajaxboxDocs", "iframe", "launcher.cgi?mod=docs&tab=0", "$MSG{Miquiloni_Documents}", "width=600px,height=400px,left=400px,top=50px,resize=1,scrolling=1", "recal")
	}
	function help(){
		ajaxwin=dhtmlwindow.open("ajaxboxDocs", "iframe", "launcher.cgi?mod=docs&tab=1", "$MSG{Miquiloni_Documents}", "width=600px,height=400px,left=400px,top=50px,resize=1,scrolling=1", "recal")
	}
	function about(){
		ajaxwin=dhtmlwindow.open("ajaxboxDocs", "iframe", "launcher.cgi?mod=docs&tab=2", "$MSG{Miquiloni_Documents}", "width=600px,height=400px,left=400px,top=50px,resize=1,scrolling=1", "recal")
	}
	function legal(){
		ajaxwin=dhtmlwindow.open("ajaxboxDocs", "iframe", "launcher.cgi?mod=docs&tab=3", "$MSG{Miquiloni_Documents}", "width=600px,height=400px,left=400px,top=50px,resize=1,scrolling=1", "recal")
	}
	
	
	
</script>

~ if $theme eq 'desktop7';

print "Location: index.cgi?mod=overview\n\n" if $theme ne 'desktop7';

return $html;
1;

