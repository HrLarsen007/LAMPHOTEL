#!/bin/bash


## Docker infomation
MySQLDBDocker="MariaDB"
MySQLIP=""
ApachePHPDocker="ApachePHP"
ApacheIP=""

## DB information
server_root="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
localuser="wpuser"
remoteuser="maria"
database="wpdatabase"
table="wp_"

remotepass=""
localpass=""

: <<'END'
## Installing Docker packages on the system
sudo yum -y update ; yum -y upgrade ; yum -y clean all
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker
sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo docker pull centos
END


## Installing a MariaDB the centos image
sudo  run -d -t --name $MySQLDBDocker centos /bin/bash -c '
    sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-*
    sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*
    yum -y update ; yum -y upgrade ; yum -y clean all
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    yum install -y http://rpms.remirepo.net/enterprise/remi-release-8.rpm
    yum install -y yum-utils
    yum install -y epel-release
    yim install -y git
    cd /
    git clone https://github.com/hrlarsen007/LAMPHOTEL.git
    sh LAMPHOTEL/DockerDB.sh

'
#sudo docker exec -it $MySQLDBDocker bash


#MySQLIP=`docker exec -it $MySQLDBDocker hostname -I`
