#!/bin/sh

#nap_count="`netstat -ano|grep 3333|grep -v 'grep'|wc -l`"
nap_count="`ps aux|grep udp2raw|grep -v 'grep'|wc -l`"
conf=/root/udp2raw/config.conf
if [ $nap_count -gt 0 ]
then
  #echo $nap_count
   echo "udp2raw is up and running...!  `date`"
  else
 /etc/init.d/udp2raw start  >>/var/log/udp2raw.log
   echo "udp2raw stopped,plz Start Nap! `date`" >>/var/log/udp2raw.log
 fi
