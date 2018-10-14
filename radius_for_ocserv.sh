#!/bin/bash
function set_shell_input1() {
	sqladmin=0p0o0i0900
	yum install lynx -y
	public_ip=`lynx --source www.monip.org | sed -nre 's/^.* (([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p'`
	#解决ssh访问慢的问题,可以安装完脚本后手工重启ssh
	sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
	alias cp='cp'
	yum groupinstall "Development tools" -y
	yum install wget vim expect telnet net-tools httpd mariadb-server php php-mysql php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl curl-devel -y
	yum install freeradius freeradius-mysql freeradius-utils -y
	systemctl restart mariadb
	systemctl restart httpd
}
#配置radius数据库并导入数据
function set_mysql2() {
	systemctl restart mariadb
	sleep 3
	mysqladmin -u root password ""${sqladmin}""
	mysql -uroot -p${sqladmin} -e "create database radius;"
	mysql -uroot -p${sqladmin} -e "grant all privileges on radius.* to radius@localhost identified by 'p0radius_0p';"
	mysql -uradius -p'p0radius_0p' radius < /etc/raddb/mods-config/sql/main/mysql/schema.sql  
	systemctl restart mariadb
}

function set_freeradius3(){
	ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/
	sed -i "s/auth = no/auth = yes/g" /etc/raddb/radiusd.conf
	sed -i "s/auth_badpass = no/auth_badpass = yes/g" /etc/raddb/radiusd.conf
	sed -i "s/auth_goodpass = no/auth_goodpass = yes/g" /etc/raddb/radiusd.conf
	sed -i "s/\-sql/sql/g" /etc/raddb/sites-available/default
	#在查找到的session {字符串后面插入内容
	sed -i '/session {/a\        sql' /etc/raddb/sites-available/default
	sed -i 's/driver = "rlm_sql_null"/driver = "rlm_sql_mysql"/g' /etc/raddb/mods-available/sql	
	#查找到字符串，去掉首字母为的注释#
	sed -i '/read_clients = yes/s/^#//' /etc/raddb/mods-available/sql
	sed -i '/dialect = "sqlite"/s/^#//' /etc/raddb/mods-available/sql
	sed -i 's/dialect = "sqlite"/dialect = "mysql"/g' /etc/raddb/mods-available/sql	
	sed -i '/server = "localhost"/s/^#//' /etc/raddb/mods-available/sql
	sed -i '/port = 3306/s/^#//' /etc/raddb/mods-available/sql
	sed -i '/login = "radius"/s/^#//' /etc/raddb/mods-available/sql
	sed -i '/password = "radpass"/s/^#//' /etc/raddb/mods-available/sql
	sed -i 's/password = "radpass"/password = "p0radius_0p"/g' /etc/raddb/mods-available/sql	
	systemctl restart radiusd
	sleep 3
}
function set_daloradius4(){
	cd /var/www/html/
	wget http://180.188.197.212/down/daloradius-0.9-9.tar.gz >/dev/null 2>&1
	tar xzvf daloradius-0.9-9.tar.gz
	mv daloradius-0.9-9 daloradius
	chown -R apache:apache /var/www/html/daloradius/
	chmod 664 /var/www/html/daloradius/library/daloradius.conf.php
	cd /var/www/html/daloradius/
	mysql -uradius -p'p0radius_0p' radius < contrib/db/fr2-mysql-daloradius-and-freeradius.sql
	mysql -uradius -p'p0radius_0p' radius < contrib/db/mysql-daloradius.sql
	sleep 3
	sed -i "s/\['CONFIG_DB_USER'\] = 'root'/\['CONFIG_DB_USER'\] = 'radius'/g"  /var/www/html/daloradius/library/daloradius.conf.php
	sed -i "s/\['CONFIG_DB_PASS'\] = ''/\['CONFIG_DB_PASS'\] = 'p0radius_0p'/g" /var/www/html/daloradius/library/daloradius.conf.php
	yum -y install epel-release
	yum -y install php-pear-DB
	systemctl restart mariadb.service 
	systemctl restart radiusd.service
	systemctl restart httpd
	chmod 644 /var/log/messages
	chmod 755 /var/log/radius/
	chmod 644 /var/log/radius/radius.log
	touch /tmp/daloradius.log
	chmod 644 /tmp/daloradius.log
	chown -R apache:apache /tmp/daloradius.log
}

