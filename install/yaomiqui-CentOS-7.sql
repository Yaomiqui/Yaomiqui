CREATE USER 'yaomiqui'@'localhost' IDENTIFIED BY 'MYSQL_PASSWD';

CREATE DATABASE IF NOT EXISTS yaomiqui CHARACTER SET 'UTF8' COLLATE 'utf8_general_ci';

GRANT ALL PRIVILEGES ON yaomiqui.* TO 'yaomiqui'@'localhost' IDENTIFIED BY 'MYSQL_PASSWD' WITH GRANT OPTION;

FLUSH PRIVILEGES;

use yaomiqui;

DROP TABLE IF EXISTS users;

CREATE TABLE IF NOT EXISTS users (
	idUser int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	username varchar(40) UNIQUE NOT NULL,
	password varchar(255) NOT NULL,
	name varchar(100) NULL,
	lastName varchar(100) NULL,
	mothersLastName varchar(100) NULL,
	idEmployee varchar(40) NULL,
	email varchar(100) NULL,
	secondaryEmail varchar(100) NULL,
	phone varchar(40) NULL,
	secondaryPhone varchar(40) NULL,
	costCenterId int(11) NULL,
	groupId int(11) NULL,
	secondaryGroupId int(11) NULL,
	theme varchar(30) DEFAULT 'classic_cloud',
	language varchar(10) DEFAULT 'en_US',
	active int(1) DEFAULT '1'
) ENGINE=InnoDB;

INSERT INTO users (idUser, username, password, name, lastName) VALUES ('1', 'admin', 'ADMIN_PASSWD', 'Hugo', 'Maza');
INSERT INTO users (idUser, username, password) VALUES ('2', 'Guest', '');


DROP TABLE IF EXISTS permissions;

CREATE TABLE IF NOT EXISTS permissions (
	idPermission int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	idUser int(11) UNIQUE NOT NULL,
	init int(1) DEFAULT '1',
	overview int(1) DEFAULT '1',
	design int(1) DEFAULT '0',
	accounts int(1) DEFAULT '0',
	accounts_edit int(1) DEFAULT '0',
	settings int(1) DEFAULT '1',
	tickets int(1) DEFAULT '0',
	tickets_form int(1) DEFAULT '0',
	logs int(1) DEFAULT '0',
	charts int(1) DEFAULT '1',
	reports int(1) DEFAULT '0',
	about int(1) DEFAULT '1',
	config int(1) DEFAULT '0',
	my_account int(1) DEFAULT '1',
	alerts int(1) DEFAULT '1',
	alerts_config int(1) DEFAULT '0'
) ENGINE=InnoDB;

INSERT INTO permissions (idUser, init, overview, design, accounts, accounts_edit, settings, tickets, tickets_form, logs, charts, reports, config, my_account, alerts, alerts_config) VALUES ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1');
INSERT INTO permissions (idUser, init, overview, settings) VALUES ('2', '0', '0', '0');


DROP TABLE IF EXISTS autoBot;

CREATE TABLE IF NOT EXISTS autoBot (
	idAutoBot varchar(40) NOT NULL PRIMARY KEY,
	autoBotName varchar(100) NOT NULL,
	description varchar(255) NULL,
	deployedDate datetime NOT NULL,
	idUserDeploy int(11) NOT NULL,
	active int(1) NOT NULL,
	autoBotXML text NULL
) ENGINE=InnoDB;

