#!/bin/bash


## Database info
server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
localuser="wpuser"
remoteuser="hemliguser"
database="wpdatabase"
table="wp_"

remotepass=""
localpass=""

sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-*
sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*

yum -y update ; yum -y upgrade ; yum -y clean all
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y http://rpms.remirepo.net/enterprise/remi-release-8.rpm
yum install -y yum-utils
yum install -y mariadb-server mariadb-client
yum install -y epel-release
yum -y update

systemctl start mariadb
systemctl enable mariadb

firewall-cmd --permanent --zone=public --add-port=3306/tcp 
firewall-cmd --reload

mysql_secure_installation

localpass=$( dialog --stdout --inputbox "Type $localuser@localhost password" 0 0 )
remotepass=$( dialog --stdout --inputbox "Type $remoteuser password" 0 0 )
Q1="CREATE DATABASE $database;"
Q2="CREATE USER $localuser@'localhost' IDENTIFIED BY '$localpass';"
Q3="GRANT ALL PRIVILEGES on $database.* TO $localuser@localhost;"
Q4="FLUSH PRIVILEGES;"

Q5="CREATE USER $remoteuser@'%' IDENTIFIED BY '$remotepass';"
Q6="GRANT ALL PRIVILEGES ON $database.* TO $remoteuser@'%' WITH GRANT OPTION;"
Q7="FLUSH PRIVILEGES;"

SQL=${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}
if `mysql -u root -p -e "$SQL"` ; then
	echo -e "$green [+] Successfully added $localuser & $remoteuser into the DB $database $default"
else
	echo -e "$red [-] Invaild MySQL password $default"
	echo -e "$green [+] Type MySQL root password $default"
	`mysql -u root -p -e "$SQL"`
fi
exit