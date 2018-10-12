#!/bin/bash
function 1_ntp_configure(){
	setenforce 0
	sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
	yum -y install ntp
	service ntpd restart
	cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	cd /root
	echo '0-59/10 * * * * /usr/sbin/ntpdate -u cn.pool.ntp.org' >> /tmp/crontab.back
	crontab /tmp/crontab.back
	systemctl restart crond
	yum install net-tools -y
	yum install epel-release -y
	systemctl stop firewalld
    systemctl disable firewalld
    yum install lynx wget expect iptables -y
}
function 4_Ocserv_Server_install(){
yum install ocserv -y
mkdir /root/anyconnect
cd /root/anyconnect
#生成 CA 证书
certtool --generate-privkey --outfile ca-key.pem
cat >ca.tmpl <<EOF
cn = "HY Annyconnect CA"
organization = "HUAYU"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
cp ca-cert.pem /etc/ocserv/
#生成本地服务器证书
certtool --generate-privkey --outfile server-key.pem
cat >server.tmpl <<EOF
cn = "HY Annyconnect CA"
organization = "HUAYU"
serial = 2
expiration_days = 3650
encryption_key
signing_key
tls_www_server
EOF
certtool --generate-certificate --load-privkey server-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
--template server.tmpl --outfile server-cert.pem
cp server-cert.pem /etc/ocserv/
cp server-key.pem /etc/ocserv/
#生成证书注销文件
cd /root/anyconnect/
touch /root/anyconnect/revoked.pem
cd /root/anyconnect/
cat << _EOF_ >crl.tmpl
crl_next_update = 365
crl_number = 1
_EOF_
certtool --generate-crl --load-ca-privkey ca-key.pem \
           --load-ca-certificate ca-cert.pem \
           --template crl.tmpl --outfile crl.pem
#配置 ocserv
cd /etc/ocserv/
rm -rf ocserv.conf
wget https://raw.githubusercontent.com/chendong12/ocserv/master/ocserv.conf
#
cd /root/anyconnect
wget https://raw.githubusercontent.com/chendong12/ocserv/master/gen-client-cert.sh
wget https://raw.githubusercontent.com/chendong12/ocserv/master/user_add.sh
https://raw.githubusercontent.com/chendong12/ocserv/master/user_del.sh
chmod +x gen-client-cert.sh
chmod +x user_add.sh
chmod +x user_del.sh
}
function 7_iptables_init(){
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p
systemctl start iptables
yum install httpd -y
service httpd start
chmod +x /etc/rc.local
cat >>  /etc/rc.local <<EOF
systemctl start ocserv
systemctl start iptables
systemctl start httpd
iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 4433 -j ACCEPT
iptables -A INPUT -p udp --dport 4433 -j ACCEPT
iptables -A INPUT -j DROP
iptables -t nat -F
iptables -t nat -A POSTROUTING -s 10.12.0.0/24 -o eth0 -j MASQUERADE
#自动调整mtu，ocserv服务器使用
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
EOF
reboot
}
function shell_install() {
1_ntp_configure
4_Ocserv_Server_install
7_iptables_init
}
shell_install