function set_fix_radacct_table5(){
	cd /tmp
	sleep 3
	wget http://180.188.197.212/down/radacct_new.sql.tar.gz
	tar xzvf radacct_new.sql.tar.gz
	mysql -uradius -p'p0radius_0p' radius < /tmp/radacct_new.sql
	rm -rf radacct_new.sql.tar.gz
	rm -rf radacct_new.sql
	systemctl restart radiusd
}

function set_iptables6(){
cat >>  /etc/rc.local <<EOF
systemctl start mariadb
systemctl start httpd
systemctl start radiusd
iptables -I INPUT -p tcp --dport 9090 -j ACCEPT
EOF
systemctl start mariadb
systemctl start httpd
systemctl start radiusd
iptables -I INPUT -p tcp --dport 9090 -j ACCEPT
}

function set_web_config7(){
echo  "
Listen 9090
<VirtualHost *:9090>
 DocumentRoot "/var/www/html/daloradius"
 ServerName daloradius
 ErrorLog "logs/daloradius-error.log"
 CustomLog "logs/daloradius-access.log" common
</VirtualHost>
" >> /etc/httpd/conf/httpd.conf
cd /var/www/html/
rm -rf *
wget http://180.188.197.212/down/daloradius20180418.tar.gz 
tar xzvf daloradius20180418.tar.gz 
rm -rf daloradius20180418.tar.gz
chown -R apache:apache /var/www/html/daloradius
service httpd restart
mkdir /usr/mysys/
cd /usr/mysys/
wget http://180.188.197.212/down/dbback.tar.gz
tar xzvf dbback.tar.gz
rm -rf dbback.tar.gz
echo 'mysql -uradius -pp0radius_0p -e "UPDATE radius.radacct SET acctstoptime = acctstarttime + acctsessiontime WHERE ((UNIX_TIMESTAMP(acctstarttime) + acctsessiontime + 240 - UNIX_TIMESTAMP())<0) AND acctstoptime IS NULL;"' >> /usr/mysys/clearsession.sh
chmod +x /usr/mysys/clearsession.sh
echo '0-59/10 * * * * /usr/mysys/clearsession.sh' >> /tmp/crontab.back
echo '0 0 1 * * /usr/mysys/dbback/backup_radius_db.sh' >> /tmp/crontab.back
crontab /tmp/crontab.back
systemctl restart crond
}

function set_radiusclient8(){
	yum install radiusclient-ng -y
	echo "localhost testing123" >> /etc/radiusclient-ng/servers
echo "==========================================================================
                  Centos7 VPN 安装完成                            
										 
				  以下信息将自动保存到/root/info.txt文件中			
          
                   mysql root用户密码:0p0o0i0900      

		          VPN 账号管理后台地址：http://$public_ip:9090
		                             账号：administrator 密码:radius
		                             
		           如果采用radius认证，需要注释/etc/ocserv/ocserv.conf文件中的下面行密码认证行
			   auth = "plain[passwd=/etc/ocserv/ocpasswd]"
			   #下面的方法是使用radius验证用户，如果使用radius，请注释上面的密码验证
			   #auth = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"
			   #下面这句加上之后，daloradius在线用户中可以看到用户在线
			   #acct = "radius[config=/etc/radiusclient-ng/radiusclient.conf]"
			   修改完成之后执行systemctl restart ocserv 命令重启ocserv

==========================================================================" > /root/info.txt
	cat /root/info.txt
	exit;
}

function shell_install() {
set_shell_input1
set_mysql2
set_freeradius3
set_daloradius4
set_fix_radacct_table5
set_iptables6
set_web_config7
set_radiusclient8
}
shell_install
