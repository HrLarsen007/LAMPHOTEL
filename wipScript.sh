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

		echo "Correct Version"
	else 
		echo "This script only supports version 7.x or 8.x of rhel"
		exit 0
	fi
else 
	echo "This script does not support $my_prettyname"
	exit 0
fi



echo "Setting up LAMP-STACK with $my_prettyname dependcies \n"
sudo yum update ; yum upgrade ; yum clean all
echo "Installing epel \n"
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$my_version.noarch.rpm  
echo "Installing remi \n"
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-$my_version.rpm   
sudo yum update
sudo yum repolist
sudo yum -y install yum-utils
sudo yum module -y reset php
echo "Installing php 5.6 \n"
sudo yum module -y install php:remi-5.6
echo "Installing php mariadb  \n"
sudo yum --enablerepo=remi -y install php httpd mariadb-server mariadb

sudo yum update ; yum upgrade
echo "Installing dependencies \n"
sudo yum --enablerepo=remi -y install php-mcrypt php-cli php-gd php-curl php-mysql php-1dap php-zip php-fileinfo php-fpm php-xml
sudo yum --enablerepo=remi -y install bind bind-utils 
sudo yum --enablerepo=remi -y install epel-release
sudo yum --enablerepo=remi -y install nano wget net-tools varnish
sudo yum --enablerepo=remi -y install fail2ban fail2ban-systemd postfix dovecot system-switch-mail system-switch-mail-gnome

sudo yum update ; yum upgrade
echo "Starting services \n"
sudo systemctl start fail2ban
sudo systemctl enable fail2ban 
sudo systemctl start named.service
sudo systemctl enable named.serivce
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
sudo systemctl start varnish.service
sudo systemctl enable varnish.service

echo "Installing up MYSQL \n"
sudo mysql_secure_installation



















: <<'END'
sudo yum -y update ; yum -y upgrade ; yum clean all

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$my_version.noarch.rpm
sudo yum repolist
sudo yum -y update
sudo subscription-manager repos --enable "codeready-builder-for-rhel-$my_version-*-rpms"
sudo yum repolist
sudo yum -y update
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-$my_version.rpm


sudo yum -y install yum-utils
#sudo subscription-manager repos --enable "codeready-builder-for-rhel-$my_version-*-rpms"
sudo yum-config-manager --enable remi-php56  # [Install PHP 5.6]
sudo yum --enablerepo=remi install php-xxx

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-xml php-fpm
sudo yum -y install httpd bind bind-utils
sudo yum -y install mariadb-server mariadb
sudo yum -y install	mc net-tools
sudo yum -y install	nano wget varnish
sudo yum -y install epel-release ; yum -y update ; yum -y upgrade
sudo yum -y install fail2ban fail2ban-systemd postfix dovecot system-switch-mail system-switch-mail-gnome

sudo systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start named.service
sudo systemctl enable named.serivce
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
sudo systemctl start varnish.service
sudo systemctl enable varnish.service

sudo mysql_secure_installation
END