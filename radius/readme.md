如果需要把 radius服务器 和 ocserv 服务器部署到不同的服务器，需要配置下的的文件

### 在radius 服务器上的配置 ###
If you need to deploy the radius server and ocserv server to different servers, you need to configure the files.
> * 1、在radius 服务器上开放radius 端口
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT

> * 2、修改radius服务器上的密码
vim /etc/raddb/clients.conf
Change below
ipv4addr = *
secret = testing123

## 在ocserv 服务器上的配置
#以下内容是在ocserv 服务器上进行
> * 1、安装 radiusclient-ng
yum install radiusclient-ng -y

> * 2、配置 radiusclient
vi /etc/radiusclient-ng/radiusclient.conf
You need to specify the address of the radius server, modify the following two lines, here you assume that you have set up the radius server and the IP is 1.2.3.4:

authserver 1.2.3.4
acctserver 1.2.3.4

> * 3、增加服务器IP及radius连接密码
vi /etc/radiusclient-ng/servers
add below

1.2.3.4        some-pass

> * 4、修改ocserv 服务器配置，开启radius认证
If you use radius authentication, you need to comment below line at the /etc/ocserv/ocserv.conf file
auth = "plain[passwd=/etc/ocserv/ocpasswd]"
 #下面的方法是使用radius验证用户，如果使用radius，请注释上面的密码验证
#auth = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"
#下面这句加上之后，daloradius在线用户中可以看到用户在线
#acct = "radius[config=/etc/radiusclient-ng/radiusclient.conf]"
修改完成之后执行systemctl restart ocserv 命令重启ocserv

## 修改phpmail乱码问题 ##
vi /var/www/html/user_reg_new/mailer/class.phpmailer.php
修改其中的public $CharSet = ‘iso-8859-1′; 改为 public $CharSet = ‘UTF-8′;

## radius 客户端测试方法 ##
radtest user user_pass server_ipaddress 1812 securit