INSERT INTO `autoBot` (`idAutoBot`, `autoBotName`, `description`, `deployedDate`, `idUserDeploy`, `active`, `autoBotXML`) VALUES
 ('4ScbG76ItWRmUzx5I0SFQmae12gZ28m6VrivtF4p', 'SELF MONITORING AUTOBOT - PROCESS', '', '2018-11-10 01:14:42', 1, 1, '<AUTO><ON><VAR name=\'number\' compare=\'startsw\' value=\'SELF\'/><VAR name=\'sys_id\' compare=\'exists\'/><VAR name=\'subject\' compare=\'eq\' value=\'ALERT BY SELF MONITORING\'/><VAR name=\'state\' compare=\'exists\'/><VAR name=\'type\' compare=\'exists\'/><VAR name=\'Message\' compare=\'exists\'/></ON><DO><SendEMAIL From=\'root@localhost\' To=\'root@localhost\' Subject=\'${subject}\' Type=\'text/plain\'><Body xml:space=\'preserve\'><![CDATA[Yaomiqui Server has an alert:\n\n${Message}]]></Body></SendEMAIL><LOGING comment=\'${Message}\'/><END value=\'Rejected\'/></DO></AUTO>'),
 ('kKzfSTwXnMw1QiOZ9agd2KSTl2ertZNvCv1IjMhI', 'SELF MONITORING AUTOBOT - CPU', '', '2018-12-02 20:53:43', 1, 1, '<AUTO><ON><VAR name=\'subject\' compare=\'eq\' value=\'SELF MONITORING\'/><VAR name=\'type\' compare=\'eq\' value=\'MEMORY\'/><VAR name=\'threshold\' compare=\'exists\'/></ON><DO><execLinuxCommand catchVarName=\'percent\'><command xml:space=\'preserve\'><![CDATA[ps -eo pcpu |  grep -v \'%CPU\' | awk \'{ sum += $1 } END { print sum }\']]></command></execLinuxCommand><IF><VAR name=\'${percent}\' compare=\'lt\' value=\'${threshold}\'><DO><execLinuxCommand catchVarName=\'tmpFileExist\'><command xml:space=\'preserve\'><![CDATA[perl -e \'if (-f "/tmp/cpuSelfAlert") {print 1} else {print 0}\']]></command></execLinuxCommand></DO><IF><VAR name=\'${tmpFileExist}\' compare=\'ne\' value=\'1\'><DO><execLinuxCommand catchVarName=\'RandIncidentNumber\'><command xml:space=\'preserve\'><![CDATA[perl -e \'@chars=(0..9);for (1..8) {$key .= $chars[int(rand(@chars))]};print SELF.$key\']]></command></execLinuxCommand><SetVar name=\'JsonToCreateTicket\'><value xml:space=\'preserve\'><![CDATA[{"ticket": {"number": "${RandIncidentNumber}","sys_id": "${RandIncidentNumber}","subject": "ALERT BY SELF MONITORING","state": "New","type": "INCIDENT","Message":"High CPU consumption: ${percent} %"}}]]></value></SetVar><execLinuxCommand catchVarName=\'insertTicket\'><command xml:space=\'preserve\'><![CDATA[curl -k -H "Content-Type: application/json" -X PUT -d \'${JsonToCreateTicket}\' --url "https://127.0.0.1/generic-api.cgi/insertTicket/";exit;]]></command></execLinuxCommand><execLinuxCommand catchVarName=\'touchTmpFile\'><command xml:space=\'preserve\'><![CDATA[touch /tmp/cpuSelfAlert]]></command></execLinuxCommand></DO></VAR></IF></VAR><VAR name=\'${percent}\' compare=\'gt\' value=\'${threshold}\'><DO><execLinuxCommand catchVarName=\'tmpFileExist\'><command xml:space=\'preserve\'><![CDATA[perl -e \'if (-f "/tmp/cpuSelfAlert") {print 1} else {print 0}\']]></command></execLinuxCommand><IF><VAR name=\'${tmpFileExist}\' compare=\'eq\' value=\'1\'><DO><execLinuxCommand catchVarName=\'resultRemoveTmpFile\'><command xml:space=\'preserve\'><![CDATA[rm -f /tmp/cpuSelfAlert 2>/dev/null]]></command></execLinuxCommand></DO></VAR></IF></DO></VAR></IF><END value=\'Resolved\'/></DO></AUTO>'),
 ('TFfDJRL2Hyw2U202aGLAfBgMAfx79r76OInrtipK', 'SELF MONITORING AUTOBOT - MEMORY', '', '2018-12-02 20:54:07', 1, 1, '<AUTO><ON><VAR name=\'subject\' compare=\'eq\' value=\'SELF MONITORING\'/><VAR name=\'type\' compare=\'eq\' value=\'MEMORY\'/><VAR name=\'threshold\' compare=\'exists\'/></ON><DO><execLinuxCommand catchVarName=\'percent\'><command xml:space=\'preserve\'><![CDATA[ps -eo pmem |  grep -v \'%MEM\' | awk \'{ sum += $1 } END { print sum }\']]></command></execLinuxCommand><IF><VAR name=\'${percent}\' compare=\'lt\' value=\'${threshold}\'><DO><execLinuxCommand catchVarName=\'tmpFileExist\'><command xml:space=\'preserve\'><![CDATA[perl -e \'if (-f "/tmp/memorySelfAlert") {print 1} else {print 0}\']]></command></execLinuxCommand></DO><IF><VAR name=\'${tmpFileExist}\' compare=\'ne\' value=\'1\'><DO><execLinuxCommand catchVarName=\'RandIncidentNumber\'><command xml:space=\'preserve\'><![CDATA[perl -e \'@chars=(0..9);for (1..8) {$key .= $chars[int(rand(@chars))]};print SELF.$key\']]></command></execLinuxCommand><SetVar name=\'JsonToCreateTicket\'><value xml:space=\'preserve\'><![CDATA[{"ticket": {"number": "${RandIncidentNumber}","sys_id": "${RandIncidentNumber}","subject": "ALERT BY SELF MONITORING","state": "New","type": "INCIDENT","Message":"High MEMORY consumption: ${percent} %"}}]]></value></SetVar><execLinuxCommand catchVarName=\'insertTicket\'><command xml:space=\'preserve\'><![CDATA[curl -k -H "Content-Type: application/json" -X PUT -d \'${JsonToCreateTicket}\' --url "https://127.0.0.1/generic-api.cgi/insertTicket/";exit;]]></command></execLinuxCommand><execLinuxCommand catchVarName=\'touchTmpFile\'><command xml:space=\'preserve\'><![CDATA[touch /tmp/memorySelfAlert]]></command></execLinuxCommand></DO></VAR></IF></VAR><VAR name=\'${percent}\' compare=\'gt\' value=\'${threshold}\'><DO><execLinuxCommand catchVarName=\'tmpFileExist\'><command xml:space=\'preserve\'><![CDATA[perl -e \'if (-f "/tmp/memorySelfAlert") {print 1} else {print 0}\']]></command></execLinuxCommand><IF><VAR name=\'${tmpFileExist}\' compare=\'eq\' value=\'1\'><DO><execLinuxCommand catchVarName=\'resultRemoveTmpFile\'><command xml:space=\'preserve\'><![CDATA[rm -f /tmp/memorySelfAlert 2>/dev/null]]></command></execLinuxCommand></DO></VAR></IF></DO></VAR></IF><END value=\'Resolved\'/></DO></AUTO>'),
 ('y3MdfumfMyOiYqg9KiAlx8Sll0XzddxmPNXn9ZWD', 'FOR WinRM TESTING', 'This AutoBot is just a simple test connection from Yaomiqui to Windows using WinRM', '2018-12-02 22:54:07', 1, 1, '<AUTO><ON><VAR name=\'number\' compare=\'exists\'/><VAR name=\'sys_id\' compare=\'exists\'/><VAR name=\'subject\' compare=\'eq\' value=\'MY SUBJECT TO BE FILTERED BY SPECIFIC AUTOBOT\'/><VAR name=\'state\' compare=\'exists\'/><VAR name=\'type\' compare=\'exists\'/></ON><DO><execRemoteWindowsCommand catchVarName=\'output\' remoteHost=\'REMOTE-HOST-NAME\' remoteUser=\'\' passwd=\'\' EncKey=\'\' EncPasswd=\'\' domain=\'MYDOMAIN.COM\' useKerberos=\'yes\' protocol=\'http\'><command xml:space=\'preserve\'><![CDATA[powershell &{  Get-Host;}]]></command></execRemoteWindowsCommand><LOGING comment=\'Output: ${output}\'/><LOGING comment=\'Error: ${Error}\'/><END value=\'Resolved\'/></DO></AUTO>'),
 ('bZY1bS54NQJdmy8fUo9yyfdaqeU2hyQz5KTz5CsT', 'Alert Processing 0001 - Init', 'Alert Processing for Trigger 0001. Initial Auto Bot. (Example)', '2020-06-07 10:43:53', 1,1,'<AUTO><ON><VAR name=\'number\' compare=\'exists\'/><VAR name=\'sys_id\' compare=\'exists\'/><VAR name=\'subject\' compare=\'eq\' value=\'Escalation for Trigger 0001\'/><VAR name=\'state\' compare=\'exists\'/><VAR name=\'type\' compare=\'exists\'/></ON><DO><IF><VAR name=\'${escalationNumber}\' compare=\'eq\' value=\'1\'><DO><AUTOBOT idAutoBot=\'E2v6NsLvdLMeRnzc3Y7ChaGcNPtt8gL9Ti9qqmW6\' catchVarName=\'EscalationOneResults\'><JsonVars xml:space=\'preserve\'><![CDATA[{\n  \"ticket\": {\n    \"number\": \"${number}\",\n    \"subject\": \"Escalation One - Trigger 0001\",\n    \"dlFirstEscalation\": \"${dlFirstEscalation}\"\n	},\n  \"data\": {\n    \"insertDate\": \"\",\n    \"severity\": \"\",\n    \"impact\": \"\",\n    \"urgency\": \"\",\n    \"title\": \"\",\n    \"definition\": \"\",\n    \"description\": \"\"\n  }\n}]]></JsonVars></AUTOBOT></DO></VAR></IF><IF><VAR name=\'${escalationNumber}\' compare=\'eq\' value=\'2\'><DO><AUTOBOT idAutoBot=\'nWnX6PFBinZrHybVTCWMAvAF61tQbiFXtluNkWMV\' catchVarName=\'EscalationTwoResults\'><JsonVars xml:space=\'preserve\'><![CDATA[{\n  \"ticket\": {\n    \"number\": \"${number}\",\n    \"subject\": \"Escalation Two - Trigger 0001\",\n    \"dlSecondEscalation\": \"${dlSecondEscalation}\"\n	},\n  \"data\": {\n    \"insertDate\": \"\",\n    \"severity\": \"\",\n    \"impact\": \"\",\n    \"urgency\": \"\",\n    \"title\": \"\",\n    \"definition\": \"\",\n    \"description\": \"\"\n  }\n}]]></JsonVars></AUTOBOT></DO></VAR></IF><IF><VAR name=\'${escalationNumber}\' compare=\'eq\' value=\'3\'><DO><AUTOBOT idAutoBot=\'5zmWV0VexV02E3HbPxl4VC1gqtq3GBOziyMKPtpY\' catchVarName=\'EscalationThreeResults\'><JsonVars xml:space=\'preserve\'><![CDATA[{\n  \"ticket\": {\n    \"number\": \"${number}\",\n    \"subject\": \"Escalation Three - Trigger 0001\",\n    \"dlThirdEscalation\": \"${dlThirdEscalation}\"\n	},\n  \"data\": {\n    \"insertDate\": \"\",\n    \"severity\": \"\",\n    \"impact\": \"\",\n    \"urgency\": \"\",\n    \"title\": \"\",\n    \"definition\": \"\",\n    \"description\": \"\"\n  }\n}]]></JsonVars></AUTOBOT></DO></VAR></IF><LOGING comment=\'Init. Returning on time\'/><END value=\'Resolved\'/></DO></AUTO>'),
 ('E2v6NsLvdLMeRnzc3Y7ChaGcNPtt8gL9Ti9qqmW6', 'Alert Processing 0001 - Escalation One', '', '2020-06-07 09:25:13', 1,1,'<AUTO><ON><VAR name=\'number\' compare=\'exists\'/><VAR name=\'subject\' compare=\'eq\' value=\'Escalation One - Trigger 0001\'/><VAR name=\'dlFirstEscalation\' compare=\'exists\'/></ON><DO><LOGING comment=\'Processing Escalation One\'/><RETURN value=\'Successful\'/></DO></AUTO>'),
 ('nWnX6PFBinZrHybVTCWMAvAF61tQbiFXtluNkWMV', 'Alert Processing 0001 - Escalation Two', '', '2020-06-07 09:55:35', 1,1,'<AUTO><ON><VAR name=\'number\' compare=\'exists\'/><VAR name=\'subject\' compare=\'eq\' value=\'Escalation Two - Trigger 0001\'/><VAR name=\'dlSecondEscalation\' compare=\'exists\'/></ON><DO><LOGING comment=\'Processing Escalation Two\'/><RETURN value=\'Successful\'/></DO></AUTO>'),
 ('5zmWV0VexV02E3HbPxl4VC1gqtq3GBOziyMKPtpY', 'Alert Processing 0001 - Escalation Three', '', '2020-06-07 09:57:18', 1,1,'<AUTO><ON><VAR name=\'number\' compare=\'exists\'/><VAR name=\'subject\' compare=\'eq\' value=\'Escalation Third- Trigger 0001\'/><VAR name=\'dlThirdEscalation\' compare=\'exists\'/></ON><DO><LOGING comment=\'Processing Escalation Three\'/><RETURN value=\'Successful\'/></DO></AUTO>');


