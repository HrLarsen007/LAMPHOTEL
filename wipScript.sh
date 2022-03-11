#!/bin/bash
## Installing LAMP STACK



my_version=$(awk -F'=' '/VERSION_ID/{ gsub(/"/,""); print $2}' /etc/os-release)
my_name=$(awk -F'=' '/NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
my_prettyname=$(awk -F'=' '/PRETTY_NAME/{ gsub(/"/,""); print $2}' /etc/os-release)
my_id=$(awk -F'=' '/ID/{ gsub(/"/,""); print $2}' /etc/os-release)


echo $my_id
echo $my_version
echo $my_name
echo $my_prettyname


if [ ${my_id} = "rhel" ] ; then

	if [ ${my_version::1} != '7' || ${my_version::1} != '8' ] ; then
		echo "This script only supports version 7.x or 8.x of rhel"
		exit 0
	fi
el 
	echo "This script only supports $my_name"
	exit 0
fi

echo "Setting up LAMP-STACK with $my_prettyname dependcies"

: <<'END'

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${my_version::1}.noarch.rpm
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-${my_version::1}.rpm
sudo yum -y install yum-utils
sudo subscription-manager repos --enable "codeready-builder-for-rhel-${my_version::1}-*-rpms"
## sudo subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms
sudo yum-config-manager --enable remi-php56  # [Install PHP 5.6]

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-xml php-fpm
sudo yum -y install httpd bind bind-utils mariadb-server mariadb nano mc net-tools wget varnish 
sudo yum -y install mariadb-server mariadb
sudo yum -y install	mc net-tools
sudo yum -y install	nano wgt varnish
sudo yum -y install epel-release ; yum -y update ; yum -y upgrade 
sudo yum -y install fail2ban fail2ban-systemd postfix dovecot system-switch-mail system-switch-mail-gnome

sudo systemctl enable fail2ban
sudo systemctl start fail2ban 
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
