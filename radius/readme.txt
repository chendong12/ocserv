如果需要把 radius服务器 和 ocserv 服务器部署到不同的服务器，需要配置下的的文件

1、在ocserv 服务器端
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT

vim /etc/raddb/clients.conf
修改下面的内容
ipv4addr = *
secret = testing123

2、在radius 客户端
yum install radiusclient-ng -y

vi /etc/radiusclient-ng/radiusclient.conf
其中需要指定radius server的地址，修改如下两行，这里假设你已经搭好了radius server而且IP为1.2.3.4：

authserver 1.2.3.4
acctserver 1.2.3.4

vi /etc/radiusclient-ng/servers
在尾巴加上：

1.2.3.4        some-pass

如果采用radius认证，需要注释/etc/ocserv/ocserv.conf文件中的下面行密码认证行
			   auth = "plain[passwd=/etc/ocserv/ocpasswd]"
			   #下面的方法是使用radius验证用户，如果使用radius，请注释上面的密码验证
			   #auth = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"
			   #下面这句加上之后，daloradius在线用户中可以看到用户在线
			   #acct = "radius[config=/etc/radiusclient-ng/radiusclient.conf]"
			   修改完成之后执行systemctl restart ocserv 命令重启ocserv
