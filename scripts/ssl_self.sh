#!/bin/sh

if [ -z "$1" ]; then
    echo "$0: <hostname>"
    exit 1
fi

set -ex
cpwd=$(pwd)

mkdir -p /tmp/bobo-ssl
cp $cpwd/scripts/server_cert_ext.cnf /tmp/bobo-ssl
cd /tmp/bobo-ssl

# TOMADO DE: https://www.golinuxcloud.com/golang-http/
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -out cacert.pem -subj "/C=IN/ST=NSW/L=Bobo/O=BoboCloud/OU=Org/CN=RootCA"

openssl genrsa -out server.key 2048

openssl req -new -key server.key -out server.csr -subj "/C=IN/ST=NSW/L=Bobo/O=BoboCloud/OU=Org/CN=bobo"

echo "DNS.2 = $1" >> server_cert_ext.cnf

openssl x509 -req -in server.csr  -CA cacert.pem -CAkey ca.key -out server.crt -CAcreateserial -days 365 -sha256 -extfile server_cert_ext.cnf

cp server.crt certbundle.pem
cat cacert.pem >> certbundle.pem 

cp certbundle.pem $cpwd/server.pem
cp certbundle.pem $cpwd/client.pem
cp server.key $cpwd/server.key


