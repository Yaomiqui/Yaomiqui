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
	log text NULL
) ENGINE=InnoDB;





