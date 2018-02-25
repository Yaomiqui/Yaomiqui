		var specifications={
			// onchange: function(){
				// console.log("I been changed now!")
			// },
			// validate: function(obj){
				// console.log("I be validatin' now!")
			// },
			elements: {
				"AUTO":{
					menu: [
						{
							caption: "Append a <IF>",
							action: Xonomy.newElementChild,
							// actionParameter: "<IF/>"
							actionParameter: "<IF><VAR name='' compare=''/></IF>"
						},
						{
							caption: "Append a <DO>",
							action: Xonomy.newElementChild,
							actionParameter: "<DO/>"
						},
					]
				},
				"ON": {
					menu: [
						{
							caption: "Append a <VAR>",
							action: Xonomy.newElementChild,
							actionParameter: "<VAR name='' compare=''/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
				},
				"IF": {
					menu: [
						{
							caption: "Append a <VAR>",
							action: Xonomy.newElementChild,
							actionParameter: "<VAR name='' compare=''/>"
						},
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
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
				},
				"VAR": {
					menu: [
						// CHILDS
						{
							caption: "Append a <DO>",
							action: Xonomy.newElementChild,
							actionParameter: "<DO/>"
						},
						{
							caption: "Append a <LOGING>",
							action: Xonomy.newElementChild,
							// actionParameter: "<END>Resolve</END>",
							actionParameter: "<LOGING comment=\"\"/>",
						},
						{
							caption: "Append a <END>",
							action: Xonomy.newElementChild,
							// actionParameter: "<END>Resolve</END>",
							actionParameter: "<END value=\"Resolved\" />",
						},
						{
							caption: "Append a <RETURN>",
							action: Xonomy.newElementChild,
							actionParameter: "<RETURN value=\"\"/>"
						},
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
							actionParameter: "<VAR name='' compare=''/>"
						},
						{
							caption: "New <VAR> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<VAR name='' compare=''/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"name": {
							asker: Xonomy.askString,
							menu: [{
								caption: "Delete this @name",
								action: Xonomy.deleteAttribute
							}]
						},
						"compare": {
							asker: Xonomy.askPicklist,
							askerParameter: [
								{value: "exists", caption: "Exists"},
								{value: "notexist", caption: "Does not Exist"},
								{value: "contains", caption: "Contains"},
								{value: "notcontain", caption: "Does not Contain"},
								{value: "startsw", caption: "Starts with"},
								{value: "endsw", caption: "Ends with"},
								{value: "eq", caption: "Equal to"},
								{value: "ne", caption: "Not Equal to"},
								{value: "isempty", caption: "Is Empty"},
							],
							menu: [{
								caption: "Delete this @compare",
								action: Xonomy.deleteAttribute
							}]
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
					menu: [
						// {
							// caption: "Add @id=\"\"",
							// action: Xonomy.newAttribute,
							// actionParameter: { name: "id", value: "" },
							// hideIf: function(jsElement){ return jsElement.hasAttribute("id"); }
						// },
						{
							caption: "Append a <execLinuxCommand>",
							action: Xonomy.newElementChild,
							actionParameter: "<execLinuxCommand catchVarName=\"\" command=\"\"/>"
						},
						{
							caption: "Append a <SetVar>",
							action: Xonomy.newElementChild,
							actionParameter: "<SetVar name=\"\" value=\"\"/>"
						},
						{
							caption: "Append a <SplitFile>",
							action: Xonomy.newElementChild,
							actionParameter: "<SplitFile arrayName=\"\" separator=\"\" inputFileName=\"\"/>"
						},
						{
							caption: "Append a <SplitVar>",
							action: Xonomy.newElementChild,
							actionParameter: "<SplitVar arrayName=\"\" separator=\"\" inputVarName=\"\"/>"
						},
						{
							caption: "Append a <execRemoteLinuxCommand>",
							action: Xonomy.newElementChild,
							actionParameter: "<execRemoteLinuxCommand catchVarName=\"\" remoteHost=\"\" remoteUser=\"\" passwd=\"\" publicKey=\"\" command=\"\"/>"
						},
						{
							caption: "Append a <execRemoteWindowsCommand>",
							action: Xonomy.newElementChild,
							actionParameter: "<execRemoteWindowsCommand catchVarName=\"\" remoteHost=\"\" domain=\"\" remoteUser=\"\" passwd=\"\" command=\"\"  useKerberos=\"yes\" />"
						},
						{
							caption: "Append a <JSONtoVar>",
							action: Xonomy.newElementChild,
							actionParameter: "<JSONtoVar catchVarName=\"\" JsonSource=\"\"/>"
						},
						{
							caption: "Append a <IF>",
							action: Xonomy.newElementChild,
							// actionParameter: "<IF/>"
							actionParameter: "<IF><VAR name='' compare=''/></IF>"
						},
						{
							caption: "Append a <FOREACH>",
							action: Xonomy.newElementChild,
							actionParameter: "<FOREACH element=\"i\" arrayName=\"\"/>"
						},
						{
							caption: "Append a <AUTOBOT>",
							action: Xonomy.newElementChild,
							actionParameter: "<AUTOBOT idAutoBot=\"\" catchVarName=\"\" JsonVars=\"\"/>"
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
						{
							caption: "New <DO> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<DO/>"
						},
						{
							caption: "New <DO> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<DO/>"
						},
						// Deletes DO
						{
							caption: "Delete this <DO>",
							action: Xonomy.deleteElement
						},
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
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
				
				"END": {
					// oneliner: true,
					menu: [
						// Deletes END
						{
							caption: "Delete this <END>",
							action: Xonomy.deleteElement
						},
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
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
				
				
				"LOGING": {
					menu: [
						// Deletes LOGING
						{
							caption: "Delete this <LOGING>",
							action: Xonomy.deleteElement
						},
						{
							caption: "New <execLinuxCommand> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<LOGING comment=\"\"/>"
						},
						{
							caption: "New <execLinuxCommand> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<LOGING comment=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"comment": {
							asker: Xonomy.askString,
						},
					}
				},
				
				
				"execLinuxCommand": {
					menu: [
						// Deletes execLinuxCommand
						{
							caption: "Delete this <execLinuxCommand>",
							action: Xonomy.deleteElement
						},
						// {
							// caption: "New <execLinuxCommand> before this",
							// action: Xonomy.newElementBefore,
							// actionParameter: "<execLinuxCommand catchVarName=\"\" command=\"\"/>"
						// },
						// {
							// caption: "New <execLinuxCommand> after this",
							// action: Xonomy.newElementAfter,
							// actionParameter: "<execLinuxCommand catchVarName=\"\" command=\"\" />"
						// }
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"catchVarName": {
							asker: Xonomy.askString,
						},
						"command": {
							asker: Xonomy.askString,
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
							actionParameter: "<JSONtoVar catchVarName=\"\" JsonSource=\"\"/>"
						},
						{
							caption: "New <execLinuxCommand> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<JSONtoVar catchVarName=\"\" JsonSource=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"catchVarName": {
							asker: Xonomy.askString,
						},
						"JsonSource": {
							asker: Xonomy.askString,
						},
					}
				},
				
				
				"execRemoteLinuxCommand": {
					menu: [
						// Deletes execRemoteLinuxCommand
						{
							caption: "Delete this <execRemoteLinuxCommand>",
							action: Xonomy.deleteElement
						},
						// {
							// caption: "New <execRemoteLinuxCommand> before this",
							// action: Xonomy.newElementBefore,
							// actionParameter: "<execRemoteLinuxCommand catchVarName=\"\" remoteHost=\"\" remoteUser=\"\" passwd=\"\" publicKey=\"\" command=\"\"/>"
						// },
						// {
							// caption: "New <execRemoteLinuxCommand> after this",
							// action: Xonomy.newElementAfter,
							// actionParameter: "<execRemoteLinuxCommand catchVarName=\"\" remoteHost=\"\" remoteUser=\"\" passwd=\"\" publicKey=\"\" command=\"\"/>"
						// }
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
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
						"command": {
							asker: Xonomy.askString,
						},
					}
				},
				
				
				"execRemoteWindowsCommand": {
					menu: [
						// Deletes execRemoteWindowsCommand
						{
							caption: "Delete this <execRemoteWindowsCommand>",
							action: Xonomy.deleteElement
						},
						// {
							// caption: "New <execRemoteWindowsCommand> before this",
							// action: Xonomy.newElementBefore,
							// actionParameter: "<execRemoteWindowsCommand catchVarName=\"\" remoteHost=\"\"  domain=\"\" remoteUser=\"\" passwd=\"\"command=\"\" useKerberos=\"yes\" />"
						// },
						// {
							// caption: "New <execRemoteWindowsCommand> after this",
							// action: Xonomy.newElementAfter,
							// actionParameter: "<execRemoteWindowsCommand catchVarName=\"\" remoteHost=\"\" domain=\"\" remoteUser=\"\" passwd=\"\" command=\"\" useKerberos=\"yes\" />"
						// }
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
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
							actionParameter: "<SetVar name=\"\" value=\"\" />"
						},
						{
							caption: "New <SetVar> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<SetVar name=\"\" value=\"\" />"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"name": {
							asker: Xonomy.askString,
						},
						"value": {
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
						{
							caption: "New <SplitVar> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<SplitVar arrayName=\"\" separator=\"\" inputVarName=\"\"/>"
						},
						{
							caption: "New <SplitVar> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<SplitVar arrayName=\"\" separator=\"\" inputVarName=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
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
				
				
				"SplitFile": {
					menu: [
						// Deletes SplitFile
						{
							caption: "Delete this <SplitFile>",
							action: Xonomy.deleteElement
						},
						{
							caption: "New <SplitFile> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<SplitFile arrayName=\"\" separator=\"\" inputFileName=\"\"/>"
						},
						{
							caption: "New <SplitFile> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<SplitFile arrayName=\"\" separator=\"\" inputFileName=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"arrayName": {
							asker: Xonomy.askString,
						},
						"separator": {
							asker: Xonomy.askPicklist,
							askerParameter: [
								{value: "newline", caption: "New Line"},
								{value: "comma", caption: "Comma separated"},
								{value: "semicolon", caption: "Semicolon separated"},
							]
						},
						"inputFileName": {
							asker: Xonomy.askString,
						},
					}
				},
				
				
				"FOREACH": {
					menu: [
						// CHILDS
						{
							caption: "Append a <DO>",
							action: Xonomy.newElementChild,
							actionParameter: "<DO/>"
						},
						// Deletes FOREACH
						{
							caption: "Delete this <FOREACH>",
							action: Xonomy.deleteElement
						},
						{
							caption: "New <FOREACH> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<FOREACH element=\"i\" arrayName=\"\"/>"
						},
						{
							caption: "New <FOREACH> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<FOREACH element=\"i\" arrayName=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"arrayName": {
							asker: Xonomy.askString,
						},
						"element": {
							isReadOnly: true
						},
					}
				},
				
				
				"AUTOBOT": {
					menu: [
						// Deletes FOREACH
						{
							caption: "Delete this <AUTOBOT>",
							action: Xonomy.deleteElement
						},
						{
							caption: "New <AUTOBOT> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<AUTOBOT idAutoBot=\"\" catchVarName=\"\" JsonVars=\"\"/>"
						},
						{
							caption: "New <AUTOBOT> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<AUTOBOT idAutoBot=\"\" catchVarName=\"\" JsonVars=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
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
				
				
				"RETURN": {
					menu: [
						// Deletes FOREACH
						{
							caption: "Delete this <RETURN>",
							action: Xonomy.deleteElement
						},
						{
							caption: "New <RETURN> before this",
							action: Xonomy.newElementBefore,
							actionParameter: "<RETURN value=\"\"/>"
						},
						{
							caption: "New <RETURN> after this",
							action: Xonomy.newElementAfter,
							actionParameter: "<RETURN value=\"\"/>"
						}
					],
					canDropTo: ["JSONtoVar", "IF", "DO", "VAR", "FOREACH", "execLinuxCommand", "AUTOBOT", "RETURN", "END", "SetVar", "SplitFile", "SplitVar", "execRemoteLinuxCommand", "execRemoteWindowsCommand"],
					attributes: {
						"value": {
							asker: Xonomy.askString,
						},
					}
				},
				
				
				
				
				
				
			}
		};