DROP TABLE IF EXISTS autoBotHistory;

CREATE TABLE IF NOT EXISTS autoBotHistory (
	idABhistory int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	idAutoBot varchar(40) NOT NULL,
	autoBotName varchar(100) NOT NULL,
	description varchar(255) NULL,
	deployedDate datetime NOT NULL,
	idUserDeploy int(11) NOT NULL,
	active int(1) NOT NULL,
	autoBotXML text NULL
) ENGINE=InnoDB;


DROP TABLE IF EXISTS ticket;

CREATE TABLE IF NOT EXISTS ticket (
	idTicket int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	numberTicket varchar(255) NOT NULL UNIQUE,
	sysidTicket varchar(255) NOT NULL,
	subject varchar(255) NOT NULL,
	typeTicket varchar(40) NOT NULL,
	idAutoBotCatched varchar(40) NULL,
	initialDate datetime NOT NULL,
	initialState varchar(50) NOT NULL,
	finalDate datetime NULL,
	finalState varchar(50) NULL,
	json text NOT NULL
) ENGINE=InnoDB;


DROP TABLE IF EXISTS log;

CREATE TABLE IF NOT EXISTS log (
	idLog int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	numberTicket varchar(255) NOT NULL,
	insertDate datetime NOT NULL,
	log mediumtext NULL
) ENGINE=InnoDB;


