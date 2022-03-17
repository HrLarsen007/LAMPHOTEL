#!/bin/bash
## Installing LAMP STACK

_my_version=$(awk -F'=' '/VERSION_ID/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_name=$(awk -F'=' '/NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_prettyname=$(awk -F'=' '/PRETTY_NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
_my_id=$(awk -F'=' '/ID/{ gsub(/"/,""); print $2}' /etc/os-release)

my_version=${_my_version::1}
my_prettyname=$_my_prettyname
my_id=$(echo $_my_id | awk '{print $1}')
my_ip=`hostname -I`

green="\033[32m"
yellow="\u001b[33m"
red="\033[31m"
white="\e[0;37m"
default="\033[00m"

yap="none"


echo -e "\033[33;5;7;1mLAMPSTACK\033[0m"


# Variables -  wordpress Database + wordpress source
server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
localuser="wpuser"
remoteuser="hemliguser"
database="wpdatabase"
table="wp_"

echo -e "$green [+] Checking your OS compatibility $default"
if [ -e "/etc/yum" ] ; then
	yap="yum"
elif [ -e "/etc/yum" ]; then
	yap="apt-get"
else 
	echo -e "$red [-] You'r OS is not supported by this script, exiting the script"
	exit 0
fi

if (( $my_id == "rhel" )) ; then

	if (( $my_version == '7' || $my_version == '8' )) ; then
		echo -e "$green [+] We are using an acceptable version of Rhel to use this script! $default"
	else 
		echo -e "$red [-] This script only supports version 7.x or 8.x of rhel $default"
		exit 0
	fi
else 
	echo -e "$red [-] This script does not support $my_prettyname $default"
	exit 0
fi




#sudo yum-config-manager -y --enable remi-php56  # [Install PHP 5.6] Not working for EL or RHEL 8


echo -e "$green [+] Setting up LAMP-STACK with $my_prettyname dependcies $default"
echo -e "$red UPDATE at Line 65! $default"
sudo $yap update ; $yap upgrade ; $yap clean all

## TODO system-switch-mail system-switch-mail-gnome
echo -e "$green [+] Installing dependencies $default"
if [ -e "/etc/yum" ] ; then
	echo -e "$green [+] Installing epel $default"
	sudo $yap -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$my_version.noarch.rpm  
	echo -e "$green [+] Installing remi $default"
	sudo $yap -y install http://rpms.remirepo.net/enterprise/remi-release-$my_version.rpm   
	echo -e "$red UPDATE at Line 75! $default"
	sudo $yap -y update
	sudo $yap repolist
	sudo $yap -y install $yap-utils

	echo -e "$green [+] Installing remi's php8.1 $default"
	sudo $yap module -y reset php
	sudo $yap module -y install php:remi-8.1
	echo -e "$red UPDATE at Line 83! $default"
	sudo $yap -y update
	
	echo -e "$green [+] Installing php http mariadb $default"
	sudo $yap --enablerepo=remi -y install php httpd mariadb-server mariadb
	sudo $yap --enablerepo=remi -y install php-mcrypt php-cli php-gd php-curl php-ldap php-zip php-fileinfo php-fpm php-xml
	sudo $yap --enablerepo=remi -y install php-mysqlnd php-mbstring php-pdo php-opcache php-common
	sudo $yap --enablerepo=remi -y install epel-release
	echo -e "$red UPDATE at Line 91! $default"
	sudo $yap -y update ; $yap -y upgrade

elif [ -e "/etc/apt" ] ; then
	sudo $yap -y install apache2 php8.1 php8.1-gd php8.1-mysql libapache2-mod-php8.1
	sudo $yap -y install mysql-server libmysqlclient-dev
	echo -e "$red UPDATE at Line 97! $default"
	sudo $yap -y update ; $yap -y upgrade
fi
hostnamectl set-hostname mbitch 
sudo $yap --enablerepo=remi -y install bind bind-utils 
sudo $yap --enablerepo=remi -y install nano wget net-tools varnish rsync dialog
sudo $yap --enablerepo=remi -y install perl perl-Net-SSLeay openssl unzip perl-Encode-Detect perl-Data-Dumper
sudo $yap --enablerepo=remi -y install fail2ban fail2ban-systemd postfix dovecot
#Packages required for AD join!
sudo $yap --enablerepo=remi -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation authselect-compat
echo -e "$red UPDATE at Line 107! $default"
sudo $yap update ; $yap upgrade

#AD Section
sudo subscription-manager register -y
sudo subscription-manager attach --auto

realm join slapaf.slapaf -U Administrator 

echo -e "$green [+] Starting services $default"
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

echo -e "$green [+] Installing MySQL $default"
sudo mysql_secure_installation

##Setting up php test site
touch /var/www/html/phpinfo.php && echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php 

#Setting up Webmin repo information
touch /etc/yum.repos.d/webmin.repo && 
echo '[Webmin]' >> /etc/yum.repos.d/webmin.repo
echo 'name=Webmin Distribution Neutral' >> /etc/yum.repos.d/webmin.repo
echo '#baseurl=https://download.webmin.com/download/yum' >> /etc/yum.repos.d/webmin.repo
echo 'mirrorlist=https://download.webmin.com/download/yum/mirrorlist' >> /etc/yum.repos.d/webmin.repo
echo 'enabled=1' >> /etc/yum.repos.d/webmin.repo
echo 'gpgkey=https://download.webmin.com/jcameron-key.asc' >> /etc/yum.repos.d/webmin.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/webmin.repo

sudo wget https://download.webmin.com/jcameron-key.asc
echo -e "$red UPDATE at Line 137! $default"
sudo $yap -y update ; $yap -y upgrade 
sudo rpm --import jcameron-key.asc
sudo $yap -y install webmin

## Mail server
echo -e "$green [+] Installing mail system (Postfix) $default"

if [ -e "/etc/sendmail" ] ; then
	systemctl stop sendmail
	systemctl disable  sendmail 
	sudo $yap -y remove sendmail*
fi

# Installing postfix as our new mail service

chkconfig --level 345 dovecot on
sudo $yap -y install postfix

systemctl start postfix
systemctl enable postfix

##chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
##chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

## Creating firewall execptions
echo -e "$green [+] Updating the firewall rule set to allow services $default"
sudo firewall-cmd --permanent --zone=public --add-service=smtp
sudo firewall-cmd --permanent --zone=public --add-service=http 
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --permanent --zone=public --add-port=10000/tcp 
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp
sudo firewall-cmd --reload

sudo systemctl restart httpd.service
echo -e "$red UPDATE at Line 173! $default"
sudo $yap update -y selinux-policy*


dialog --title "setting variables" --msgbox \
"[Server Root] = $server_root \
[Database name] = $database \
[Table prefix] = $table \
[MySQL Local Username] = $localuser \ 
[MySQL remote Username] = $remoteuser " 10 35 --and-widget


# Installing and configuring dependencies according to each distro's package manager
echo -e "$green [+] Installing and configuring dependencies $default"

# Downloading source
echo -e "$green [+] Downloading Wordpress$default"
wget $wp_source
echo -e "$green [+] Unpacking Wordpress$default"
tar xpvf latest.tar.gz

# Copying files to server root
echo -e "$green [+] Copying files to $server_root $default"
sudo rsync -avP wordpress/ $server_root


#Cleaning up after myslef, since my mom isn't here!
echo -e "$green [+] Removing latest.tar.gz & wordpress from $server_root $default"
rm -rf latest.tar.gz
rm -rf wordpress

# Setting up permissions
echo -e "$green [+] Changing permissions$default"
if [ -e "/etc/yum" ] ; then
	sudo chown apache:apache $server_root/* -R 
elif [ -e "/etc/apt" ] ; then
	sudo chown www-data:www-data $server_root/* -R
	local_user=`whoami`
	sudo usermod -a -G www-data $local_user
fi
mv $server_root/index.html $server_root/index.html.orig

# Configuring MySQL Database
localpass=$( dialog --stdout --inputbox "Type $localuser@localhost password" 0 0 )
remotepass=$( dialog --stdout --inputbox "Type $remoteuser password" 0 0 )
echo -e "$green [+] Type MySQL root password $default"
#Creating local & remote user for the database

Q1="CREATE DATABASE $database;"
Q2="CREATE USER $localuser@'localhost' IDENTIFIED BY '$localpass';"
Q3="GRANT ALL PRIVILEGES on $database.* TO $localuser@localhost;"
Q4="FLUSH PRIVILEGES;"

Q5="CREATE USER $remoteuser@'192.168.123.%' IDENTIFIED BY '$remotepass';"
Q6="GRANT ALL PRIVILEGES ON $database.* TO $remoteuser@'192.168.123.%' WITH GRANT OPTION;"
Q7="FLUSH PRIVILEGES;"

SQL=${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}

if `mysql -u root -p -e "$SQL"` ; then
	echo -e "$green [+] Successfully added $localuser & $remoteuser into the DB $database $default"
else
	echo -e "$red [-] Invaild MySQL password $default"
	echo -e "$green [+] Type MySQL root password $default"
	`mysql -u root -p -e "$SQL"`
fi

echo -e "$green [+] Creating wp-config.php $default"
# Generating wp-config.php file
sudo cp $server_root/wp-config-sample.php $server_root/wp-config.php
sudo sed -i "s/database_name_here/$database/g" $server_root/wp-config.php
sudo sed -i "s/username_here/$localuser/g" $server_root/wp-config.php
sudo sed -i "s/password_here/$localpass/g" $server_root/wp-config.php
sudo sed -i "s/wp_/$table/g" $server_root/wp-config.php

echo -e "$green [+] Finishing / End of the script' $default"
echo -e "$green [+] You LAMP stack is now up and running! $default"
echo -e "$green [+] You access Wordpress via https://localhost/ or https://$my_ip/ $default"
echo -e "$green [+] You can access Webmin via https://localhost:10000 or https://$my_ip:10000 $default"
echo -e "\033[33;5;7;1mLAMPSTACK DONE\033[0m"