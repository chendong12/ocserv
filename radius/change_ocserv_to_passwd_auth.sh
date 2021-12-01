#!/bin/bash
sed -i "s/auth = \"radius\[config=\/etc\/radiusclient-ng\/radiusclient.conf,groupconfig=true\]\"/#auth = \"radius\[config=\/etc\/radiusclient-ng\/radiusclient.conf,groupconfig=true\]\"/g" /etc/ocserv/ocserv.conf 
sed -i "s/acct = \"radius\[config=\/etc\/radiusclient-ng\/radiusclient.conf\]\"/#acct = \"radius\[config=\/etc\/radiusclient-ng\/radiusclient.conf\]\"/g" /etc/ocserv/ocserv.conf
sed -i "s/#auth = \"plain\[passwd=\/etc\/ocserv\/ocpasswd\]\"/auth = \"plain\[passwd=\/etc\/ocserv\/ocpasswd\]\"/g" /etc/ocserv/ocserv.conf
systemctl restart ocserv