DROP TABLE IF EXISTS report;

CREATE TABLE IF NOT EXISTS report (
	idReport int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	typeTicket varchar(255) NOT NULL,
	averageAttTime varchar(3) NOT NULL,
	costPerHour varchar(3) NOT NULL,
	costPerTicket varchar(3) NOT NULL
) ENGINE=InnoDB;

INSERT INTO report (typeTicket, averageAttTime, costPerHour, costPerTicket) VALUES ('INCIDENT', '2', '9', '1');
INSERT INTO report (typeTicket, averageAttTime, costPerHour, costPerTicket) VALUES ('TASK', '3', '8', '1');


DROP TABLE IF EXISTS configVars;

CREATE TABLE IF NOT EXISTS configVars (
	idConfigVar int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	varName varchar(100) NOT NULL,
	varValue varchar(100) NULL
) ENGINE=InnoDB;

INSERT INTO configVars (varName, varValue) VALUES ('PROC_MAX_PARALLEL', '30');
INSERT INTO configVars (varName, varValue) VALUES ('SHOW_LOGS_IN_FRAME', '1');
INSERT INTO configVars (varName, varValue) VALUES ('SHOW_PER_PAGE', '50');
INSERT INTO configVars (varName, varValue) VALUES ('REFRESH_RATE', '3000');
INSERT INTO configVars (varName, varValue) VALUES ('DESIGNER_SET_MODE', 'nerd');
INSERT INTO configVars (varName, varValue) VALUES ('CRITICAL_PROC', '0');
INSERT INTO configVars (varName, varValue) VALUES ('COOKIE_TERM', '');
INSERT INTO configVars (varName, varValue) VALUES ('STATUS_AFTER_TIMEOUT', 'Rejected');
INSERT INTO configVars (varName, varValue) VALUES ('CONNECTTIMEOUT', '43200');
INSERT INTO configVars (varName, varValue) VALUES ('TIMEOUT', '300');
INSERT INTO configVars (varName, varValue) VALUES ('SSH_TIMEOUT', '30');
INSERT INTO configVars (varName, varValue) VALUES ('ENVIRONMENT', 'DEV');
INSERT INTO configVars (varName, varValue) VALUES ('SHOW_LINECHARTS', '1');


