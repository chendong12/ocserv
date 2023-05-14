#/bin/sh
systemctl restart openvpn@server
ps -ef | grep '127.0.0.1:1298' | grep -v grep | awk '{print $2}' | xargs kill -9
/root/udp2raw/udp2raw_amd64 -s -l0.0.0.0:50000 -r 127.0.0.1:1298 --raw-mode faketcp -k huayu888 --fix-gro --cipher-mode xor --auth-mode simple &
sleep 3
iptables -D INPUT -p tcp -m tcp --dport 50000 -j DROP
iptables -I INPUT -p tcp -m tcp --dport 50000 -j DROP
/root/tc6M_tun100.sh
