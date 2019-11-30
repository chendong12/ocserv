如果需要把 radius服务器 和 ocserv 服务器部署到不同的服务器，需要配置下的的文件

### 在radius 服务器上的配置 ###
If you need to deploy the radius server and ocserv server to different servers, you need to configure the files.
> * 1、在radius 服务器上开放radius 端口
```bash 
iptables -I INPUT -p tcp --dport 1812 -j ACCEPT
iptables -I INPUT -p udp --dport 1812 -j ACCEPT
iptables -I INPUT -p tcp --dport 1813 -j ACCEPT
iptables -I INPUT -p udp --dport 1813 -j ACCEPT
```
> * 2、修改radius服务器上的密码
```bash 
vim /etc/raddb/clients.conf
Change below
ipv4addr = *
secret = testing123
```
## 在ocserv 服务器上的配置
#以下内容是在ocserv 服务器上进行
> * 1、安装 radiusclient-ng
```bash
yum install radiusclient-ng -y
```

> * 2、配置 radiusclient
```bash
vi /etc/radiusclient-ng/radiusclient.conf
#将authserver和acctserver 后面的地址，修改为你实际的radius服务器地址，假定你radius服务器地址为 1.2.3.4:

authserver 1.2.3.4
acctserver 1.2.3.4
```

> * 3、增加服务器IP及radius连接密码
```bash
vi /etc/radiusclient-ng/servers
#添加下面内容，其中1.2.3.4 位你的radius服务器IP地址，some-pass 为密码

1.2.3.4       testing123
```
> * 4、修改ocserv 服务器配置，开启radius认证
```bash
vi /etc/ocserv/ocserv.conf
#注释密码认证，去掉radiusclient-ng 相关的两行内容，如下所示
#auth = "plain[passwd=/etc/ocserv/ocpasswd]
auth = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"
acct = "radius[config=/etc/radiusclient-ng/radiusclient.conf]"
```
修改完成之后执行下面命令重启ocserv
```bash
systemctl restart ocserv
```
## 修改phpmail乱码问题 ##
```bash
#修改其中的public $CharSet = ‘iso-8859-1′; 改为 public $CharSet = ‘UTF-8′;
vi /var/www/html/user_reg_new/mailer/class.phpmailer.php
```

## radius 客户端测试方法 ##
```bash
radtest user user_pass testing123 1812 testing123
```

