#!/bin/bash
#This script is add vpn user and user's certificate at the same time
function input_user() {
	public_ip=`lynx --source www.monip.org | sed -nre 's/^.* (([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p'`
	read -p "Input your vpn username:" user_name
	if  [ ! -n "$user_name" ] ;then
    echo "You did not enter a username, please re-execute the program"
    else
	read -p "Input your password:" user_pass	
	fi
	if  [ ! -n "$user_pass" ] ;then
    echo "You did not enter your password, please re-execute the program"
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
#增加证书用户函数
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
echo "$user_name The user is successfully created and the password is $user_pass"
echo "$user_name The user's certificate was created successfully. Click the following link to download."
echo "http://$public_ip/$user_name.p12"  
echo "The import password for the certificate is $user_pass"
echo "VPN address and port is $public_ip:4433"
}
function shell_install() {
	input_user
}
shell_install
