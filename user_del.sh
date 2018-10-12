#!/bin/bash
#ocserv 删除用户及注销用户的证书的脚本文件
function user_del() {
    read -p "请输入要删除的用户名称！(英文格式):" user_name
    if  [ ! -n "$user_name" ] ;then
    echo "您没有输入用户名，请重新执行程序"
    else
    /usr/bin/ocpasswd -d $user_name
    echo "$user_name 用户删除成功"
    cat /root/anyconnect/$user_name/$user_name-cert.pem >> /root/anyconnect/revoked.pem
    certtool --generate-crl --load-ca-privkey ca-key.pem  --load-ca-certificate ca-cert.pem --load-certificate revoked.pem  --template crl.tmpl --outfile crl.pem
    echo "$user_name 用户证书被注销"
    service ocserv restart
	fi
}
user_del
