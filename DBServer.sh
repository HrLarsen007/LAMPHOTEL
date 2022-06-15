#!bin/bash

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm  
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm

sudo yum -y install fail2ban fail2ban-systemd postfix dovecot
sudo yum -y install nano wget net-tools varnish rsync dialog
sudo yum -y install perl perl-Net-SSLeay unzip perl-Encode-Detect perl-Data-Dumper
sudo yum -y install epel-release
sudo yum -y install yum-utils
sudo yum -y install mariadb-server mariadb

sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp ## Database (mariadb)
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp ## DNS
sudo firewall-cmd --reload

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service

sudo mysql_secure_installation

Q1="CREATE DATABASE wpdatabase;"
Q2="CREATE USER wpuser@'localhost' IDENTIFIED BY 'Kode1234!';"
Q3="GRANT ALL PRIVILEGES on wpdatabase.* TO wpuser@localhost WITH GRANT OPTION;"
Q4="FLUSH PRIVILEGES;"
Q5="CREATE USER wpremote@'%' IDENTIFIED BY 'Kode1234!';"
Q6="GRANT ALL PRIVILEGES ON wpdatabase.* TO wpremote@'%' WITH GRANT OPTION;"
Q7="FLUSH PRIVILEGES;"
SQL=${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}
mysql -u root --password=Kode1234! -e "$SQL"