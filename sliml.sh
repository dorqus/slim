#!/bin/sh

SLIM=$HOME/slim

if [ $# != 1 ]; then
  echo "Arguments: $0 </full/path/to/rom.zip>"
  exit 1
fi

# what OS are we?
OSTYPE=$(uname -s)
if [ $OSTYPE = "Darwin" ]; then
	echo "You're running a Mac, going to use /usr/local/bin/gsed"
	SED=/usr/local/bin/gsed
	export SED
elif [ $OSTYPE = "Linux" ]; then
	echo "You're running some flavor of Linux, going to use /bin/sed"
	SED=/bin/sed
	export SED
fi

mkdir -p $HOME/slimtmp
SLIMTMP=$HOME/slimtmp
rm -rf $SLIMTMP/*

SLIMFILES=$HOME/slimfiles
cd $SLIMTMP

echo "unzipping original zip"
unzip -q -o $1

#echo "Removing useless apps"
#for k in `cat $SLIMFILES/apps-to-remove.txt`
#do
##	echo "Now removing: "$k
#	find . -name $k -exec rm -f {} \;
#done

echo "Removing sounds"
cd $SLIMTMP
rm system/media/audio/ringtones/*.ogg
rm system/media/audio/notifications/*.ogg

echo "Installing new sounds"
cp $SLIMFILES/Old_Phone.ogg system/media/audio/ringtones/Old_Phone.ogg
cp $SLIMFILES/Merope.ogg system/media/audio/notifications/Merope.ogg
cp $SLIMFILES/sms-received2.ogg system/media/audio/notifications/sms-received2.ogg
chmod 644 system/media/audio/ringtones/Old_Phone.ogg
chmod 644 system/media/audio/notifications/*

echo "Installing new hosts file"
cp $SLIMFILES/hosts system/etc/hosts
chmod 644 system/etc/hosts

echo "Installing QuickSearchBox.apk"
cp $SLIMFILES/QuickSearchBox.apk system/app/QuickSearchBox.apk
chmod 644 system/app/QuickSearchBox.apk

echo "editing build.prop - making backup copy first"
cp system/build.prop system/build.prop.new
$SED -i '/ro.config.ringtone/d' system/build.prop.new
$SED -i '/ro.config.notification_sound/d' system/build.prop.new
$SED -i '/ro.config.alarm_alert/d' system/build.prop.new
$SED -i '/wifi.supplicant_scan_interval/d' system/build.prop.new


echo 'ro.config.ringtone=Old_Phone.ogg' >> system/build.prop.new
echo 'ro.config.notification_sound=Merope.ogg' >> system/build.prop.new
echo 'ro.config.alarm_alert=Merope.ogg' >> system/build.prop.new
echo 'wifi.supplicant_scan_interval=180' >> system/build.prop.new

echo "Checking ogg in system/build.prop.new"
oggs=$(grep -c ogg$ system/build.prop.new)
if [ $oggs != 3 ]; then
	echo "wrong number of oggs in build.prop, aborting"
	echo "there are "$oggs" but there are supposed to be 3"
	exit 1
fi
echo "There are "$oggs" .ogg files in system/build.prop.new"

echo "Stripping out blank lines and comments from system/build.prop.new"
grep -v ^\# system/build.prop.new | grep . > /tmp/system-build.prop
cp /tmp/system-build.prop system/build.prop.new

cp system/build.prop system/build.prop.orig
mv system/build.prop.new system/build.prop

echo "setting perms on build.prop"
chmod 644 system/build.prop
chmod 644 system/build.prop.orig

echo "Zipping up your file now"
DATE=$(/bin/date +%m%d%y-%H%M)
NEWNAME=$(echo $1 | sed s/\.zip$/-slimmed.zip)
zip -q -r ~/$NEWNAME *

# test to see if the phone is connected, and if so, push the .zip to it

ADB=$(adb devices | wc -l)
if [ $ADB -ge "3" ]; then
	echo "Phone is connected, pushing .zip file now"
	adb push ~/$NEWNAME  /sdcard/l/
else
	echo "Phone is not connected, at your convenience run:"
	echo "adb push ~/$NEWNAME /sdcard/l/"
fi

echo "cleaning up..."
rm -rf $SLIMTMP/*


echo "Slim completed."
