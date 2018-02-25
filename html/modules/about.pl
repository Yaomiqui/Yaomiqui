%MSG = loadLang('about');

my $html;
$html .= qq~<div class="contentTitle">$MSG{About_Yaomiqui}</div>~ unless $input{'shtl'};

$html .= qq~
<div style="padding: 30px 30px 30px 50px; background-color: #FFFFFF">
<a href="https://yaomiqui.org" target="_blank"><img src="images/logo64x80.jpg" border="0"/></a>
<br/>
<font style="font-size: 180%">Yaomiqui</font>
<br/>
Automation Tool for repetitive tasks
<br/>
$MSG{Version}: $VAR{Version}
<br/>
<br/>
<br/>
<br/>
$MSG{Developed_by} Hugo Maza Moreno
<br/><br/>
$MSG{See} <a href="https://github.com/HugoMaza" target="_blank">Hugo Maza</a> $MSG{on_GitHub}
<br/><br/>
$MSG{See} <a href="https://github.com/Yaomiqui" target="_blank">Yaomiqui on</a> $MSG{on_GitHub}
<br/><br/>
<font style="font-size: 140%">$MSG{See_documentation_for} <a href="https://yaomiqui.org" target="_blank">Yaomiqui</a></font>
<br/><br/>
<br/><br/>
<a href="http://www.gnu.org/licenses/gpl.html" target="_blank">GPL v3 License</a>
<br/><br/>
<pre>
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <a href="http://www.gnu.org/licenses/" target="_blank">http://www.gnu.org/licenses/</a>.
</pre>
</div>
~;



return $html;
1;
