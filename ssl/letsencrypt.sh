#本脚本未做测试
read -p "请输入VPN域名！(默认为example.com):" domain_name
if [ -z "$domain_name" ];then
domain_name=example.com
read -p "请输入您的Email！(默认为user@qq.com):" mail_address
if [ -z "$mail_address" ];then
mail_address=user@qq.com

yum install git -y
git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
cd /opt/letsencrypt
#安装证书
expect<<-END
spawn ./letsencrypt-auto certonly -d $domain_name
expect "Select the appropriate number"
send "3\r"
expect "Enter email address (used for urgent renewal and security notices) "
send "$mail_address\r"
expect "(A)gree"
send "A\r"
expect "(Y)es"
send "Y\r"
expect "Input the webroot for"
send "/var/www/html/\r"
expect eof
exit
END
#证书安装完成后需要修改配置文件，如下，替换服务器中的 server-cert 和 server-key 配置的地方，最后重启服务器
#vi /etc/ocserv/ocserv.conf 
#server-cert = /etc/letsencrypt/live/example.com/fullchain.pem
#server-key = /etc/letsencrypt/live/example.com/privkey.pem
#service ocserv restart
