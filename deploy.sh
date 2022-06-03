#!/bin/bash

################################################################################################
# A script to build and deploy the release build of the IPA file to the connected iPhone or iPad
################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"
APP_ID='com.authsamples.basicmobileapp'

#
# Do a clean
#
#rm -rf build
if [ $? -ne 0 ]; then
  echo 'Problem encountered cleaning the iOS build system'
  exit
fi

#
# Do a release build to produce an archive file
#
#xcodebuild -workspace basicmobileapp.xcworkspace -scheme basicmobileapp -configuration Release archive -archivePath build/basicmobileapp.xcarchive
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the iOS app'
  exit
fi

#
# Export the archive to an IPA file, which works according to the instructions in the export.plist file
#
#xcodebuild -exportArchive -archivePath build/basicmobileapp.xcarchive -exportPath build -exportOptionsPlist export.plist
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the iOS app to an archive file'
  exit
fi


#
# The following steps required these tools to be installed as a prerequisite:
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
exit

#
# To run the IPA file on the device, ensure that the disk image for th device version is downloaded from here, then unzipped:
# https://github.com/mspvirajpatel/Xcode_Developer_Disk_Images/releases
#
# Then copy the folder to a location such as this, and run this command:
# ideviceimagemounter -d /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/15.3/DeveloperDiskImage.dmg
#
# Debug from another terminal if required by running this command:
# idevicesyslog -q
#

#
# Then run the app
#
DEVICE_UDID=$(ideviceinfo -k UniqueDeviceID)
idevicedebug run $APP_ID -u $DEVICE_UDID
if [ $? -ne 0 ]; then
  echo 'Problem encountered running the iOS app'
  exit
fi
