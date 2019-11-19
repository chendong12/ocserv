#!/bin/bash
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"
sleep 1
#
server1='Change_to_your_abord_serverip'
OLDGW=$(ip route show 0/0 | sed -e 's/^default//')
#------------------------------------------------------------------------------------
#udp2raw需要做的
ServerList=("$server1")
for p in "${ServerList[@]}"
do
        iptables -D INPUT -s $p -p tcp -m tcp --sport 50000 -j DROP
        iptables -I INPUT -s $p -p tcp -m tcp --sport 50000 -j DROP
done
echo '停止udp2raw 和openvpn客户端'
ps -ef | grep udp2raw_amd64 | grep -v grep | awk '{print $2}' | xargs kill -9
ps -ef | grep openvpn | grep -v grep | awk '{print $2}' | xargs kill -9
#------------------------------------------------------------------------------------
echo '增加服务器去往国内路由到table 5'
ip route add $server1 $OLDGW  table 5
#ip route add $server2 $OLDGW  table 5
echo '启动第一阶段udp2raw'
/root/udp2raw/udp2raw_amd64 -c -r$server1:50000 -l 127.0.0.1:1198 --raw-mode faketcp  -k udp2rawpassword --fix-gro &
echo '启动openvpn客户端'
/usr/sbin/openvpn /etc/openvpn/client/client.ovpn >/dev/null &
#
echo '执行完成'
echo "`date` 重新启动了mutiUDP2raw.sh " >> /var/log/udp2raw.log
