#!/bin/bash



sudo yum -y update ; yum -y upgrade ; yum -y clean all
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker
sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo docker pull centos

sudo docker run -it centos --name ApachePHP
sudo yum -y update ; yum -y upgrade ; yum -y clean all
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum install -y yum-utils
sudo yum install -y httpd