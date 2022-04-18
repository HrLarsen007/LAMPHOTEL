#!/bin/bash

#Installation of LAMP with docker

## Defining color codes for text
green="\033[32m"
yellow="\u001b[33m"
red="\033[31m"
white="\e[0;37m"
default="\033[00m"

## Gathering information about our OS system
_my_version=$(awk -F'=' '/VERSION_ID/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_name=$(awk -F'=' '/NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_prettyname=$(awk -F'=' '/PRETTY_NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_id=$(awk -F'=' '/ID/{ gsub(/"/,""); print $2}' /etc/os-release)

my_version=${_my_version::1}
my_prettyname=$_my_prettyname
my_id=$(echo $_my_id | awk '{print $1}')
my_ip=`hostname -I`

## Database info
server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
localuser="wpuser"
remoteuser="hemliguser"
database="wpdatabase"
table="wp_"

remotepass=""
localpass=""

mysqlIP=""

## Defining a variable to be used instead of yum or apt-get.
yap="none"

## Checking if the user's OS system is supported by our script.
if (( $my_id == "centos" )) ; then

	if (( $my_version == '7' )) ; then
		echo -e "$green [+] We are using an acceptable version of centos to use this script! $default"
	else 
		echo -e "$red [-] This script only supports version 7.x centos $default"
		exit 0
	fi
else 
	echo -e "$red [-] This script does not support $my_prettyname $default"
	exit 0
fi

## Declaring our yap variable's value to be compatiable with the OS we are running
echo -e "$green [+] Checking your OS compatibility $default"
if [ -e "/etc/yum" ] ; then
	yap="yum"
elif [ -e "/etc/apt" ]; then
	yap="apt-get"
else 
	echo -e "$red [-] You'r OS is not supported by this script, exiting the script"
	exit 0
fi

echo -e "$green [+] Setting up LAMP-HOTEL with $my_prettyname dependcies $default"
sudo $yap -y update ; $yap -y upgrade ; $yap -y clean all
sudo $yap install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo $yap -y install docker
sudo $yap -y install docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo docker pull centos

sudo docker run -it centos --name ApachePHP
sudo $yap -y update ; $yap -y upgrade ; $yap -y clean all
sudo $yap install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo $yap install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo $yap install -y yum-utils
sudo $yap install -y httpd
sudo yum-config-manager --enable remi-php56
sudo $yap -y install php-mcrypt php-cli php-gd php-curl php-ldap php-zip php-fileinfo php-fpm php-xml
sudo $yap -y install php-mysqlnd php-mbstring php-pdo php-opcache php-common
sudo $yap -y install bind bind-utils 
sudo $yap -y install nano wget net-tools varnish rsync dialog
sudo $yap -y install perl perl-Net-SSLeay unzip perl-Encode-Detect perl-Data-Dumper
sudo $yap -y install fail2ban fail2ban-systemd postfix dovecot

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --zone=public --add-port=10000/tcp ##Webmin
sudo firewall-cmd --permanent --zone=public --add-port=10100-10200/tcp ## Passive Ports 
sudo firewall-cmd --reload

sudo $yap update ; $yap upgrade

sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl start varnish.service
sudo systemctl enable varnish.service
sudo systemctl start fail2ban
sudo systemctl enable fail2ban 
sudo systemctl start named
sudo systemctl enable named

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
sudo $yap update -y selinux-policy*
sudo $yap -y update ; $yap -y upgrade 
sudo rpm --import jcameron-key.asc
sudo $yap -y install webmin

wget $wp_source
tar xpvf latest.tar.gz


sudo rsync -avP wordpress/ $server_root

rm -rf latest.tar.gz
rm -rf wordpress

sudo chown apache:apache $server_root/* -R 
mv $server_root/index.html $server_root/index.html.orig

sudo cp $server_root/wp-config-sample.php $server_root/wp-config.php
sudo sed -i "s/database_name_here/$database/g" $server_root/wp-config.php
sudo sed -i "s/username_here/$remoteuser/g" $server_root/wp-config.php
sudo sed -i "s/password_here/$remotepass/g" $server_root/wp-config.php
sudo sed -i "s/localhost/$mysqlIP/g" $server_root/wp-config.php
sudo sed -i "s/wp_/$table/g" $server_root/wp-config.php
exit

sudo docker run -it centos --name MySQL
sudo $yap -y update ; $yap -y upgrade ; $yap -y clean all
sudo $yap install -y yum-utils
sudo $yap install -y mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp 
sudo firewall-cmd --reload
sudo mysql_secure_installation
localpass=$( dialog --stdout --inputbox "Type $localuser@localhost password" 0 0 )
remotepass=$( dialog --stdout --inputbox "Type $remoteuser password" 0 0 )
echo -e "$green [+] Type MySQL root password $default"

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
