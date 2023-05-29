#!/bin/bash
sqladmin=0p0o0i0900
client_secret=testing123
public_ip=`curl -s ifconfig.me`
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
alias cp='cp'
yum install yum-utils -y
yum remove httpd* php*  

#nginx + php install 
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
yum install nginx -y
#php 7.4 安装，不能安装php8 ，否则图标和一些信息不显示
yum install epel-release yum-utils -y
#
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
#列出可以用的php版本
yum --disablerepo="*" --enablerepo="remi-safe" list php[7-9][0-9].x86_64
#
yum-config-manager --enable remi-php74
#
yum install php php-fpm php-mysql php-cli php-devel php-gd php-pecl-memcache php-pspell php-snmp php-xmlrpc php-xml php-pdo php-pgsql php-pecl-redis php-soap php-mbstring php-opcache php-json php-cli php-zip -y

#php 7.4 修改配置
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


#配置数据库
systemctl restart mariadb
sleep 3
mysqladmin -u root password ""${sqladmin}""
mysql -uroot -p${sqladmin} -e "create database radius;"
mysql -uroot -p${sqladmin} -e "grant all privileges on radius.* to radius@localhost identified by 'p0radius_0p';"
mysql -uradius -p'p0radius_0p' radius < /etc/raddb/mods-config/sql/main/mysql/schema.sql
mysql -uradius -p'p0radius_0p' radius < /etc/raddb/mods-config/sql/ippool/mysql/schema.sql

systemctl restart mariadb
systemctl restart radiusd

#daloradius 1.3 配置

cd /var/www/html/
wget https://180.188.197.212:/down/daloradius-1.3.tar.gz --no-check-certificate
tar xzvf daloradius-1.3.tar.gz
mv daloradius-1.3 daloradius
cp /var/www/html/daloradius/library/daloradius.conf.php.sample /var/www/html/daloradius/library/daloradius.conf.php
chown -R nginx:nginx /var/www/html/daloradius/
chmod 664 /var/www/html/daloradius/library/daloradius.conf.php
cd /var/www/html/daloradius/
#mysql -uradius -p'p0radius_0p' radius < contrib/db/fr2-mysql-daloradius-and-freeradius.sql
mysql -uradius -p'p0radius_0p' radius < /var/www/html/daloradius/contrib/db/mysql-daloradius.sql
sleep 3
sed -i "s/\['CONFIG_DB_USER'\] = 'root'/\['CONFIG_DB_USER'\] = 'radius'/g"  /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\['CONFIG_DB_PASS'\] = ''/\['CONFIG_DB_PASS'\] = 'p0radius_0p'/g" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s|/tmp/daloradius.log|/var/log/daloradius.log|g" /var/www/html/daloradius/library/daloradius.conf.php
chmod 644 /var/log/messages
chmod 755 /var/log/radius/
chmod 644 /var/log/radius/radius.log
touch /var/log/daloradius.log
chown -R nginx:nginx /var/log/daloradius.log
chown -R nginx:nginx /var/www/html/daloradius/


#添加中文支持
sed -i '/Russian/i\<option value="zh"> Chinese <\/option>' /var/www/html/daloradius/config-lang.php


yum -y install epel-release
yum install php-devel php-pear -y
pear install DB

systemctl stop httpd
systemctl restart radiusd
systemctl restart php-fpm
systemctl restart nginx

sed -i 's/You are already logged in - access denied/您同时登录的用户数超过上限/g'  /etc/raddb/radiusd.conf 

#月流量设置
#增加 radius 两条自定义属性
echo 'ATTRIBUTE Max-Monthly-Traffic  3003 integer
ATTRIBUTE Monthly-Traffic-Limit    3004    integer' >> /etc/raddb/dictionary

#新建月流量的计数器sql语句，下面的文件没有需要新增，虽然在文件夹下有 monthlycounter.conf 但不是用来限制每月流量的

wget -P /etc/raddb/mods-config/sql/counter/mysql/ https://180.188.197.212/down/monthlytrafficcounter.conf --no-check-certificate

#内容为 query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{${key}}' AND UNIX_TIMESTAMP(AcctStartTime) > '%%b'"

#在sqlcounter模块中增加新的计数器

mv /etc/raddb/mods-available/sqlcounter /etc/raddb/mods-available/sqlcounter.bak
wget -P /etc/raddb/mods-available/ https://180.188.197.212/down/sqlcounter  --no-check-certificate

ln -s /etc/raddb/mods-available/sqlcounter /etc/raddb/mods-enabled/

#将monthlytrafficcounter模块添加到用户认证过程中
sed -i '/\/smbpasswd/i\monthlytrafficcounter' /etc/raddb/sites-enabled/default

#增加50G用户组，该组的用户流量为50G，1024*50，同时在线用户是2
mysql -uradius -pp0radius_0p -Dradius -e "INSERT INTO radgroupcheck (groupname,attribute,op,VALUE) VALUES ('50G_month','Max-Monthly-Traffic',':=','51200');"
mysql -uradius -pp0radius_0p -Dradius -e "INSERT INTO radgroupcheck (GroupName,Attribute,op,Value) VALUES ('50G_Month','Simultaneous-Use',':=', '2');"

systemctl restart radiusd

#radius 的默认密码存储在

echo "client all {
        ipaddr          = * 
        proto           = *
        secret          = $client_secret
        nas_type        = other 
        limit {
                max_connections = 16
                lifetime = 0    # 连接超时时间
                idle_timeout = 30   # 空闲时间
        }
}" >>/etc/raddb/clients.conf


echo 'systemctl start mariadb
systemctl start nginx
systemctl start php-fpm
systemctl start radiusd
iptables -I INPUT -p tcp --dport 9090 -j ACCEPT
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT' >/etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
systemctl restart mariadb
systemctl restart nginx
systemctl restart php-fpm
systemctl restart radiusd
iptables -I INPUT -p tcp --dport 9090 -j ACCEPT
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT

yum install -y radcli-devel

echo "==========================================================================
                  Centos7 VPN installation is complete                           
										 
信息保存在 /root/info.txt file.		
          
mysql 账号密码： root password:$sqladmin   
Radius共享密钥：$client_secret
Radius管理地址：http://$public_ip:9090
登录账号密码：administrator Password:radius

编辑 /etc/ocserv/ocserv.conf 文件修改认证方式。如果用 radius 认证，增加下面两行，并去掉原来的密码认证
auth = "radius[config=/etc/radcli/radiusclient.conf,groupconfig=true]"
acct = "radius[config=/etc/radcli/radiusclient.conf]"
修改完成后 systemctl restat ocserv 重启 ocserv 服务

==========================================================================" > /root/info.txt
	cat /root/info.txt
