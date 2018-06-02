#!/bin/sh
########################################################################
# Yaomiqui is a Web UI for AUTOMATION
# Copyright (C) 2017  Hugo Maza M.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################

export LC_CTYPE=en_US.UTF-8

export LC_ALL=en_US.UTF-8

source ./keys_auto.conf

yum install -y wget vim net-tools httpd perl perl-core perl-CGI perl-DBI mod_ssl perl-JSON perl-XML-Simple

wget -c http://repo.mysql.com/mysql-community-release-el6-7.noarch.rpm

rpm -ivh mysql-community-release-el6-7.noarch.rpm

yum install -y mysql-server perl-DBD-MySQL epel-release

yum --enablerepo=epel install -y sshpass perl-Parallel-ForkManager

# service NetworkManager stop

# chkconfig NetworkManager off

service iptables stop

chkconfig iptables off

service httpd start

service mysqld start

chkconfig httpd on

chkconfig mysqld on

chkconfig sshd on

perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

setenforce 0

perl -pi -e 's/Listen 80/Listen 80\nListen 443\n\nTimeout 1200/' /etc/httpd/conf/httpd.conf

mkdir /var/www/yaomiqui

mkdir /var/www/yaomiqui/html

mkdir /var/www/yaomiqui/keys

mkdir /var/www/yaomiqui/certs

mkdir /var/www/yaomiqui/logs

perl -pi -e "s/SERVER_NAME/${COMMON_NAME}/g" yaomiqui_apache.conf

perl -pi -e "s/\#LoadModule/LoadModule/" yaomiqui_apache.conf

cat ./yaomiqui_apache.conf > /etc/httpd/conf.d/yaomiqui.conf

mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bk

cp -r ../html/* /var/www/yaomiqui/html/

cp -r ../tools/* /var/www/yaomiqui/

chown -R apache:apache /var/www/yaomiqui

mysqlPasswdAdmin=`./generateEncKey.pl 12`
perl -pi -e "s/DBPASSWD/DBPASSWD \= ${mysqlPasswdAdmin}/g" /var/www/yaomiqui/yaomiqui.conf
perl -pi -e "s/MYSQL_PASSWD/${mysqlPasswdAdmin}/g" yaomiqui.sql

encKey=`./generateEncKey.pl`;
echo "${encKey}" > /var/www/yaomiqui/certs/yaomiquikey.enc

encPasswd=`./cryptPasswdAdmin.pl admin`
perl -pi -e "s/ADMIN_PASSWD/${encPasswd}/" yaomiqui.sql

cd /var/www/yaomiqui/certs

openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -keyout yaomiqui-private.key -out yaomiqui-cert.crt -subj "/C=${COUNTRY}/ST=${CITY}/L=Region/O=${REGION}/OU=${ORGANIZATION}/CN=${COMMON_NAME}"

chown -R apache:apache /var/www/yaomiqui

service httpd restart

/usr/bin/find /var/www/yaomiqui/html -name *.cgi -exec chmod 755 {} \;

/usr/bin/find /var/www/yaomiqui -name *.pl -exec chmod 755 {} \;

echo ''
echo '================================================================================'
echo 'Installation finished'
echo 'Please enter to MySQL as root and run:'
echo 'SQL> source yaomiqui.sql;'
echo '================================================================================'
echo ''
echo '================================================================================'
echo 'As a last step, insert the contents of the "/var/www/yaomiqui/crontab.txt" file into the root crontab'
echo '================================================================================'
echo ''
