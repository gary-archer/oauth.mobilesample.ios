#!/bin/bash

#############################################################################################################
# Some users may get problems running the code sample, due to deep linking failures after login
# This leads to a mobile deep link being followed as a web URL and an Access Denied message: 
# https://github.com/gary-archer/oauth.mobilesample.ios?tab=readme-ov-file#deep-linking-registration-failures
#
# First, ensure that you have the following tools installed:
# - OpenSSL
# - envsubst (brew install gettext)
# - Node.js
#############################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# You must update this to your own Apple Team ID that uses your own certificates
#
export APPLE_TEAM_ID='U3VTCHYEM7'
if [ "$APPLE_TEAM_ID" == '' ]; then
  echo 'No APPLE_TEAM_ID was supplied to the deploy.sh script'
  exit 1
fi

#
# Create certificates
#
./certs/makecerts.sh
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating local SSL certificates'
  exit 1
fi

#
# Update mobile deep linking assets
#
echo 'Updating mobile deep linking assets file ...'
cd .well-known
envsubst < apple-app-site-association-template > apple-app-site-association
if [ $? -ne 0 ]; then
  echo 'Problem encountered updating the deep linking assets file'
  exit 1
fi
cd ..

#
# Run the mobile host, which requires administrator rights
#
echo 'Running the mobile HTTPS host to serve the deep linking asset file ...'
npm install
npm start
if [ $? -ne 0 ]; then
  echo 'Problem encountered running the mobile host'
  exit 1
fi
