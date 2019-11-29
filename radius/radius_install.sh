#!/bin/bash
function set_shell_input1() {
	sqladmin=0p0o0i0900
	yum install lynx -y
	public_ip=`lynx --source www.monip.org | sed -nre 's/^.* (([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p'`
	#Solve the problem of slow ssh access, you can manually restart ssh after installing the script.
	sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
	alias cp='cp'
	yum groupinstall "Development tools" -y
	yum install wget vim expect telnet net-tools httpd mariadb-server php php-mysql php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl curl-devel -y
	yum install freeradius freeradius-mysql freeradius-utils -y
	systemctl restart mariadb
	systemctl restart httpd
}
#Configuring the radius database and importing data
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
	sed -i "s/mysql/mysqli/g" /var/www/html/daloradius/library/daloradius.conf.php
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
sed -i "s/mysql/mysqli/g" /var/www/html/daloradius/library/daloradius.conf.php
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
