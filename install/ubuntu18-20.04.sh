#!/bin/bash
########################################################################
# Yaomiqui is Powerful tool for Automation + Easy to use Web UI
# Written in freestyle Perl + CGI + Apache + MySQL + Javascript + CSS
# Automated installation script for Yaomiqui 1.0 on Ubuntu 18.04
# and Ubuntu 20.04 Server
# 
# Yaomiqui and its logo are registered trademark by Hugo Maza Moreno
# Copyright (C) 2019
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

ps -efa | grep apt | grep -v grep | awk '{print "kill -9 "$2}' | sh

source ./keys_auto.conf

apt-get update

apt install -y curl apache2 mariadb-server sshpass libnet-openssh-perl libdbi-perl libdbd-mysql-perl libjson-perl libtest-json-perl libxml-simple-perl libxml-validate-perl libparallel-forkmanager-perl libnet-openssh-perl sendmail libmime-lite-perl libmath-random-isaac-perl libdate-calc-perl realmd krb5-kdc krb5-pkinit krb5-sync-tools krb5-user libmail-imapclient-perl

/usr/bin/perl -pi -e 's/Timeout 300/Timeout 1200\nLimitRequestLine 100000\nLimitRequestFieldSize 100000/' /etc/apache2/apache2.conf

a2enmod ssl

a2enmod cgi

mkdir /var/www/yaomiqui

mkdir /var/www/yaomiqui/html

mkdir /var/www/yaomiqui/keys

mkdir /var/www/yaomiqui/certs

mkdir /var/www/yaomiqui/logs

mkdir -p /var/lib/yaomiqui/tmp

/usr/bin/perl -pi -e "s/SERVER_NAME/${COMMON_NAME}/g" yaomiqui_apache.conf

cat ./yaomiqui_apache.conf > /etc/apache2/sites-available/yaomiqui.conf

mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bk

cp -r ../html/* /var/www/yaomiqui/html/

cp -r ../root/* /var/www/yaomiqui/

chown -R www-data:www-data /var/www/yaomiqui

chown -R www-data:www-data /var/lib/yaomiqui

mysqlPasswdAdmin=`./generateEncKey.pl 12`

/usr/bin/perl -pi -e "s/DBPASSWD/DBPASSWD \= ${mysqlPasswdAdmin}/g" /var/www/yaomiqui/yaomiqui.conf

/usr/bin/perl -pi -e "s/MYSQL_PASSWD/${mysqlPasswdAdmin}/g" yaomiqui.sql

encKey=`./generateEncKey.pl`;
echo "${encKey}" > /var/www/yaomiqui/certs/yaomiquikey.enc

encPasswd=`./cryptPasswdAdmin.pl admin`

/usr/bin/perl -pi -e "s/ADMIN_PASSWD/${encPasswd}/" yaomiqui.sql

mysql -u root < yaomiqui.sql

cd /var/www/yaomiqui/certs

openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -keyout yaomiqui-private.key -out yaomiqui-cert.crt -subj "/C=${COUNTRY}/ST=${CITY}/L=Region/O=${REGION}/OU=${ORGANIZATION}/CN=${COMMON_NAME}"

chown -R www-data:www-data /var/www/yaomiqui

service apache2 restart

cd /etc/apache2/sites-available

a2ensite yaomiqui.conf

service apache2 restart

/usr/bin/find /var/www/yaomiqui -name *.cgi -exec chmod 755 {} \;

/usr/bin/find /var/www/yaomiqui -name *.pl -exec chmod 755 {} \;

chmod 755 /var/www/yaomiqui/*.sh

crontab /var/www/yaomiqui/crontab.txt

echo ''
echo '================================================================================'
echo 'If there was some problem with SQL execution'
echo 'Please enter to MySQL as root and run:'
echo 'SQL> source yaomiqui.sql;'
echo '================================================================================'
echo ''
echo '================================================================================'
echo 'You can now pointing to your URL instance with SSL:'
echo 'https://[FQDN or IP]'
echo 'User and password default: admin/admin. You should change password immediately'
echo '================================================================================'
echo ''
