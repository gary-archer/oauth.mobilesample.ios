#!/bin/bash

###################################################################################################
# A script to run a development web server over HTTPS that hosts a deep linking assets file
# This enables associateed domains registration to work on any computer when using ?mode=developer
# To run the script, ensure that you have the following tools installed:
# - Node.js
# - OpenSSL 3
# - envsubst (brew install gettext)
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# You must update this to your own Apple Team ID that uses your own certificates
#
if [ "$APPLE_TEAM_ID" == '' ]; then
  echo 'No APPLE_TEAM_ID was supplied to the deploy.sh script'
  exit 1
fi

#
# Create SSL certificates for a local version of https://mobile.authsamples.com
#
./certs/makecerts.sh
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating local SSL certificates'
  exit 1
fi

#
# Make the simulator trust the 'Development CA for mobile.authsamples.com' root certificate
# Once installed, find the root CA at these locations on the simulator:
# - The Profile at 'Settings / General / VPN & Device Management'
# - Trust for the Profile at 'Settings / General / About / Certificate Trust Settings'
# - If required, use the simulator's menu item 'Device / Erase All Content and Settings' to clean up
#
xcrun simctl keychain booted add-root-cert ./certs/mobile.authsamples.ca.pem
if [ $? -ne 0 ]; then
  echo 'Problem encountered creating local SSL certificates'
  exit 1
fi

#
# Update mobile deep linking assets with the Apple Team ID
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
# Run the mobile host on port 443, which requires administrator rights
#
echo 'Running the mobile HTTPS host to serve the deep linking asset file ...'
npm install
npm start
if [ $? -ne 0 ]; then
  echo 'Problem encountered running the mobile host'
  exit 1
fi

#
# On the simulator you should now be able to browse to this URL in Safari without SSL trust errors
# You can then run the app with 'Automatically Manage Signing' and Claimed HTTPS Scheme logins should work
# - https://mobile.authsamples.com/.well-known/apple-app-site-association
#