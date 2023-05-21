#!/bin/bash
function init() {
sqladmin=0p0o0i0900
yum install lynx -y
public_ip=`lynx --source www.monip.org | sed -nre 's/^.* (([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p'`
#Solve the problem of slow ssh access, you can manually restart ssh after installing the script.
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
alias cp='cp'
yum install yum-utils -y
}
function nginx_php82() {
#nginx + php install 
yum remove httpd* php*  
yum install yum-utils -y

echo '[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true' >/etc/yum.repos.d/nginx.repo

#默认情况下nginx 只安装稳定的版本
yum install nginx -y

#php 8.2 安装

yum install epel-release yum-utils -y
#
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
#列出可以用的php版本
yum --disablerepo="*" --enablerepo="remi-safe" list php[7-9][0-9].x86_64
#
yum-config-manager --enable remi-php82
#
yum install php php-fpm php-mysql php-cli php-devel php-gd php-pecl-memcache php-pspell php-snmp php-xmlrpc php-xml php-pdo php-pgsql php-pecl-redis php-soap php-mbstring php-opcache php-json php-cli php-zip -y

#php 8.2 修改配置

sed -i 's@;date.timezone =@date.timezone = Asia/Shanghai@g' /etc/php.ini
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf

#将 php-fpm 调整问文件运行
sed -i 's@listen = 127.0.0.1:9000@listen = /var/run/php-fpm/php-fpm.sock@g' /etc/php-fpm.d/www.conf

#配置监控用户和组
sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf

#用下面命令将 /etc/php.ini 将;cgi.fix_pathinfo=1修改为cgi.fix_pathinfo=0
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini
#
echo 'server {
    listen       9090;
    server_name  localhost;

    root   /var/www/html/daloradius;
    index index.php index.html index.htm;

    location / {
	try_files $uri $uri/ =404;
    }
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
	root /usr/share/nginx/html;
    }

    location ~ \.php$ {
	try_files $uri =404;
	fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
	fastcgi_index index.php;
	fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	include fastcgi_params;
    }
}' >/etc/nginx/conf.d/daloradius.conf 

chown -R root:nginx /var/lib/php
}
function freeradius() {

yum install wget expect telnet net-tools mariadb-server -y
yum install freeradius freeradius-mysql freeradius-utils -y

#freeradius 对接 sql
ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/

ln -s /etc/raddb/mods-available/sqlippool /etc/raddb/mods-enabled/
sed -i "s/auth = no/auth = yes/g" /etc/raddb/radiusd.conf
sed -i "s/auth_badpass = no/auth_badpass = yes/g" /etc/raddb/radiusd.conf
sed -i "s/auth_goodpass = no/auth_goodpass = yes/g" /etc/raddb/radiusd.conf
sed -i "s/\-sql/sql/g" /etc/raddb/sites-available/default
#Insert content after the found session {string
sed -i '/session {/a\        sql' /etc/raddb/sites-available/default
sed -i 's/driver = "rlm_sql_null"/driver = "rlm_sql_mysql"/g' /etc/raddb/mods-available/sql	
#Find the string and remove the comment with the first letter#
sed -i '/read_clients = yes/s/^#//' /etc/raddb/mods-available/sql
sed -i '/dialect = "sqlite"/s/^#//' /etc/raddb/mods-available/sql
sed -i 's/dialect = "sqlite"/dialect = "mysql"/g' /etc/raddb/mods-available/sql	
sed -i '/server = "localhost"/s/^#//' /etc/raddb/mods-available/sql
sed -i '/port = 3306/s/^#//' /etc/raddb/mods-available/sql
sed -i '/login = "radius"/s/^#//' /etc/raddb/mods-available/sql
sed -i '/password = "radpass"/s/^#//' /etc/raddb/mods-available/sql
sed -i 's/password = "radpass"/password = "p0radius_0p"/g' /etc/raddb/mods-available/sql	
sed -i 's|dialect = ${modules.sql.dialect}|dialect = "mysql"|' /etc/raddb/mods-available/sqlcounter
# Enable used tunnel for unifi
sed -i 's|use_tunneled_reply = no|use_tunneled_reply = yes|' /etc/raddb/mods-available/eap
# Enable status in freeadius
ln -s /etc/raddb/sites-available/status /etc/raddb/sites-enabled/status
}

function mariadb() {
#配置数据库
systemctl restart mariadb
sqladmin=0p0o0i0900
sleep 3
mysqladmin -u root password ""${sqladmin}""
mysql -uroot -p${sqladmin} -e "create database radius;"
mysql -uroot -p${sqladmin} -e "grant all privileges on radius.* to radius@localhost identified by 'p0radius_0p';"
mysql -uradius -p'p0radius_0p' radius < /etc/raddb/mods-config/sql/main/mysql/schema.sql
mysql -uradius -p'p0radius_0p' radius < /etc/raddb/mods-config/sql/ippool/mysql/schema.sql
}

