#!/bin/bash
apt-get -y update ; apt-get -y upgrade ; apt-get -y clean all

database="wpdatabase"

localuser="wpuser"
localpass="Kode1234!"
remoteuser="sshuser"
remotepass="Kode1234!"

Q1="CREATE DATABASE $database;"
Q2="CREATE USER $localuser@'localhost' IDENTIFIED BY '$localpass';"
Q3="GRANT ALL PRIVILEGES on $database.* TO $localuser@localhost;"
Q4="FLUSH PRIVILEGES;"

Q5="CREATE USER $remoteuser@'%' IDENTIFIED BY '$remotepass';"
Q6="GRANT ALL PRIVILEGES ON $database.* TO $remoteuser@'%' WITH GRANT OPTION;"
Q7="FLUSH PRIVILEGES;"

SQL=${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}
mysql -u root -p -e "$SQL"

