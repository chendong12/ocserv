## Cisco anyconnect 服务器搭建（服务器软件采用ocserv）注意本项目是基于Centos7操作系统
### 安装步骤 ###
> * 第一步：安装ocserv 服务器，请使用下面的脚本文件进行安装
> * https://raw.githubusercontent.com/chendong12/ocserv/master/ocserv_quick.sh
> * 第二步：（可以不安装）但如果想使用 Radius 来管理 ocserv 服务器中的账号，即OCSERV对接Radius，请使用这一步，注意，必须安装第一步，才能安装第二步
> * https://github.com/chendong12/ocserv/blob/master/ocserv_radius_quickinstall.sh
## 服务器操作常用方法 ##
> * 启动服务器方法: systemctl start ocserv
> * 停止服务器方法: systemctl stop ocserv
> * 重启服务器方法: systemctl restart ocserv
## 增加客户端账号的方法
> * 方法一：/root/anyconnect/user_add.sh 通过脚本文件直接增加账号密码和证书文件 
> * 方法二：ocpasswd -c /etc/ocserv/ocpasswd user_name 增加用户名为user_name的账号，如果已经存在则修改其密码
> * 方法三：cd /root/anyconnect ; mkdir user_name ; cd user_name ; ../gen-client-cert.sh user_name /root/anyconnect 只增加用户证书> * ocpasswd -d user_name 删除user_name账号
## 配置文件说明 ##
> * ocserv_quick.sh － 快速安装anyconnect服务器的脚本文件
> * ocserv.conf － 服务器主要配置文件
> * install_script.sh － 服务器安装主要脚本文件
> * ocserv_radius_quickinstall.sh － Ocserv 对接 Radius 快速安装脚本
> * radius_for_ocserv.sh － Ocserv 对接 Radius 主要脚本文件
> * user_add.sh － 快速生成anyconnect 客户端账号及客户端证书的脚本
> * user_del.sh － 快速删除anyconnect 客户端账号及禁用改账号证书脚本
> * client_download.txt － 不同类型的客户端下载地址
> * certificate.txt － 单独新增证书用户说明
> * /ssl/server_ssl_install.txt 服务器通过域名连接，并配置可信ssl的方法说明


## 修改 /var/lib/ocserv/profile.xml 文件中的内容可以将服务器的配置推送给客户端 ###
```bash
vi /var/lib/ocserv/profile.xml
```
```xml
<ServerList>
                <HostEntry>
                    <HostName>服务器描述1</HostName>
                    <HostAddress>server1_ipaddress:port</HostAddress>
                </HostEntry>
                <HostEntry>
                    <HostName>服务器描述2</HostName>
                    <HostAddress>server2_ipaddress:port</HostAddress>
                </HostEntry>
</ServerList>
```

## ocserv 常见配置说明 ##
#### 配置vpn客户端的速率 ###
```bash
rx-data-per-sec =
tx-data-per-sec = 
如果要设置2Mbps带宽，清输入 262144，计算方法为：  2048(2*1024)*1024/8 = 262144
1M    131072
2M    262144
3M    393216
4M    524288
5M    655360
```

### 配置连接协议，禁止TLS1.0 和TLS1.1 ###

```bash
tls-priorities = "NORMAL:%SERVER_PRECEDENCE:%COMPAT:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1"
```

### 记录anyconnect连接断开的日志 ###
编辑 /etc/ocserv/ocserv.conf
增加如下内容

```bash
connect-script = /etc/ocserv/connect-script
disconnect-script = /etc/ocserv/connect-script
```
新建 connect-script 文件
```bash
touch /etc/ocserv/connect-script
chmod +x /etc/ocserv/connect-script
```

/etc/ocserv/connect-script 文件内容如下

```bash
#!/bin/bash
 
export LOGFILE=/etc/ocserv/login.log
 
#echo $USERNAME : $REASON : $DEVICE
case "$REASON" in
  connect)
echo `date` $USERNAME "connected" >> $LOGFILE
echo `date` $REASON $USERNAME $DEVICE $IP_LOCAL $IP_REMOTE $IP_REAL >> $LOGFILE
    ;;
  disconnect)
echo `date` $USERNAME "disconnected" >> $LOGFILE
    ;;
esac
exit 0
```
配置完成后重启 ocserv


```bash
systemctl restart ocserv
cat /etc/ocserv/login.log 
2022年 08月 28日 星期日 11:23:56 CST test connected
2022年 08月 28日 星期日 11:23:56 CST connect jack vpns0 10.12.0.1 10.12.0.128 1.27.210.31
2022年 08月 28日 星期日 11:24:00 CST test disconnected
```

### 使用 let's encrypt 生成域名的证书 ###

```bash
准备工作：80 端口未被使用，并且防火墙上放行了80端口

yum install epel-release
yum install certbot

certbot certonly --standalone -d your_domain

/etc/letsencrypt/live/your_domain/fullchain.pem
/etc/letsencrypt/live/your_domain/privkey.pem

修改 ocserv 配置文件
server-cert = /etc/letsencrypt/live/your_domain/fullchain.pem
server-key = /etc/letsencrypt/live/your_domain/privkey.pem

systemctl rextart ocserv

Let's Encrypt 证书的有效期是 90 天，并且官方推荐每 60 天 自动进行一次续期，以确保证书不会过期。我们可以利用 Certbot 的内置功能，自动管理证书的续期。

设置 Certbot 自动续期： Certbot 内置了一个命令，用于每天自动检查证书是否即将过期。你可以使用以下 cron 任务来确保 Certbot 每天检查证书状态并续期

这个 cron 任务会每天午夜运行一次 certbot renew，但只有当证书剩余有效期少于 30 天时，Certbot 才会自动续期证书

crontab -e

0 0 * * * /usr/bin/certbot renew --quiet --post-hook "systemctl restart ocserv"

```

