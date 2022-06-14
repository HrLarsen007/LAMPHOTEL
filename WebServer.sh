#!bin/bash
## Webserver Opsætnings Script
## CentOS 7 / YUM

server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
localuser="wpuser"
remoteuser="hemliguser"
database="wpdatabase"
table="wp_"
host="127.0.0.1"

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils
sudo yum -y install epel-release
sudo yum repolist

sudo yum module -y reset php
sudo yum module -y install php:remi-8.1
sudo yum -y update ; yum -y upgrade ; yum clean all

sudo yum -y install php
sudo yum -y install php-mcrypt php-cli php-gd php-curl php-ldap php-zip php-fileinfo php-fpm php-xml
sudo yum -y install php-mysqlnd php-mbstring php-pdo php-opcache php-common
sudo yum -y install httpd bind bind-utils
sudo yum -y install perl perl-Net-SSLeay unzip perl-Encode-Detect perl-Data-Dumper
##sudo yum -y install mariadb-server mariadb
sudo yum -y install nano mc net-tools wget varnish
sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install fail2ban fail2ban-systemd postfix dovecot

sudo systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start named.service
sudo systemctl enable named.serivce
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl start varnish.service
sudo systemctl enable varnish.service

##Setting up a php test site
touch /var/www/html/phpinfo.php && echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php 

##Setting up Webmin repo information
touch /etc/yum.repos.d/webmin.repo && 
echo '[Webmin]' >> /etc/yum.repos.d/webmin.repo
echo 'name=Webmin Distribution Neutral' >> /etc/yum.repos.d/webmin.repo
echo '#baseurl=https://download.webmin.com/download/yum' >> /etc/yum.repos.d/webmin.repo
echo 'mirrorlist=https://download.webmin.com/download/yum/mirrorlist' >> /etc/yum.repos.d/webmin.repo
echo 'enabled=1' >> /etc/yum.repos.d/webmin.repo
echo 'gpgkey=https://download.webmin.com/jcameron-key.asc' >> /etc/yum.repos.d/webmin.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/webmin.repo

sudo wget https://download.webmin.com/jcameron-key.asc
sudo yum -y update ; $yap -y upgrade 
sudo rpm --import jcameron-key.asc
sudo yum -y install webmin


echo -e "$green [+] Updating the firewall rule set to allow services $default"
sudo firewall-cmd --permanent --zone=public --add-service=smtp ## Mail Service
sudo firewall-cmd --permanent --zone=public --add-service=http  ##Apache
sudo firewall-cmd --permanent --zone=public --add-service=https ##Secure Apache
sudo firewall-cmd --permanent --zone=public --add-port=10000/tcp ##Webmin
sudo firewall-cmd --permanent --zone=public --add-port=10100-10200/tcp ## Passive Ports 
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp
sudo firewall-cmd --reload

sudo systemctl restart httpd.service
sudo yum update -y selinux-policy*
setsebool -P httpd_can_network_connect_db on

wget $wp_source
tar xpvf latest.tar.gz
sudo rsync -avP wordpress/ $server_root
rm -rf latest.tar.gz
rm -rf wordpress
sudo chown apache:apache $server_root/* -R 
mv $server_root/index.html $server_root/index.html.orig

sudo cp $server_root/wp-config-sample.php $server_root/wp-config.php
sudo sed -i "s/database_name_here/$database/g" $server_root/wp-config.php
sudo sed -i "s/username_here/$localuser/g" $server_root/wp-config.php
sudo sed -i "s/password_here/$localpass/g" $server_root/wp-config.php
sudo sed -i "s/wp_/$table/g" $server_root/wp-config.
sudo sed -i "s/localhost/$host/g" $server_root/wp-config.php