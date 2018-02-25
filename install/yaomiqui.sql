DROP USER 'yaomiqui'@'localhost';

CREATE USER 'yaomiqui'@'localhost' IDENTIFIED BY 'MYSQL_PASSWD';

DROP DATABASE yaomiqui;

CREATE DATABASE IF NOT EXISTS yaomiqui CHARACTER SET 'UTF8' COLLATE 'utf8_general_ci';

use yaomiqui;

GRANT ALL PRIVILEGES ON yaomiqui.* TO 'yaomiqui'@'localhost' IDENTIFIED BY 'MYSQL_PASSWD' WITH GRANT OPTION;

FLUSH PRIVILEGES;



DROP TABLE IF EXISTS users;

CREATE TABLE IF NOT EXISTS users (
	idUser int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	username varchar(40) UNIQUE NOT NULL,
	password varchar(64) NOT NULL,
	name varchar(40) NULL,
	lastName varchar(40) NULL,
	mothersLastName varchar(40) NULL,
	idEmployee varchar(40) NULL,
	email varchar(60) NULL,
	secondaryEmail varchar(60) NULL,
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
	charts int(1) DEFAULT '0',
	reports int(1) DEFAULT '0',
	about int(1) DEFAULT '1'
) ENGINE=InnoDB;

INSERT INTO permissions (idUser, init, overview, design, accounts, accounts_edit, settings, tickets, tickets_form, logs, charts, reports, about) VALUES ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1');
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

INSERT INTO autoBot (idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active, autoBotXML) VALUES ('0bUy2JHb8BwGabqb5kMDuJBdvyMf56soipvQ8OLn', 'TEST SEND EMAIL', 'Send an Email from local host', '2018-02-11 13:02:27', '1', '1', '<AUTO><ON><VAR name="TO" compare="exists"/><VAR name="FROM" compare="exists"/><VAR name="SUBJECT" compare="eq" value="TEST SEND EMAIL"/><VAR name="MESSAGE" compare="exists"/><VAR name="number" compare="exists"/></ON><DO><execLinuxCommand catchVarName="results" command="/bin/echo [quotes]${MESSAGE}[quotes] | /usr/bin/mailx -s [quotes]${SUBJECT}[quotes] -r ${FROM} -- ${TO}"/><IF><VAR name="${results}" compare="isempty"><RETURN value="Email sent"/></VAR></IF></DO></AUTO>');
INSERT INTO autoBot (idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active, autoBotXML) VALUES ('rQBjluDurWEg2F0OVjbBcksb7vPaCLUqOMk8q3aQ', 'TEST CREATE LOCAL USER', 'AutoBot for testing. It creates an user in the local server.', '2018-02-11 05:30:21', '1', '1', '<AUTO><ON><VAR name="number" compare="exists"/><VAR name="user" compare="exists"/><VAR name="subject" compare="eq" value="CREATE LOCAL USER"/></ON><IF><VAR name="${user}" compare="notcontain" value=" -"><DO><execLinuxCommand catchVarName="respCreationUser" command="/usr/sbin/useradd -m -d /home/${user} -k /etc/skel -s /bin/bash -p [comm]/usr/bin/perl -e [quote]print crypt([quotes]${user}[quotes],[quotes]SA[quotes])[quote][comm] [quote]${user}[quote]"/><IF><VAR name="${respCreationUser}" compare="isempty"><DO><AUTOBOT idAutoBot="0bUy2JHb8BwGabqb5kMDuJBdvyMf56soipvQ8OLn" catchVarName="respSendMail" JsonVars="[quotes]number[quotes]: [quotes]${number}[quotes],[quotes]TO[quotes]: [quotes]hmaza@regiolinux.net[quotes],[quotes]FROM[quotes]: [quotes]hugo.maza@gmail.com[quotes],[quotes]SUBJECT[quotes]: [quotes]User Created[quotes],[quotes]MESSAGE[quotes]: [quotes]User ${user} created. Password is the same User. Please change it immediately[quotes]"/><LOGING comment="User ${user} created. Password is the same that username"/><END value="Resolved"/></DO></VAR><VAR name="${respCreationUser}" compare="exists"><LOGING comment="Error: ${respCreationUser}"/><END value="Rejected"/></VAR></IF></DO></VAR><VAR name="${user}" compare="contains" value=" -"><DO><LOGING comment="User contains some not valid character"/><END value="Failed"/></DO></VAR></IF></AUTO>');
INSERT INTO autoBot (idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active, autoBotXML) VALUES ('J33pGnE9tCasB0FhSeFkPMfwoKPADmbvPdI5iycp', 'TEST PARSE JSON TO HASH VAR', 'AutoBot to show how to parse a JSON variable and add values to a HASH', '2018-02-18 00:01:12', '1', '1', '<AUTO><ON><VAR name="number" compare="exists"/><VAR name="sys_id" compare="exists"/><VAR name="subject" compare="eq" value="JSON TO VAR TESTING"/><VAR name="state" compare="exists"/></ON><DO><SetVar name="JSONinput" value="{  [quotes]ticket[quotes]: {  [quotes]number[quotes]:[quotes]INC874829233[quotes],  [quotes]sys_id[quotes]:[quotes]xrxtcyeFd7OwG84y3gG37jdudKc6bts3wI84t3e[quotes],  [quotes]subject[quotes]:[quotes]RUN COMMAND IN WINDOWS REMOTE MACHINE[quotes],  [quotes]state[quotes]:[quotes]assigned[quotes]  } }"/><JSONtoVar catchVarName="JSON" JsonSource="${JSONinput}"/><LOGING comment="Number is: $[[{JSON}{ticket}{number}]] as variable extracted. And other one as sys_id: $[[{JSON}{ticket}{sys_id}]]"/><END value="Resolved"/></DO></AUTO>');
INSERT INTO autoBot (idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active, autoBotXML) VALUES ('0OOh3o05EUerpuBH2fyRrSctkHiZbQFsIBj1y40B', 'TEST WINDOWS REMOTE COMMAND', 'Testing for run any Windows remote command and print results', '2018-02-18 00:02:12', '1', '1', '<AUTO><ON><VAR name="number" compare="exists"/><VAR name="sys_id" compare="exists"/><VAR name="subject" compare="eq" value="TEST WINDOWS REMOTE COMMAND"/><VAR name="state" compare="exists"/><VAR name="remoteHost" compare="exists"/><VAR name="remoteUser" compare="exists"/><VAR name="remotePasswd" compare="exists"/><VAR name="remoteDomain" compare="exists"/><VAR name="remoteCommand" compare="exists"/></ON><DO><execRemoteWindowsCommand catchVarName="results" remoteHost="${remoteHost}" remoteUser="${remoteUser}" passwd="${remotePasswd}" domain="${remoteDomain}" command="${remoteCommand}" useKerberos="yes"/><LOGING comment="results of the command execution: ${results}"/><END value="Resolved"/></DO></AUTO>');


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
	log text NULL
) ENGINE=InnoDB;





