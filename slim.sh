#!/bin/sh

SLIM=$HOME/slim

if [ $# != 1 ]; then
  echo "Arguments: $0 </full/path/to/rom.zip>"
  exit 1
fi

# what OS are we?
OSTYPE=$(uname -s)
if [ $OSTYPE = "Darwin" ]; then
	echo "You're running a Mac, going to use /usr/local/bin/sed"
	SED=/usr/local/bin/sed
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

echo "Removing useless apps"
for k in `cat $SLIMFILES/apps-to-remove.txt`
do
#	echo "Now removing: "$k
	find . -name $k -exec rm -f {} \;
done

echo "Removing sounds and bootanimation"
cd $SLIMTMP
#rm system/media/audio/ringtones/* 
#rm system/media/audio/notifications/* 
rm system/media/bootanimation.zip 
#rm system/media/audio/alarms/*
#rm system/media/audio/ui/*

echo "Installing new boot animation and sounds"
cp $SLIMFILES/l-bootanimation.zip system/media/bootanimation.zip 
cp $SLIMFILES/Old_Phone.ogg system/media/audio/ringtones/Old_Phone.ogg
cp $SLIMFILES/Merope.ogg system/media/audio/notifications/Merope.ogg
cp $SLIMFILES/sms-received2.ogg system/media/audio/notifications/sms-received2.ogg
chmod 644 system/media/bootanimation.zip
chmod 644 system/media/audio/ringtones/Old_Phone.ogg
chmod 644 system/media/audio/notifications/*

###echo "Installing new wifi config"
###cp system/etc/wifi/WCNSS_qcom_cfg.ini system/etc/wifi/WCNSS_qcom_cfg.ini.orig
###rm system/etc/wifi/WCNSS_qcom_cfg.ini
###cp $SLIMFILES/WCNSS_qcom_cfg.ini system/etc/wifi/WCNSS_qcom_cfg.ini
###chmod 644 system/etc/wifi/WCNSS_qcom_cfg.ini

echo "Installing new hosts file"
cp $SLIMFILES/hosts system/etc/hosts
chmod 644 system/etc/hosts


echo "Installing 99vibrator into /system/etc/init.d"
cp $SLIMFILES/99vibrator system/etc/init.d/99vibrator
chmod 755 system/etc/init.d/99vibrator

#echo "Installing Apollo.apk"
#cp $SLIMFILES/Apollo.apk system/app/Apollo.apk
#chmod 644 system/app/Apollo.apk

echo "Installing QuickSearchBox.apk"
cp $SLIMFILES/QuickSearchBox.apk system/app/QuickSearchBox.apk
chmod 644 system/app/QuickSearchBox.apk

echo "Installing Better Battery Stats as system app"
cp $SLIMFILES/com.asksven.betterbatterystats_xdaedition.apk system/priv-app/com.asksven.betterbatterystats_xdaedition.apk
chmod 644 system/priv-app/com.asksven.betterbatterystats_xdaedition.apk

#echo "Installing AOSP Keyboard"
#cp $SLIMFILES/LatinIME.apk system/app/LatinIME.apk
#chmod 644 system/app/LatinIME.apk

echo "editing build.prop - making backup copy first"
cp system/build.prop system/build.prop.new
$SED -i '/ro.config.ringtone/d' system/build.prop.new
$SED -i '/ro.config.notification_sound/d' system/build.prop.new
$SED -i '/ro.config.alarm_alert/d' system/build.prop.new
$SED -i '/wifi.supplicant_scan_interval/d' system/build.prop.new


echo 'ro.config.ringtone=Old_Phone.ogg' >> system/build.prop.new
echo 'ro.config.notification_sound=Merope.ogg' >> system/build.prop.new
echo 'ro.config.alarm_alert=Merope.ogg' >> system/build.prop.new
echo 'wifi.supplicant_scan_interval=360' >> system/build.prop.new

echo "Checking ogg in system/build.prop.new"
oggs=$(grep -c ogg system/build.prop.new)
if [ $oggs != 3 ]; then
	echo "wrong number of oggs in build.prop, aborting"
	echo "there are "$oggs" but there are supposed to be 3"
	exit 1
fi
echo "There are "$oggs" .ogg files in system/build.prop.new, copying to system/build.prop"

#echo "setting wifi scan rate to 360 seconds in system/build.prop"
#perl -pi -e 's/wifi.supplicant_scan_interval=15/wifi.supplicant_scan_interval=360/' system/build.prop
#grep wifi.supplicant_scan_interval system/build.prop

echo "setting density from 268 to 320 in system/build.prop"
perl -pi -e 's/ro.sf.lcd_density=268/ro.sf.lcd_density=320/' system/build.prop.new
grep ro.sf.lcd_density system/build.prop.new

#echo "adding LTE enabler lines to build.prop"
#cat $SLIMFILES/build.prop.lte >> system/build.prop.new
#echo "Done adding LTE enabler lines to build.prop"

cp system/build.prop system/build.prop.orig
mv system/build.prop.new system/build.prop


echo "setting perms on build.prop"
chmod 644 system/build.prop
chmod 644 system/build.prop.orig

echo "Installing onandroid"
cp $SLIMFILES/onandroid system/bin
chmod 755 system/bin/onandroid
cp $SLIMFILES/partlayout4nandroid system/partlayout4nandroid
chmod 644 system/partlayout4nandroid

#echo "Installing wireless settings (hopefully)"
#mkdir -p data/misc/wifi
#cp $SLIMFILES/wpa_supplicant.conf data/misc/wifi/wpa_supplicant.conf
#cp $SLIMFILES/ipconfig.txt data/misc/wifi/ipconfig.txt

echo "Zipping up your file now"
DATE=$(/bin/date +%m%d%y-%H%M)
zip -q -r ~/slimrom-$DATE.zip *

# test to see if the phone is connected, and if so, push the .zip to it

ADB=$(adb devices | wc -l)
if [ $ADB -ge "3" ]; then
	echo "Phone is connected, pushing .zip file now"
	adb push ~/slimrom-$DATE.zip  /sdcard/Download/
else
	echo "Phone is not connected, at your convenience run:"
	echo "adb push ~/slimrom-"$DATE".zip /sdcard/Download/"
fi

echo "cleaning up..."
rm -rf $SLIMTMP/*


echo "Slim completed."
