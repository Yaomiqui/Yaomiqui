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

yum install -y wget vim net-tools httpd perl perl-core perl-CGI perl-DBI mod_ssl perl-JSON perl-XML-Simple sendmail

wget -c http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm

rpm -ivh mysql-community-release-el7-5.noarch.rpm

yum install -y mysql-server perl-DBD-MySQL epel-release

yum --enablerepo=epel install -y sshpass perl-Parallel-ForkManager samba4-libs gnutls-devel perl-Net-OpenSSH perl-IO-Pty-Easy perl-MIME-Lite

### Install winexe. You can comment the next two lines to enhance performance. Then you can run it later.
# yum install -y gcc perl mingw-binutils-generic mingw-filesystem-base mingw32-binutils mingw32-cpp mingw32-crt mingw32-filesystem mingw32-gcc mingw32-headers mingw64-binutils mingw64-cpp mingw64-crt mingw64-filesystem mingw64-gcc mingw64-headers libcom_err-devel popt-devel zlib-devel zlib-static glibc-devel glibc-static python-devel git gnutls-devel libacl-devel openldap-devel rpm-build pkgconfig samba4-libs
yum remove libbsd-devel

rpm -Uvh winexe-1.1-b787d2.el7.centos.x86_64.rpm
###### 

chown apache:apache /usr/share/httpd

# service NetworkManager stop

# chkconfig NetworkManager off

service firewalld stop

chkconfig firewalld off

service httpd start

service mysqld start

chkconfig httpd on

chkconfig mysqld on

perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

setenforce 0

perl -pi -e 's/Listen 80/Listen 80\nListen 443\n\nTimeout 1200\nLimitRequestLine 100000\nLimitRequestFieldSize 100000/' /etc/httpd/conf/httpd.conf

mkdir /var/www/yaomiqui

mkdir /var/www/yaomiqui/html

mkdir /var/www/yaomiqui/keys

mkdir /var/www/yaomiqui/certs

mkdir /var/www/yaomiqui/logs

perl -pi -e "s/SERVER_NAME/${COMMON_NAME}/g" yaomiqui_apache.conf

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

mysql -u root < yaomiqui.sql

cd /var/www/yaomiqui/certs

openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -keyout yaomiqui-private.key -out yaomiqui-cert.crt -subj "/C=${COUNTRY}/ST=${CITY}/L=Region/O=${REGION}/OU=${ORGANIZATION}/CN=${COMMON_NAME}"

chown -R apache:apache /var/www/yaomiqui

service httpd restart

/usr/bin/find /var/www/yaomiqui/html -name *.cgi -exec chmod 755 {} \;

/usr/bin/find /var/www/yaomiqui -name *.pl -exec chmod 755 {} \;

useradd -m -d /home/yaomiqui -g apache -s /bin/bash -k /etc/skel yaomiqui

chown yaomiqui:apache /var/www/yaomiqui/logs

crontab -u yaomiqui /var/www/yaomiqui/crontab.txt

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
echo '================================================================================'
echo ''
