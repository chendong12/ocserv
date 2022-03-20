#!/bin/bash
######################################################################################################
yum install -y gnutls-devel libev-devel
yum install -y pam-devel lz4-devel libseccomp-devel readline-devel \
        libnl3-devel krb5-devel radcli-devel libcurl-devel cjose-devel \
        jansson-devel protobuf-c-devel libtalloc-devel http-parser-devel \
        protobuf-c gperf nuttcp lcov uid_wrapper pam_wrapper nss_wrapper \
        socket_wrapper gssntlmssp haproxy iputils  gawk \
        gnutls-utils iproute yajl
wget https://www.infradead.org/ocserv/download/ocserv-1.1.6.tar.xz  --no-check-certificate
tar xf ocserv-1.1.6.tar.xz 
cd ocserv-1.1.6
./configure && make && make install
mv /var/lib/ocserv/profile.xml.rpmsave /var/lib/ocserv/profile.xml
cp /etc/ocserv/ocserv.conf.rpmsave /etc/ocserv/ocserv.conf
sed -i 's@enable-auth = "certificate"@#enable-auth = "certificate"@g' /etc/ocserv/ocserv.conf
cp "doc/systemd/standalone/ocserv.service" "/usr/lib/systemd/system/ocserv.service"
sed -i 's@/usr/sbin/ocserv@/usr/local/sbin/ocserv@g' /usr/lib/systemd/system/ocserv.service
systemctl daemon-reload
systemctl start ocserv
