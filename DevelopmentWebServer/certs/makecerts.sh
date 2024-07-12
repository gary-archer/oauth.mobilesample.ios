#!/bin/bash

########################################################################
# Creates a development root CA to host the iOS deep linking assets file
########################################################################

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Make initial checks
#
export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
OPENSSL_VERSION_3=$(openssl version | grep 'OpenSSL 3')
if [ "$OPENSSL_VERSION_3" == '' ]; then
  echo 'Please install openssl version 3 or higher before running this script'
fi

#
# Root certificate parameters
#
ENTITY='mobile.authsamples'
ROOT_CERT_FILE_PREFIX="$ENTITY.ca"
ROOT_CERT_DESCRIPTION="Development CA for $ENTITY.com"

#
# SSL certificate parameters
#
SSL_CERT_FILE_PREFIX="$ENTITY.ssl"
SSL_CERT_PASSWORD='Password1'

#
# Create the root private key
#
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out $ROOT_CERT_FILE_PREFIX.key
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the Root CA key'
  exit 1
fi

#
# Create the root certificate file, which has a long lifetime
#
openssl req \
    -x509 \
    -new \
    -key $ROOT_CERT_FILE_PREFIX.key \
    -out $ROOT_CERT_FILE_PREFIX.pem \
    -subj "/CN=$ROOT_CERT_DESCRIPTION" \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -days 3650
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the Root CA'
  exit 1
fi

#
# Create the SSL key
#
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out $SSL_CERT_FILE_PREFIX.key
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the SSL key'
  exit 1
fi

#
# Create the certificate signing request for a wildcard certificate
#
openssl req \
    -new \
    -key $SSL_CERT_FILE_PREFIX.key \
    -out $SSL_CERT_FILE_PREFIX.csr \
    -subj "/CN=$ENTITY.com" \
    -addext 'basicConstraints=critical,CA:FALSE'
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the SSL certificate signing request'
  exit 1
fi

#
# Create the SSL certificate, which must have a limited lifetime
#
openssl x509 -req \
    -in $SSL_CERT_FILE_PREFIX.csr \
    -CA $ROOT_CERT_FILE_PREFIX.pem \
    -CAkey $ROOT_CERT_FILE_PREFIX.key \
    -out $SSL_CERT_FILE_PREFIX.pem \
    -days 365 \
    -extfile server.ext
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the SSL certificate'
  exit 1
fi

#
# Export it to a deployable PKCS#12 file that is password protected
#
openssl pkcs12 \
    -export -inkey $SSL_CERT_FILE_PREFIX.key \
    -in $SSL_CERT_FILE_PREFIX.pem \
    -name "$ENTITY.com" \
    -out $SSL_CERT_FILE_PREFIX.p12 \
    -passout pass:$SSL_CERT_PASSWORD
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the PKCS#12 file'
  exit 1
fi

#
# Delete files no longer needed
#
rm "$ENTITY.ca.srl"
rm "$ENTITY.ssl.csr"
echo 'All certificates created successfully'
