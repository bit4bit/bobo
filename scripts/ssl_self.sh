#!/bin/sh

set -ex

cpwd=$(pwd)

mkdir -p /tmp/bobo-ssl
cd /tmp/bobo-ssl

FILE_CERT_NAME=bobo
openssl req -new -subj "/C=CO/ST=Colombia/CN=nczs4e7pbhbmmk2pwswa3ov3fxj7oruf4p5urhnumtdacel2p6dtgbqd.onion" \
        -newkey rsa:2048 -nodes -keyout "$FILE_CERT_NAME.key" -out "$FILE_CERT_NAME.csr"
openssl x509 -req -days 9999 -in "$FILE_CERT_NAME.csr" -signkey "$FILE_CERT_NAME.key" -out "$FILE_CERT_NAME.crt"

cp $FILE_CERT_NAME.crt  $cpwd/server.crt
cp $FILE_CERT_NAME.key  $cpwd/server.key
