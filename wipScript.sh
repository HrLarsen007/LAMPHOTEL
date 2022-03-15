#!/bin/bash
## Installing LAMP STACK



_my_version=$(awk -F'=' '/VERSION_ID/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_name=$(awk -F'=' '/NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_prettyname=$(awk -F'=' '/PRETTY_NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_id=$(awk -F'=' '/ID/{ gsub(/"/,""); print $2}' /etc/os-release)

my_version=${_my_version::1}
my_prettyname=$_my_prettyname
my_id=$(echo $_my_id | awk '{print $1}')

green="\033[32m"
red="\033[31m"
white="\e[0;37m"
default="\033[00m"



if (( $my_id == "rhel" )) ; then

	if (( $my_version == '7' || $my_version == '8' )) ; then
		echo -e "$green [+] We are using an acceptable version of Rhel to use this script! $default"
	else 
		echo -e "$red [-] This script only supports version 7.x or 8.x of rhel $default"
		exit 0
	fi
else 
	echo -e "$red [-] This script does not support $my_prettyname ' $default"
	exit 0
fi



echo "\nSetting up LAMP-STACK with $my_prettyname dependcies\n"
sudo yum update ; yum upgrade ; yum clean all
echo -e "$green [+] Installing epel $default"
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$my_version.noarch.rpm  
echo -e "$green [+] Installing remi $default"
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-$my_version.rpm   
sudo yum -y update
sudo yum repolist
sudo yum -y install yum-utils
sudo yum module -y reset php
sudo yum module -y install php:remi-8.1
sudo yum -y update
#echo -e "$green [+] Installing remi's php5.6 $default"
#sudo yum-config-manager -y --enable remi-php56  # [Install PHP 5.6]


echo -e "$green [+] Installing php http mariadb $default"
sudo yum --enablerepo=remi -y install php httpd mariadb-server mariadb

sudo yum -y update ; yum -y upgrade

echo -e "$green [+] Installing dependencies $default"
sudo yum --enablerepo=remi -y install php-mcrypt php-cli php-gd php-curl php-1dap php-zip php-fileinfo php-fpm php-xml
sudo yum --enablerepo=remi -y install php-mysqlnd php-mbstring php-pdo php-opcache php-common
sudo yum --enablerepo=remi -y install bind bind-utils 
sudo yum --enablerepo=remi -y install epel-release
sudo yum --enablerepo=remi -y install nano wget net-tools varnish rsync
sudo yum --enablerepo=remi -y install fail2ban fail2ban-systemd postfix dovecot 

## TODO system-switch-mail system-switch-mail-gnome

sudo yum update ; yum upgrade
echo -e "$green [+] Starting services ' $default"

sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
sudo systemctl start varnish.service
sudo systemctl enable varnish.service
sudo systemctl start fail2ban
sudo systemctl enable fail2ban 
sudo systemctl start named
sudo systemctl enable named

#sudo systemctl status fail2ban
#sudo systemctl status named.service
#sudo systemctl status mariadb.service
#sudo systemctl status varnish.service
#sudo systemctl status httpd.service

echo -e "$green [+] Installing MySQL $default"
sudo mysql_secure_installation

touch /var/www/html/phpinfo.php && echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php 

touch /etc/yum.repos.d/webmin.repo && 
echo '[Webmin]' >> /etc/yum.repos.d/webmin.repo
echo 'name=Webmin Distribution Neutral' >> /etc/yum.repos.d/webmin.repo
echo '#baseurl=https://download.webmin.com/download/yum' >> /etc/yum.repos.d/webmin.repo
echo 'mirrorlist=https://download.webmin.com/download/yum/mirrorlist' >> /etc/yum.repos.d/webmin.repo
echo 'enabled=1' >> /etc/yum.repos.d/webmin.repo
echo 'gpgkey=https://download.webmin.com/jcameron-key.asc' >> /etc/yum.repos.d/webmin.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/webmin.repo

sudo wget https://download.webmin.com/jcameron-key.asc
sudo yum -y update ; yum -y upgrade 
sudo rpm --import jcameron-key.asc
sudo yum -y install webmin

## Mail server
systemctl stop sendmail
systemctl disable  sendmail 
sudo yum -y remove sendmail*

chkconfig --level 345 dovecot on

sudo yum -y install postfix

systemctl start postfix
systemctl enable postfix

chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

sudo firewall-cmd --permanent --zone=public --add-service=smtp
sudo firewall-cmd --permanent --zone=public --add-service=http 
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --permanent --zone=public --add-port=10000/tcp 
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp

sudo firewall-cmd --reload

sudo systemctl restart httpd.service

yum update -y selinux-policy*

sudo yum -y install dialog wget


# Starting script
server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
user="wpuser"
database="wpdatabase"
table="wp_"

# Setting up variables
dialog --title "Setting variables" --yesno "Use $server_root as server root?" 0 0
if [ "$?" = "1" ] ; then
	server_root=$( dialog --stdout --inputbox "Set server root:" 0 0 )
fi

dialog --title "Setting variables" --yesno "Set $database as WordPress Database?" 0 0
if [ "$?" = "1" ] ; then
	database=$( dialog --stdout --inputbox "Set WordPress DB name:" 0 0 )
fi

dialog --title "Setting variables" --yesno "Set $table as WordPress table prefix?" 0 0
if [ "$?" = "1" ] ; then
	table=$( dialog --stdout --inputbox "Set WordPress table prefix:" 0 0 )
fi

dialog --title "Setting variables" --yesno "Use $user as WordPress database username?" 0 0
if [ "$?" = "1" ] ; then
	user=$( dialog --stdout --inputbox "Set WordPress username:" 0 0 )
fi

dialog --title "setting variables" --msgbox \
"[Server Root] = $server_root \
[Database name] = $database \
[Table prefix] = $table \
[MySQL Username] = $user" 10 35 --and-widget


# Installing and configuring dependencies according to each distro's package manager
echo -e "$green [+] Installing and configuring dependencies $default"

sudo yum install httpd php php-gd php-mysql php-xml mariadb-server mariadb
sudo systemctl start mariadb
sudo systemctl start httpd
sudo systemctl enable mariadb
sudo systemctl enable httpd

# Downloading source
echo -e "$green [+] Downloading Wordpress$default"
wget $wp_source
echo -e "$green [+] Unpacking Wordpress$default"
tar xpvf latest.tar.gz

# Copying files to server root
echo -e "$green [+] Copying files to $server_root $default"
sudo rsync -avP wordpress/ $server_root


#Cleaning up after myslef, since my mom isn't here!
rm -rf latest.tar.gz
rm -rf wordpress

# Setting up permissions
echo -e "$green [+] Changing permissions$default"
if [ -e "/etc/yum" ] ; then
	sudo chown apache:apache $server_root/* -R 
fi
mv $server_root/index.html $server_root/index.html.orig

# Configuring MySQL Database
pass=$( dialog --stdout --inputbox "Type $user@localhost password" 0 0 )
echo -e "$green [+] Type MySQL root password $default"


Q1="CREATE DATABASE $database;"
Q2="CREATE USER $user@localhost;"
Q3="SET PASSWORD FOR $user@localhost= PASSWORD('$pass');"
Q4="GRANT ALL PRIVILEGES on $database.* TO $user@localhost;"
Q5="FLUSH PRIVILEGES;"
SQL=${Q1}${Q2}${Q3}${Q4}${Q5}

`mysql -u root -p -e "$SQL"`

# Generating wp-config.php file
sudo cp $server_root/wp-config-sample.php $server_root/wp-config.php
sudo sed -i "s/database_name_here/$database/g" $server_root/wp-config.php
sudo sed -i "s/username_here/$user/g" $server_root/wp-config.php
sudo sed -i "s/password_here/$pass/g" $server_root/wp-config.php
sudo sed -i "s/wp_/$table/g" $server_root/wp-config.php

echo -e "$green [+] Finishing / End of the script' $default"