function daloradius() {
#daloradius 1.3 配置
cd /var/www/html/
wget https://github.com/lirantal/daloradius/archive/refs/tags/1.3.tar.gz
tar xzvf 1.3.tar.gz
mv daloradius-1.3 daloradius
cp /var/www/html/daloradius/library/daloradius.conf.php.sample /var/www/html/daloradius/library/daloradius.conf.php
chown -R apache:apache /var/www/html/daloradius/
cd /var/www/html/daloradius/
mysql -uradius -p'p0radius_0p' radius < /var/www/html/daloradius/contrib/db/mysql-daloradius.sql
sleep 3
sed -i "s/\['CONFIG_DB_USER'\] = 'root'/\['CONFIG_DB_USER'\] = 'radius'/g"  /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\['CONFIG_DB_PASS'\] = ''/\['CONFIG_DB_PASS'\] = 'p0radius_0p'/g" /var/www/html/daloradius/library/daloradius.conf.php
#sed -i "s/mysql/mysqli/g" /var/www/html/daloradius/library/daloradius.conf.php
chmod 644 /var/log/messages
chmod 755 /var/log/radius/
chmod 644 /var/log/radius/radius.log
touch /tmp/daloradius.log
chmod 644 /tmp/daloradius.log
chown -R nginx:nginx /tmp/daloradius.log
yum -y install epel-release
yum install php-devel php-pear -y
pear install DB

systemctl stop httpd
systemctl disable httpd
}

function monthly_traffic(){

#修改登录超限提醒
sed -i 's/You are already logged in - access denied/您同时登录的用户数超过上限/g'  /etc/raddb/radiusd.conf 

#月流量设置
#增加 radius 两条自定义属性
echo 'ATTRIBUTE Max-Monthly-Traffic  3003 integer
ATTRIBUTE Monthly-Traffic-Limit    3004    integer' >> /etc/raddb/dictionary

#新建月流量的计数器sql语句，下面的文件没有需要新增，虽然在文件夹下有 monthlycounter.conf 但不是用来限制每月流量的

wget -P /etc/raddb/mods-config/sql/counter/mysql/ https://raw.githubusercontent.com/chendong12/ocserv/master/radius/monthlytrafficcounter.conf

#在sqlcounter模块中增加新的计数器

mv /etc/raddb/mods-available/sqlcounter /etc/raddb/mods-available/sqlcounter.bak
wget -P /etc/raddb/mods-available/ https://raw.githubusercontent.com/chendong12/ocserv/master/radius/sqlcounter

ln -s /etc/raddb/mods-available/sqlcounter /etc/raddb/mods-enabled/

#将monthlytrafficcounter模块添加到用户认证过程中
sed -i '/\/smbpasswd/i\monthlytrafficcounter' /etc/raddb/sites-enabled/default

#增加50G用户组，该组的用户流量为50G，1024*50，同时在线用户是2
mysql -uradius -pp0radius_0p -Dradius -e "INSERT INTO radgroupcheck (groupname,attribute,op,VALUE) VALUES ('50G_month','Max-Monthly-Traffic',':=','51200');"
mysql -uradius -pp0radius_0p -Dradius -e "INSERT INTO radgroupcheck (GroupName,Attribute,op,Value) VALUES ('50G_Month','Simultaneous-Use',':=', '2');"
systemctl restart radiusd

}

function set_iptables(){
echo 'systemctl start mariadb
systemctl start nginx
systemctl start php-fpm
systemctl start radiusd
iptables -I INPUT -p tcp --dport 9090 -j ACCEPT
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT' >/etc/rc.d/rc.local
systemctl restart mariadb
systemctl restart nginx
systemctl restart php-fpm
systemctl restart radiusd
iptables -I INPUT -p tcp --dport 9090 -j ACCEPT
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT
}

function crond(){

echo 'mysql -uradius -pp0radius_0p -e "UPDATE radius.radacct SET acctstoptime = acctstarttime + acctsessiontime WHERE ((UNIX_TIMESTAMP(acctstarttime) + acctsessiontime + 240 - UNIX_TIMESTAMP())<0) AND acctstoptime IS NULL;"' >> /usr/mysys/clearsession.sh
chmod +x /usr/mysys/clearsession.sh
echo '0-59/10 * * * * /usr/mysys/clearsession.sh' >> /tmp/crontab.back
echo '0 0 1 * * /usr/mysys/dbback/backup_radius_db.sh' >> /tmp/crontab.back
crontab /tmp/crontab.back
systemctl restart crond
}

function set_radiusclient(){
yum install radiusclient-ng -y
echo "localhost testing123" >> /etc/radiusclient-ng/servers
echo "==========================================================================
                  Centos7 VPN installation is complete                           
										 
				 The following information will be automatically saved to the /root/info.txt file.		
          
                   mysql root password:0p0o0i0900      

		          VPN Account management address：http://$public_ip:9090
		                             Username：administrator Password:radius
		                             
		     If you use radius authentication, you need to comment the following line in the /etc/ocserv/ocserv.conf file.
			   auth = "plain[passwd=/etc/ocserv/ocpasswd]"
			   #The following method is to use radius authentication. If using radius, please remove the following line comment#
			   #auth = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"
			   #After remove the following line comment#, The manager can be seen online users in the daloradius.
			   #acct = "radius[config=/etc/radiusclient-ng/radiusclient.conf]"
			  After the modification is complete, execute the systemctl restart ocserv command to restart ocserv.

==========================================================================" > /root/info.txt
	cat /root/info.txt
	exit;
}

function shell_install() {
init
nginx_php82
freeradius
mariadb
daloradius
monthly_traffic
set_iptables
crond
set_radiusclient
}
shell_install
