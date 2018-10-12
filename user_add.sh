#!/bin/bash
#ocserv 增加用户及证书的脚本文件，通过该脚本增加用户的同时增加了该用户的证书
function input_user() {
	public_ip=`lynx --source www.monip.org | sed -nre 's/^.* (([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p'`
	read -p "请输入要创建的用户名称！(英文格式):" user_name
	if  [ ! -n "$user_name" ] ;then
    echo "您没有输入用户名，请重新执行程序"
    else
	read -p "请输入密码！:" user_pass	
	fi
	if  [ ! -n "$user_pass" ] ;then
    echo "您没有输入密码"
    else
    user_add
    cert_add
    fi

}
function user_add(){
expect<<-END
spawn ocpasswd -c /etc/ocserv/ocpasswd $user_name
expect "Enter password:"
send "$user_pass\r"
expect "Re-enter password:"
send "$user_pass\r"
expect eof
exit
END
}
#配置radius数据库并导入数据
function cert_add() {
cd /root/anyconnect
mkdir $user_name
cd $user_name
expect<<-END
spawn ../gen-client-cert.sh $user_name /root/anyconnect
expect "Enter Export Password:"
send "$user_pass\r"
expect "Verifying - Enter Export Password:"
send "$user_pass\r"
expect eof
exit
END
cp /root/anyconnect/$user_name/$user_name.p12 /var/www/html/
echo "$user_name 用户创建成功,密码为$user_pass"
echo "$user_name 用户的证书创建成功,请访问下面地址进行证书下载或导入"
echo "http://$public_ip/$user_name.p12"  
echo "证书的导入密码为$user_pass"
}
function shell_install() {
	input_user
}
shell_install
