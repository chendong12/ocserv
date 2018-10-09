#!/bin/bash
USER=$1
CA_DIR=$2
SERIAL=`date +%s`
certtool --generate-privkey --outfile $USER-key.pem
cat << _EOF_ >user.tmpl
cn = "$USER"
unit = "users"
serial = "$SERIAL"
expiration_days = 9999
signing_key
tls_www_client
_EOF_
certtool --generate-certificate --load-privkey $USER-key.pem --load-ca-certificate $CA_DIR/ca-cert.pem --load-ca-privkey $CA_DIR/ca-key.pem --template user.tmpl --outfile $USER-cert.pem
openssl pkcs12 -export -inkey $USER-key.pem -in $USER-cert.pem -name "$USER VPN Client Cert" -certfile $CA_DIR/ca-cert.pem -out $USER.p12