DROP TABLE IF EXISTS environmentVars;

CREATE TABLE IF NOT EXISTS environmentVars (
	idEnvVar int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	varName varchar(100) NOT NULL,
	varValue varchar(255) NULL
) ENGINE=InnoDB;







DROP TABLE IF EXISTS alerts;

CREATE TABLE IF NOT EXISTS alerts (
	idAlert int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    alertCounter int(4) NOT NULL DEFAULT '1',
    insertDate datetime NOT NULL,
    lastDate datetime NOT NULL,
    hiddenDate datetime NULL,
    severity varchar(40) NULL,
    impact varchar(40) NULL,
    urgency varchar(40) NULL,
    queue varchar(40) NULL,
    title varchar(40) NULL,
    definition varchar(40) NULL,
    description varchar(255) NULL,
    idTrigger int(40) NOT NULL DEFAULT '0001',
    silenced int(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB;


DROP TABLE IF EXISTS alertTriggerToAutoBot;

CREATE TABLE IF NOT EXISTS alertTriggerToAutoBot (
	idTrigger int(4) ZEROFILL NOT NULL PRIMARY KEY AUTO_INCREMENT,
    triggerName varchar(40) NULL,
    countToStatusUp int(2) NOT NULL DEFAULT '2',
    minutesToStatusDown int(2) NOT NULL DEFAULT '5',
    minutesToHidden int(2) NOT NULL DEFAULT '10',
    dlFirstEscalation varchar(255) NULL,
    dlSecondEscalation varchar(255) NULL,
    dlThirdEscalation varchar(255) NULL,
    idAutoBot varchar(40) NULL,
    yaomiquiTriggerTicket int(1) NOT NULL DEFAULT '1',
    Json text NULL
) ENGINE=InnoDB;

INSERT INTO alertTriggerToAutoBot (idTrigger, triggerName, countToStatusUp, minutesToStatusDown, minutesToHidden, dlFirstEscalation, dlSecondEscalation, dlThirdEscalation, idAutoBot, Json) VALUES ('0001', 'Default Trigger', '2', '6', '11', 'someone@somedomain.com','someone@somedomain.com','someone@somedomain.com', 'bZY1bS54NQJdmy8fUo9yyfdaqeU2hyQz5KTz5CsT', '{\r\n  \"ticket\": {\r\n    \"number\": \"${randomNumber}\",\r\n    \"sys_id\": \"${randomSysId}\",\r\n    \"subject\": \"Escalation for Trigger 0001\",\r\n    \"state\": \"NEW\",\r\n    \"type\": \"INTERNAL\",\r\n    [[AUTOMATED-DATA]]\r\n	},\r\n  \"data\": {\r\n    \r\n  }\r\n}');


DROP TABLE IF EXISTS scalation;

CREATE TABLE IF NOT EXISTS scalation (
	idScalation int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    idAlert int(40) NOT NULL,
    firstScalation datetime NULL,
    numberFirstTicket varchar(64) NULL,
    secondScalation datetime NULL,
    numberSecondTicket varchar(64) NULL,
    thirdScalation datetime NULL,
    numberThirdTicket varchar(64) NULL
) ENGINE=InnoDB;


DROP TABLE IF EXISTS alertsView;

CREATE TABLE IF NOT EXISTS alertsView (
	idView int(40) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    viewName varchar(100) NOT NULL,
    severity varchar(40) NULL,
    impact varchar(40) NULL,
    urgency varchar(40) NULL,
    queue varchar(40) NULL,
    title varchar(40) NULL,
    definition varchar(40) NULL,
    description varchar(255) NULL
) ENGINE=InnoDB;
--  INSERT INTO alertsView (viewName, title, definition, description) VALUES ('Test Alert', 'Just for test', 'Just for test', 'This alert is for check if this thing works');

DROP TABLE IF EXISTS alertsHistory;

CREATE TABLE IF NOT EXISTS alertsHistory (
	idAlert int(40) NOT NULL PRIMARY KEY,
    alertCounter int(4) NOT NULL DEFAULT '1',
    insertDate datetime NOT NULL,
    lastDate datetime NOT NULL,
    hiddenDate datetime NULL,
    severity varchar(40) NULL,
    impact varchar(40) NULL,
    urgency varchar(40) NULL,
    queue varchar(40) NULL,
    title varchar(40) NULL,
    definition varchar(40) NULL,
    description varchar(255) NULL,
    idTrigger int(40) NOT NULL DEFAULT '0001',
    silenced int(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB;








