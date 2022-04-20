#!/bin/bash


docker network create --subnet=172.18.0.0/24 LAMP-Network 
docker run --name MariaDB -e MYSQL_ROOT_PASSWORD=Kode1234! --ip 172.18.0.100 -p 3308:3308 --network LAMP-Network -d docker.io/library/mariadb:10.3
docker exec -it MariaDB /bin/bash -c '
apt-get -y update ; apt-get -y upgrade ; apt-get -y clean all
database="wpdatabase"
table="wp_"

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

'

docker exec -it MariaDB /bin/bash -c '
apt-get -y update ; apt-get -y upgrade ; apt-get -y clean all
apt-get -y install wget ; apt-get -y install git

'