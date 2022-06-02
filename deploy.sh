#!/bin/bash

####################################################################################################
# A script to build and deploy the release build of the IPA file to the connected emulator or device
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

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
xcodebuild -workspace basicmobileapp.xcworkspace -scheme basicmobileapp -configuration Release archive -archivePath build/basicmobileapp.xcarchive
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the iOS app'
  exit
fi

#
# Export the archive to an IPA file, which requires my code signing certificate
# This will only works for me, as described in the export.plist file
#
xcodebuild -exportArchive -archivePath build/basicmobileapp.xcarchive -exportPath build -exportOptionsPlist export.plist
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the iOS app to an archive file'
  exit
fi

#
# Uninstall on an emulator or device if required
#
if [ $? -ne 0 ]; then
  echo 'Problem encountered uninstalling the iOS app'
  exit
fi

#
# Deploy to the connected device
#
if [ $? -ne 0 ]; then
  echo 'Problem encountered deploying the iOS app'
  exit
fi

#
# Then run the app
#
if [ $? -ne 0 ]; then
  echo 'Problem encountered running the iOS app'
  exit
fi
