#!/bin/bash

#########################################################################################################
# I use this script to run the app on my iOS or iPad device, which is registered against my Apple account
# It enables me to build and deploy the release build of the IPA file to the connected iPhone or iPad
# See also the prerequisite instructions in the export.plist file
##########################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"
APP_ID='com.authsamples.finalmobileapp'

#
# Do a clean
#
rm -rf build
if [ $? -ne 0 ]; then
  echo 'Problem encountered cleaning the iOS build system'
  exit
fi

#
# Do a release build to produce an archive file
#
xcodebuild -project finalmobileapp.xcodeproj -scheme finalmobileapp -configuration Release archive -archivePath build/finalmobileapp.xcarchive
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the iOS app'
  exit
fi

#
# Export the archive to an IPA file, which works according to the instructions in the export.plist file
#
xcodebuild -exportArchive -archivePath build/finalmobileapp.xcarchive -exportPath build -exportOptionsPlist export.plist
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the iOS app to an archive file'
  exit
fi

#
# On macOS, the following steps require these tools to be installed as a prerequisite:
# brew install libimobiledevice
# brew install ideviceinstaller
#

#
# Uninstall on an emulator or device if required
#
ideviceinstaller --uninstall $APP_ID
if [ $? -ne 0 ]; then
  echo 'Problem encountered uninstalling the iOS app'
  exit
fi

#
# Deploy to the connected device
#
ideviceinstaller --install ./build/Demo.ipa
if [ $? -ne 0 ]; then
  echo 'Problem encountered deploying the iOS app'
  exit
fi
