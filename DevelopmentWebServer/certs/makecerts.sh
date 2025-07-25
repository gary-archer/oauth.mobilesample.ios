#!/bin/bash

###################################################################################
# Creates a development SSL certificate to host the deep linking mobile assets file
###################################################################################

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Require OpenSSL 3 so that up to date syntax can be used
#
OPENSSL_VERSION_3=$(openssl version | grep 'OpenSSL 3')
if [ "$OPENSSL_VERSION_3" == '' ]; then
  echo 'Please install openssl version 3 or higher before running this script'
fi

#
# Set parameters
#
DOMAIN='mobile.authsamples'

#
# Create the root private key
#
openssl ecparam -name prime256v1 -genkey -noout -out $DOMAIN.ca.key
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating the Root CA key'
  exit 1
fi

#
# Create the root certificate file, which has a long lifetime
#
openssl req \
    -x509 \
    -new \
    -key $DOMAIN.ca.key \
    -out $DOMAIN.ca.crt \
    -subj "/CN=Development CA for $DOMAIN.com" \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -days 3650
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating the Root CA'
  exit 1
fi

#
# Create the SSL key
#
openssl ecparam -name prime256v1 -genkey -noout -out $DOMAIN.ssl.key
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating the SSL key'
  exit 1
fi

#
# Create the SSL certificate, which must have a limited lifetime
#
openssl req \
    -new \
    -key $DOMAIN.ssl.key \
    -out $DOMAIN.ssl.csr \
    -subj "/CN=$DOMAIN.com"
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating the certificate signing request'
  exit 1
fi

openssl x509 -req \
    -in "$DOMAIN.ssl.csr" \
    -CA "$DOMAIN.ca.crt" \
    -CAkey "$DOMAIN.ca.key" \
    -out "$DOMAIN.ssl.crt" \
    -sha256 \
    -days 365 \
    -extfile extensions.cnf \
    -extensions server_ext
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating the SSL certificate'
  exit 1
fi

#
# Export it to a deployable PKCS#12 file that is password protected
#
openssl pkcs12 \
    -export \
    -inkey $DOMAIN.ssl.key \
    -in $DOMAIN.ssl.crt \
    -name $DOMAIN.com \
    -out $DOMAIN.ssl.p12 \
    -passout pass:Password1
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating the PKCS#12 file'
  exit 1
fi

#
# Indicate success
#
rm ./*.csr
echo 'All certificates created successfully'
