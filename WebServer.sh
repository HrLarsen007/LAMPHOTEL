#!bin/bash
## Webserver Opsætnings Script
## CentOS 7 / YUM

server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
remoteuser="dorte@webhoteldb"
remotepass="Kode1234!"
database="dbwebhotel"
table="wp_"
host="webhoteldb.mariadb.database.azure.com"

sudo -i

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils
sudo yum -y install epel-release
sudo yum repolist

sudo yum module -y reset php
sudo yum-config-manager --disable 'remi-php*'
sudo yum-config-manager --enable remi-php81
sudo yum -y update ; yum -y upgrade ; yum clean all

sudo yum -y install php
sudo yum -y install php-mcrypt php-cli php-gd php-curl php-ldap php-zip php-fileinfo php-fpm php-xml
sudo yum -y install php-mysqlnd php-mbstring php-pdo php-opcache php-common
sudo yum -y install php-{devel,pear,bcmath,json,redis,memcache}
sudo yum -y install httpd bind bind-utils
sudo yum -y install perl perl-Net-SSLeay unzip perl-Encode-Detect perl-Data-Dumper

sudo yum -y install nano mc net-tools wget varnish
sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install fail2ban fail2ban-systemd postfix dovecot

sudo yum -y install vsftpd openssl
sudo yum -y install mod_ssl

sudo touch /etc/yum.repos.d/mariadb.repo

echo '[mariadb]' >> /etc/yum.repos.d/mariadb.repo
echo 'name = MariaDB' >> /etc/yum.repos.d/mariadb.repo
echo 'baseurl = http://yum.mariadb.org/10.3/centos73-amd64/' >> /etc/yum.repos.d/mariadb.repo
echo 'gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB' >> /etc/yum.repos.d/mariadb.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/mariadb.repo

sudo yum -y install MariaDB-client

sudo systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start named.service
sudo systemctl enable named.serivce
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl start varnish.service
sudo systemctl enable varnish.service
sudo yum -y update ; yum -y upgrade ; yum clean all

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


sudo firewall-cmd --permanent --zone=public --add-service=http  ##Apache
sudo firewall-cmd --permanent --zone=public --add-service=https ##Secure Apache
sudo firewall-cmd --permanent --zone=public --add-service=ftp ## FTP Service
sudo firewall-cmd --permanent --zone=public --add-port=10000/tcp ##Webmin
sudo firewall-cmd --permanent --zone=public --add-port=10100-10200/tcp ## Passive Ports 
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp
sudo firewall-cmd --permanent --zone=public --add-port=22/tcp ## SSH
sudo firewall-cmd --reload

sudo systemctl restart httpd.service
sudo yum update -y selinux-policy*
setsebool -P httpd_can_network_connect_db on
setsebool -P httpd_can_network_connect on
#setsebool -P httpd_enable_ftp_server on

wget $wp_source
tar xpvf latest.tar.gz
sudo rsync -avP wordpress/ $server_root
rm -rf latest.tar.gz
rm -rf wordpress
sudo chown apache:apache $server_root/* -R 
mv $server_root/index.html $server_root/index.html.orig


Q1="CREATE DATABASE $database;"
SQL=${Q1}
mysql -u $remoteuser -h $host --ssl --password=Kode1234! -e "$SQL"

sudo cp $server_root/wp-config-sample.php $server_root/wp-config.php
sudo sed -i "s/database_name_here/$database/g" $server_root/wp-config.php
sudo sed -i "s/username_here/$remoteuser/g" $server_root/wp-config.php
sudo sed -i "s/password_here/$remotepass/g" $server_root/wp-config.php
sudo sed -i "s/wp_/$table/g" $server_root/wp-config.php
sudo sed -i "s/localhost/$host/g" $server_root/wp-config.php
sudo sed -i '/Add any custom values between this line and the.*/a define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL);' /var/www/html/wp-config.php
sudo yum -y update ; yum -y upgrade ; yum clean all
sudo systemctl restart httpd.service


sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
systemctl restart sshd

sudo openssl req -newkey rsa:2048 -nodes -keyout /etc/pki/tls/private/vsftpd.key -x509 -days 365 -out /etc/pki/tls/certs/vsftpd.crt


## nano /etc/httpd/conf.d/ssl.conf
## DocumentRoot "/var/www/html"
## ServerName publicIP:443
## SSLCertificateFile /etc/pki/tls/certs/vsftpd.crt
## SSLCertificateKeyFile /etc/pki/tls/private/vsftpd.key

mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_orig
touch /etc/vsftpd/vsftpd.conf
echo 'anonymous_enable=NO' >> /etc/vsftpd/vsftpd.conf
echo 'local_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'write_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'local_umask=022' >> /etc/vsftpd/vsftpd.conf
echo 'dirmessage_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'xferlog_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'connect_from_port_20=YES' >> /etc/vsftpd/vsftpd.conf
echo 'xferlog_std_format=YES' >> /etc/vsftpd/vsftpd.conf
echo 'listen=YES' >> /etc/vsftpd/vsftpd.conf
echo 'listen_ipv6=NO' >> /etc/vsftpd/vsftpd.conf
echo 'pam_service_name=vsftpd' >> /etc/vsftpd/vsftpd.conf
echo 'userlist_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'rsa_cert_file=/etc/pki/tls/certs/vsftpd.crt' >> /etc/vsftpd/vsftpd.conf
echo 'rsa_private_key_file=/etc/pki/tls/private/vsftpd.key' >> /etc/vsftpd/vsftpd.conf
echo 'ssl_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'force_local_data_ssl=YES' >> /etc/vsftpd/vsftpd.conf
echo 'force_local_logins_ssl=YES' >> /etc/vsftpd/vsftpd.conf
echo 'ssl_tlsv1=YES' >> /etc/vsftpd/vsftpd.conf
echo 'ssl_sslv2=NO' >> /etc/vsftpd/vsftpd.conf
echo 'ssl_sslv3=NO' >> /etc/vsftpd/vsftpd.conf
echo 'require_ssl_reuse=NO' >> /etc/vsftpd/vsftpd.conf
echo 'ssl_ciphers=HIGH' >> /etc/vsftpd/vsftpd.conf
echo 'pasv_enable=YES' >> /etc/vsftpd/vsftpd.conf
echo 'pasv_min_port=10100' >> /etc/vsftpd/vsftpd.conf
echo 'pasv_max_port=10200' >> /etc/vsftpd/vsftpd.conf
echo 'allow_anon_ssl=NO' >> /etc/vsftpd/vsftpd.conf

systemctl start vsftpd
systemctl enable vsftpd
systemctl restart vsftpd
sudo groupadd FTP
sudo adduser -d /home/ftpuser/ -s /bin/bash -g FTP ftpuser
sudo passwd ftpuser
sudo chmod 711 /home
sudo chmod 750 /home/ftpuser/
sudo chown –R ftpuser: /home/ftpuser/
