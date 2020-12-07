#!/bin/bash
#######################################################
#                                                     #
# This is a ocserv installation for CentOS 7 and 6    #
# Version: 1.1.1 20181101                             #
# Website: https://github.com/chendong12/ocserv       #
#                                                     #
####################################################
#
#检测是否是root用户
function check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}
function check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}
function sys_clean(){
	yum remove ocserv httpd mariadb-server freeradius freeradius-mysql freeradius-utils -y
	rm -rf /var/www/html/*.p12
	rm -rf /root/anyconnect/
	rm -rf /tmp/crontab.back
	rm -rf /etc/ocserv/
	rm -rf /etc/raddb/
	rm -rf /var/www/html/daloradius
	rm -rf /etc/httpd/conf/httpd.conf
	rm -rf /root/info.txt
	rm -rf /opt/letsencrypt
	sed -i '/service ocserv start/d' /etc/rc.d/rc.local
	sed -i '/service iptables start/d' /etc/rc.d/rc.local
	sed -i '/service httpd start/d' /etc/rc.d/rc.local
	sed -i '/echo 1 > \/proc\/sys\/net\/ipv4\/ip_forward/d' /etc/rc.d/rc.local
	sed -i '/iptables -F/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -i lo -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -p icmp -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -p tcp --dport 22 -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -I INPUT -p tcp --dport 80 -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -p tcp --dport 4433 -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -p udp --dport 4433 -j ACCEPT/d' /etc/rc.d/rc.local
	sed -i '/iptables -A INPUT -j DROP/d' /etc/rc.d/rc.local
	sed -i '/iptables -t nat -F/d' /etc/rc.d/rc.local
	sed -i '/iptables -t nat -A POSTROUTING -s 10.12.0.0\/24 -o eth0 -j MASQUERADE/d' /etc/rc.d/rc.local
	sed -i '/#自动调整mtu，ocserv服务器使用/d' /etc/rc.d/rc.local
	sed -i '/iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu/d' /etc/rc.d/rc.local
	sed -i '/systemctl start mariadb/d' /etc/rc.d/rc.local
	sed -i '/systemctl start httpd/d' /etc/rc.d/rc.local
	sed -i '/systemctl start radiusd/d' /etc/rc.d/rc.local
	sed -i '/iptables -I INPUT -p tcp --dport 9090 -j ACCEPT/d' /etc/rc.d/rc.local
}
function centos1_ntp(){
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
function centos2_ocserv(){
yum install epel-release wget -y
yum install ocserv httpd -y
mkdir /root/anyconnect
cd /root/anyconnect
#生成 CA 证书
certtool --generate-privkey --outfile ca-key.pem
cat >ca.tmpl <<EOF
cn = "Annyconnect CA"
organization = "Anyconnect"
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
cn = "Annyconnect CA"
organization = "Anyconnect"
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
cp crl.pem /etc/ocserv/	   
#配置 ocserv
cd /etc/ocserv/
rm -rf ocserv.conf
wget --no-check-certificate https://raw.githubusercontent.com/chendong12/ocserv/master/ocserv.conf
#
cd /root/anyconnect
wget --no-check-certificate https://raw.githubusercontent.com/chendong12/ocserv/master/gen-client-cert.sh
wget --no-check-certificate https://raw.githubusercontent.com/chendong12/ocserv/master/user_add.sh
wget --no-check-certificate https://raw.githubusercontent.com/chendong12/ocserv/master/user_del.sh
chmod +x gen-client-cert.sh
chmod +x user_add.sh
chmod +x user_del.sh
}
centos3_iptables(){
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p
chmod +x /etc/rc.d/rc.local
cat >>  /etc/rc.d/rc.local <<EOF
service ocserv start
service httpd start
echo 1 > /proc/sys/net/ipv4/ip_forward
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
echo "Anyconnect服务器安装完成，服务准备重启，重启后即可正常使用"
reboot
}
function centos_install(){
sys_clean
centos1_ntp
centos2_ocserv
centos3_iptables
}
function shell_install() {
check_root
check_sys
	if [[ ${release} == "centos" ]]; then
		centos_install
	else
		echo "您的操作系统不是Cenos，请更换操作系统之后再试"  && exit 1
	fi
}
shell_install
