yum install vsftpd
service vsftpd start
chkconfig vsftpd on
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
echo 'allow_anon_ssl=YES' >> /etc/vsftpd/vsftpd.conf