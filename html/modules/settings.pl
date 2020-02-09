%MSG = loadLang('settings');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Settings_for_some_things}</div>~ unless $input{'shtl'};

# unless ( $input{submod} ) {
	
# }

return $html;
1;

