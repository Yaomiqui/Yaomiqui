//######################################################################
// Yaomiqui is a Web UI for Automation
// The Yaomiqui version for Xonomy library
// 
// Written in freestyle Perl-CGI + Apache + MySQL + Javascript + CSS
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
var specifications={
	// onchange: function(){
		// console.log("I been changed now!")
	// },
	// validate: function(obj){
		// console.log("I be validatin' now!")
	// },
	elements: {
		"AUTO":{
			// backgroundColour: '#EBEBEB',
			menu: [
				{
					caption: "Append a <IF>",
					action: Xonomy.newElementChild,
					// actionParameter: "<IF/>"
					actionParameter: "<IF><VAR name='' compare=''><DO/></VAR></IF>"
				},
				{
					caption: "Append a <DO>",
					action: Xonomy.newElementChild,
					actionParameter: "<DO/>"
				},
			]
		},
		"ON": {
			backgroundColour: '#CEEBCE',
			menu: [
				{
					caption: "Append a <VAR>",
					action: Xonomy.newElementChild,
					actionParameter: "<VAR name='' compare=''/>"
				}
			],
			//canDropTo: [],
		},
		"IF": {
			backgroundColour: '#F1E0C2',
			menu: [
				{
					caption: "Append a <VAR>",
					action: Xonomy.newElementChild,
					actionParameter: "<VAR name='' compare=''><DO/></VAR>"
				},
				// {
					// caption: "Append a <LOGING>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<LOGING comment=\"\"/>",
				// },
				// {
					// caption: "Append a <END>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<END value=\"Resolved\" />",
				// },
				// {
					// caption: "Append a <RETURN>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<RETURN value=\"\"/>"
				// },
				// {
					// caption: "Append a <DO>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<DO/>"
				// },
				// Deletes IF
				{
					caption: "Delete this <IF>",
					action: Xonomy.deleteElement
				},
				// {
					// caption: "New <IF> before this",
					// action: Xonomy.newElementBefore,
					// actionParameter: "<IF/>"
				// },
				// {
					// caption: "New <IF> after this",
					// action: Xonomy.newElementAfter,
					// actionParameter: "<IF/>"
				// }
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep"]
		},
		"VAR": {
			backgroundColour: '#F1F9FD',
			menu: [
				// CHILDS
				// {
					// caption: "Append a <LOGING>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<LOGING comment=\"\"/>",
				// },
				// {
					// caption: "Append a <END>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<END value=\"Resolved\" />",
				// },
				// {
					// caption: "Append a <RETURN>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<RETURN value=\"\"/>"
				// },
				// {
					// caption: "Append a <DO>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<DO/>"
				// },
				// Add Attributes
				{
					caption: "Add @name=\"\"",
					action: Xonomy.newAttribute,
					actionParameter: { name: "name", value: "" },
					hideIf: function(jsElement){ return jsElement.hasAttribute("name"); }
				},
				{
					caption: "Add @compare=\"\"",
					action: Xonomy.newAttribute,
					actionParameter: { name: "compare", value: "" },
					hideIf: function(jsElement){ return jsElement.hasAttribute("compare"); }
				},
				{
					caption: "Add @value=\"\"",
					action: Xonomy.newAttribute,
					actionParameter: { name: "value", value: "" },
					hideIf: function(jsElement){ return jsElement.hasAttribute("value"); }
				},
				// Deletes VAR
				{
					caption: "Delete this <VAR>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <VAR> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<VAR name='' compare=''><DO/></VAR>"
				},
				{
					caption: "New <VAR> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<VAR name='' compare=''><DO/></VAR>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"name": {
					asker: Xonomy.askString,
					// menu: [{
						// caption: "Delete this @name",
						// action: Xonomy.deleteAttribute
					// }]
				},
				"compare": {
					asker: Xonomy.askPicklist,
					askerParameter: [
						{value: "exists", caption: "Exists"},
						{value: "notexist", caption: "Does not Exist"},
						{value: "contains", caption: "Contains"},
						{value: "notcontain", caption: "Does not Contain"},
						{value: "startsw", caption: "Starts with"},
						{value: "notstartsw", caption: "Does not Start with"},
						{value: "endsw", caption: "Ends with"},
						{value: "notendsw", caption: "Does not End with"},
						{value: "eq", caption: "Equal to"},
						{value: "ne", caption: "Not Equal to"},
						{value: "lt", caption: "Less than"},
						{value: "gt", caption: "Greater than"},
						{value: "isempty", caption: "Is Empty"}
					],
					// menu: [{
						// caption: "Delete this @compare",
						// action: Xonomy.deleteAttribute
					// }]
				},
				"value": {
					asker: Xonomy.askString,
					menu: [{
						caption: "Delete this @value",
						action: Xonomy.deleteAttribute
					}]
				},
			}
		},
		
		"DO": {
			// CHILDS
			backgroundColour: '#DCEEDC',
			menu: [
				{
					caption: "Append a <execLinuxCommand>",
					action: Xonomy.newElementChild,
					actionParameter: "<execLinuxCommand catchVarName=\"\"><command><![CDATA[]]></command></execLinuxCommand>"
				},
				{
					caption: "Append a <execRemoteLinuxCommand>",
					action: Xonomy.newElementChild,
					actionParameter: "<execRemoteLinuxCommand catchVarName=\"\" remoteHost=\"\" remoteUser=\"\" passwd=\"\" publicKey=\"\" EncKey=\"\" EncPasswd=\"\"><command><![CDATA[]]></command></execRemoteLinuxCommand>"
				},
				{
					caption: "Append a <execRemoteWindowsCommand>",
					action: Xonomy.newElementChild,
					actionParameter: "<execRemoteWindowsCommand catchVarName=\"\" remoteHost=\"\" domain=\"\" remoteUser=\"\" passwd=\"\" useKerberos=\"yes\" EncKey=\"\" EncPasswd=\"\"><command><![CDATA[]]></command></execRemoteWindowsCommand>"
				},
				{
					caption: "Append a <SetVar>",
					action: Xonomy.newElementChild,
					actionParameter: "<SetVar name=\"\"><value><![CDATA[]]></value></SetVar>"
				},
				// {
					// caption: "Append a <SplitFile>",
					// action: Xonomy.newElementChild,
					// actionParameter: "<SplitFile arrayName=\"\" separator=\"\" inputFileName=\"\"/>"
				// },
				{
					caption: "Append a <SplitVar>",
					action: Xonomy.newElementChild,
					actionParameter: "<SplitVar arrayName=\"\" separator=\"\" inputVarName=\"\"/>"
				},
	
				{
					caption: "Append a <JSONtoVar>",
					action: Xonomy.newElementChild,
					actionParameter: "<JSONtoVar catchVarName=\"\"><JsonSource><![CDATA[]]></JsonSource></JSONtoVar>"
				},
				{
					caption: "Append a <IF>",
					action: Xonomy.newElementChild,
					actionParameter: "<IF><VAR name='' compare=''><DO/></VAR></IF>"
				},
				{
					caption: "Append a <FOREACH>",
					action: Xonomy.newElementChild,
					actionParameter: "<FOREACH element=\"i\" arrayName=\"\"><DO/></FOREACH>"
				},
				{
					caption: "Append a <FOREACH_NUMBER>",
					action: Xonomy.newElementChild,
					actionParameter: "<FOREACH_NUMBER element=\"i\" initRange=\"\" endRange=\"\"><DO/></FOREACH_NUMBER>"
				},
				{
					caption: "Append a <AUTOBOT>",
					action: Xonomy.newElementChild,
					actionParameter: "<AUTOBOT idAutoBot=\"\" catchVarName=\"\"><JsonVars><![CDATA[]]></JsonVars></AUTOBOT>"
				},
				{
					caption: "Append a <SendEMAIL>",
					action: Xonomy.newElementChild,
					actionParameter: "<SendEMAIL From=\"\" To=\"\" Subject=\"\" Type=\"text/plain\"><Body><![CDATA[]]></Body></SendEMAIL>"
				},
				{
					caption: "Append a <IntegerArray>",
					action: Xonomy.newElementChild,
					actionParameter: "<IntegerArray arrayName=\"\" initRange=\"\" endRange=\"\"/>"
				},
				{
					caption: "Append a <DecodePWDtoVar>",
					action: Xonomy.newElementChild,
					actionParameter: "<DecodePWDtoVar name=\"\" EncKey=\"\" EncPasswd=\"\"/>"
				},
				{
					caption: "Append a <Sleep>",
					action: Xonomy.newElementChild,
					actionParameter: "<Sleep seconds=\"1\"/>"
				},
				{
					caption: "Append a <RETURN>",
					action: Xonomy.newElementChild,
					actionParameter: "<RETURN value=\"\"/>"
				},
				{
					caption: "Append a <LOGING>",
					action: Xonomy.newElementChild,
					actionParameter: "<LOGING comment=\"\"/>"
				},
				{
					caption: "Append a <END>",
					action: Xonomy.newElementChild,
					actionParameter: "<END value=\"Resolved\"/>"
				},
				// {
					// caption: "New <DO> before this",
					// action: Xonomy.newElementBefore,
					// actionParameter: "<DO/>"
				// },
				// {
					// caption: "New <DO> after this",
					// action: Xonomy.newElementAfter,
					// actionParameter: "<DO/>"
				// },
				// Deletes DO
				{
					caption: "Delete this <DO>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep"]
			// attributes: {
				// "id": {
					// asker: Xonomy.askString,
					// menu: [{
						// caption: "Delete this @id",
						// action: Xonomy.deleteAttribute
					// }]
				// },
			// }
		},
		
		"execLinuxCommand": {
			backgroundColour: '#CBF0CB',
			menu: [
				// Deletes execLinuxCommand
				{
					caption: "Delete this <execLinuxCommand>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <execLinuxCommand> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<execLinuxCommand catchVarName=\"\"><command><![CDATA[]]></command></execLinuxCommand>"
				},
				{
					caption: "New <execLinuxCommand> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<execLinuxCommand catchVarName=\"\"><command><![CDATA[]]></command></execLinuxCommand>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"catchVarName": {
					asker: Xonomy.askString,
				},
				"command": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"execRemoteLinuxCommand": {
			backgroundColour: '#CBDBF0',
			menu: [
				// Deletes execRemoteLinuxCommand
				{
					caption: "Delete this <execRemoteLinuxCommand>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <execRemoteLinuxCommand> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<execRemoteLinuxCommand catchVarName=\"\" remoteHost=\"\" remoteUser=\"\" passwd=\"\" publicKey=\"\" EncKey=\"\" EncPasswd=\"\"><command><![CDATA[]]></command></execRemoteLinuxCommand>"
				},
				{
					caption: "New <execRemoteLinuxCommand> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<execRemoteLinuxCommand catchVarName=\"\" remoteHost=\"\" remoteUser=\"\" passwd=\"\" publicKey=\"\" EncKey=\"\" EncPasswd=\"\"><command><![CDATA[]]></command></execRemoteLinuxCommand>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"catchVarName": {
					asker: Xonomy.askString,
				},
				"remoteHost": {
					asker: Xonomy.askString,
				},
				"remoteUser": {
					asker: Xonomy.askString,
				},
				"passwd": {
					asker: Xonomy.askString,
				},
				"publicKey": {
					asker: Xonomy.askString,
				},
				"EncKey": {
					asker: Xonomy.askString,
				},
				"EncPasswd": {
					asker: Xonomy.askString,
				},
				"command": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"execRemoteWindowsCommand": {
			backgroundColour: '#F5E2E5',
			menu: [
				// Deletes execRemoteWindowsCommand
				{
					caption: "Delete this <execRemoteWindowsCommand>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <execRemoteWindowsCommand> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<execRemoteWindowsCommand catchVarName=\"\" remoteHost=\"\" domain=\"\" remoteUser=\"\" passwd=\"\" useKerberos=\"yes\" EncKey=\"\" EncPasswd=\"\"><command><![CDATA[]]></command></execRemoteWindowsCommand>"
				},
				{
					caption: "New <execRemoteWindowsCommand> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<execRemoteWindowsCommand catchVarName=\"\" remoteHost=\"\" domain=\"\" remoteUser=\"\" passwd=\"\" useKerberos=\"yes\" EncKey=\"\" EncPasswd=\"\"><command><![CDATA[]]></command></execRemoteWindowsCommand>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"catchVarName": {
					asker: Xonomy.askString,
				},
				"remoteHost": {
					asker: Xonomy.askString,
				},
				"remoteUser": {
					asker: Xonomy.askString,
				},
				"passwd": {
					asker: Xonomy.askString,
				},
				"EncKey": {
					asker: Xonomy.askString,
				},
				"EncPasswd": {
					asker: Xonomy.askString,
				},
				"domain": {
					asker: Xonomy.askString,
				},
				"command": {
					asker: Xonomy.askString,
				},
				"useKerberos": {
					asker: Xonomy.askPicklist,
					askerParameter: [
						{value: "yes", caption: "Yes"},
						{value: "no", caption: "No"},
					]
				},
			}
		},
		
		
		"JSONtoVar": {
			menu: [
				// Deletes JSONtoVar
				{
					caption: "Delete this <JSONtoVar>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <JSONtoVar> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<JSONtoVar catchVarName=\"\"><JsonSource><![CDATA[]]></JsonSource></JSONtoVar>"
				},
				{
					caption: "New <JSONtoVar> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<JSONtoVar catchVarName=\"\"><JsonSource><![CDATA[]]></JsonSource></JSONtoVar>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"catchVarName": {
					asker: Xonomy.askString,
				},
				"JsonSource": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"SetVar": {
			menu: [
				// Deletes SetVar
				{
					caption: "Delete this <SetVar>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <SetVar> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<SetVar name=\"\"><value><![CDATA[]]></value></SetVar>"
				},
				{
					caption: "New <SetVar> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<SetVar name=\"\"><value><![CDATA[]]></value></SetVar>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"name": {
					asker: Xonomy.askString,
				},
				"value": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"IntegerArray": {
			menu: [
				// Deletes SetVar
				{
					caption: "Delete this <IntegerArray>",
					action: Xonomy.deleteElement
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"arrayName": {
					asker: Xonomy.askString,
				},
				"initRange": {
					asker: Xonomy.askString,
				},
				"endRange": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"SplitVar": {
			menu: [
				// Deletes SplitVar
				{
					caption: "Delete this <SplitVar>",
					action: Xonomy.deleteElement
				},
				// {
					// caption: "New <SplitVar> before this",
					// action: Xonomy.newElementBefore,
					// actionParameter: "<SplitVar arrayName=\"\" separator=\"\" inputVarName=\"\"/>"
				// },
				// {
					// caption: "New <SplitVar> after this",
					// action: Xonomy.newElementAfter,
					// actionParameter: "<SplitVar arrayName=\"\" separator=\"\" inputVarName=\"\"/>"
				// }
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"arrayName": {
					asker: Xonomy.askString,
				},
				"separator": {
					asker: Xonomy.askPicklist,
					askerParameter: [
						{value: "comma", caption: "Comma separated"},
						{value: "semicolon", caption: "Semicolon separated"},
						{value: "pipe", caption: "Pipe separated"},
						{value: "nl", caption: "New/Brake line"},
					]
				},
				"inputVarName": {
					asker: Xonomy.askString,
				},
				// "wrapper": {
					// asker: Xonomy.askPicklist,
					// askerParameter: [
						// {value: "quote", caption: "Quote wrapped"},
						// {value: "quotes", caption: "Quotes separated"},
					// ]
				// },
			}
		},
		
		
		// "SplitFile": {
			// menu: [
				// // Deletes SplitFile
				// {
					// caption: "Delete this <SplitFile>",
					// action: Xonomy.deleteElement
				// },
				// {
					// caption: "New <SplitFile> before this",
					// action: Xonomy.newElementBefore,
					// actionParameter: "<SplitFile arrayName=\"\" separator=\"\" inputFileName=\"\"/>"
				// },
				// {
					// caption: "New <SplitFile> after this",
					// action: Xonomy.newElementAfter,
					// actionParameter: "<SplitFile arrayName=\"\" separator=\"\" inputFileName=\"\"/>"
				// }
			// ],
			// canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			// attributes: {
				// "arrayName": {
					// asker: Xonomy.askString,
				// },
				// "separator": {
					// asker: Xonomy.askPicklist,
					// askerParameter: [
						// {value: "newline", caption: "New Line"},
						// {value: "comma", caption: "Comma separated"},
						// {value: "semicolon", caption: "Semicolon separated"},
					// ]
				// },
				// "inputFileName": {
					// asker: Xonomy.askString,
				// },
			// }
		// },
		
		
		"FOREACH": {
			menu: [
				// CHILDS
				{
					caption: "Append a <DO>",
					action: Xonomy.newElementChild,
					actionParameter: "<DO/>"
				},
				{
					caption: "Append a <IF>",
					action: Xonomy.newElementChild,
					actionParameter: "<IF><VAR name='' compare=''><DO/></VAR></IF>"
				},
				// Deletes FOREACH
				{
					caption: "Delete this <FOREACH>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"arrayName": {
					asker: Xonomy.askString,
				},
				"element": {
					isReadOnly: true
				},
			}
		},
		
		
		"FOREACH_NUMBER": {
			menu: [
				// CHILDS
				{
					caption: "Append a <DO>",
					action: Xonomy.newElementChild,
					actionParameter: "<DO/>"
				},
				{
					caption: "Append a <IF>",
					action: Xonomy.newElementChild,
					actionParameter: "<IF><VAR name='' compare=''><DO/></VAR></IF>"
				},
				// Deletes FOREACH
				{
					caption: "Delete this <FOREACH_NUMBER>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"element": {
					isReadOnly: true
				},
				"initRange": {
					asker: Xonomy.askString,
				},
				"endRange": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"AUTOBOT": {
			menu: [
				// Deletes AUTOBOT
				{
					caption: "Delete this <AUTOBOT>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <AUTOBOT> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<AUTOBOT idAutoBot=\"\" catchVarName=\"\"><JsonVars><![CDATA[]]></JsonVars></AUTOBOT>"
				},
				{
					caption: "New <AUTOBOT> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<AUTOBOT idAutoBot=\"\" catchVarName=\"\"><JsonVars><![CDATA[]]></JsonVars></AUTOBOT>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"idAutoBot": {
					asker: Xonomy.askString,
				},
				"catchVarName": {
					asker: Xonomy.askString,
				},
				"JsonVars": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"LOGING": {
			menu: [
				// Deletes LOGING
				{
					caption: "Delete this <LOGING>",
					action: Xonomy.deleteElement
				},
				{
					caption: "New <LOGING> before this",
					action: Xonomy.newElementBefore,
					actionParameter: "<LOGING comment=\"\"/>"
				},
				{
					caption: "New <LOGING> after this",
					action: Xonomy.newElementAfter,
					actionParameter: "<LOGING comment=\"\"/>"
				}
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"comment": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"RETURN": {
			menu: [
				// Deletes RETURN
				{
					caption: "Delete this <RETURN>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"value": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"DecodePWDtoVar": {
			backgroundColour: '#F5E2E5',
			menu: [
				// Deletes RETURN
				{
					caption: "Delete this <DecodePWDtoVar>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"name": {
					asker: Xonomy.askString,
				},
				"EncKey": {
					asker: Xonomy.askString,
				},
				"EncPasswd": {
					asker: Xonomy.askString,
				},
			}
		},
		
		
		"END": {
			// oneliner: true,
			menu: [
				// Deletes END
				{
					caption: "Delete this <END>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"value": {
					asker: Xonomy.askPicklist,
					askerParameter: [
						{value: "Resolved", caption: "Resolved"},
						{value: "Failed", caption: "Failed"},
						{value: "Rejected", caption: "Rejected"},
						{value: "Pending", caption: "Pending"},
					]
				},
			},
		},
		
		
		"Sleep": {
			// oneliner: true,
			menu: [
				// Deletes END
				{
					caption: "Delete this <Sleep>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"seconds": {
					asker: Xonomy.askPicklist,
					askerParameter: [
						{value: "1", caption: "1 Second"},
						{value: "2", caption: "2 Seconds"},
						{value: "3", caption: "3 Seconds"},
						{value: "4", caption: "4 Seconds"},
						{value: "5", caption: "5 Seconds"},
						{value: "6", caption: "6 Seconds"},
						{value: "7", caption: "7 Seconds"},
						{value: "8", caption: "8 Seconds"},
						{value: "9", caption: "9 Seconds"},
						{value: "10", caption: "10 Seconds"},
						{value: "20", caption: "20 Seconds"},
						{value: "30", caption: "30 Seconds"},
						{value: "60", caption: "60 Seconds"},
						{value: "120", caption: "120 Seconds"},
					]
				},
			},
		},
		
		
		"SendEMAIL": {
			// oneliner: true,
			menu: [
				// Deletes END
				{
					caption: "Delete this <SendEMAIL>",
					action: Xonomy.deleteElement
				},
			],
			canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "FOREACH_NUMBER", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand", "IntegerArray", "Sleep", "DecodePWDtoVar"],
			attributes: {
				"From": {
					asker: Xonomy.askString,
				},
				"To": {
					asker: Xonomy.askString,
				},
				"Subject": {
					asker: Xonomy.askString,
				},
				"Type": {
					asker: Xonomy.askPicklist,
					askerParameter: [
						{value: "text/plain", caption: "Text/Plain"},
						{value: "text/html", caption: "Text/HTML"},
					]
				},
			},
		},
		
		
		
		
		
		
		
	}
};
