## Cisco anyconnect 服务器搭建（服务器软件采用ocserv）注意本项目是基于Centos7操作系统
### 安装步骤 ###
> * 安装ocserv 服务器，请使用下面的脚本文件进行安装
> * https://raw.githubusercontent.com/chendong12/ocserv/master/ocserv_quick.sh
> * 使用Radius来管理ocserv 服务器中的账号，即OCSERV对接Radius，请安装上面的脚本后再使用下面的脚本文件进行radius的安装配置
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


