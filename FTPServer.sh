#!bin/bash

sudo yum -y update ; yum -y upgrade ; yum clean all
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm

sudo yum -y install fail2ban fail2ban-systemd postfix dovecot
sudo yum -y install nano wget net-tools varnish rsync dialog
sudo yum -y install perl perl-Net-SSLeay unzip perl-Encode-Detect perl-Data-Dumper
sudo yum -y install epel-release
sudo yum -y install yum-utils
sudo yum -y install vsftpd openssl

sudo firewall-cmd --permanent --zone=public --add-service=ftp ## FTP Service
sudo firewall-cmd --permanent --zone=public --add-port=10100-10200/tcp ## Passive Ports (vsftpd)
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp ## DNS
sudo firewall-cmd --reload

sudo yum -y update ; yum -y upgrade ; yum clean all


sudo openssl req -newkey rsa:2048 -nodes -keyout /etc/pki/tls/private/vsftpd.key -x509 -days 365 -out /etc/pki/tls/certs/vsftpd.crt
mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_orig
touch /etc/vsftpd/vsftpd.conf
echo 'anonymous_enable=YES' >> /etc/vsftpd/vsftpd.conf
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
echo 'allow_anon_ssl=YES' >> /etc/vsftpd/vsftpd.conf

systemctl start vsftpd
systemctl enable vsftpd
systemctl restart vsftpd
sudo groupadd FTP
sudo adduser -d /home/ftpuser/ -s /bin/bash -g FTP ftpuser
sudo passwd ftpuser
sudo chmod 701 /home
sudo chmod 750 /home/ftpuser/