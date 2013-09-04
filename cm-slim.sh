#!/bin/sh
if [ $# != 1 ]; then
  echo "Arguments: $0 </full/path/to/rom.zip>"
  exit 1
fi

mkdir -p $HOME/cmtmp
CMTMP=$HOME/cmtmp
rm -rf $CMTMP/*

SLIMFILES=$HOME/slimfiles
cd $CMTMP

echo "unzipping original zip"
unzip -q -o $1

echo "Removing useless apps"
cd system/app
for k in $(cat $SLIMFILES/cm-apps-to-remove.txt)
do
	echo "Now removing: "$k
	rm $k
done

echo "Removing sounds"
cd $CMTMP
rm system/media/audio/ringtones/* 
rm system/media/audio/notifications/* 

rm system/media/audio/alarms/*
rm system/media/audio/ui/*

echo "Removing videos"
rm system/media/video/*

echo "Installing new sounds"
cp $SLIMFILES/Old_Phone.ogg system/media/audio/ringtones/Old_Phone.ogg
cp $SLIMFILES/Merope.ogg system/media/audio/notifications/Merope.ogg
cp $SLIMFILES/sms-received2.ogg system/media/audio/notifications/sms-received2.ogg

chmod 644 system/media/audio/ringtones/Old_Phone.ogg
chmod 644 system/media/audio/notifications/*

echo "Installing new wifi config"
cp system/etc/wifi/WCNSS_qcom_cfg.ini system/etc/wifi/WCNSS_qcom_cfg.ini.orig
rm system/etc/wifi/WCNSS_qcom_cfg.ini
cp $SLIMFILES/WCNSS_qcom_cfg.ini system/etc/wifi/WCNSS_qcom_cfg.ini
chmod 644 system/etc/wifi/WCNSS_qcom_cfg.ini

echo "Installing new hosts file"
cp $SLIMFILES/hosts system/etc/hosts
chmod 644 system/etc/hosts

echo "editing build.prop - making backup copy first"
cp system/build.prop system/build.prop.new
sed -i '/ro.config.ringtone/d' system/build.prop.new
sed -i '/ro.config.notification_sound/d' system/build.prop.new
sed -i '/ro.config.alarm_alert/d' system/build.prop.new

echo 'ro.config.ringtone=Old_phone.ogg' >> system/build.prop.new
echo 'ro.config.notification_sound=sms-received2.ogg' >> system/build.prop.new
echo 'ro.config.alarm_alert=sms-received2.ogg' >> system/build.prop.new

echo "Checking ogg in system/build.prop.new"
oggs=`grep -c ogg system/build.prop.new`
if [ $oggs != 3 ]; then
	echo "wrong number of oggs in build.prop, aborting"
	echo "there are "$oggs" but there are supposed to be 3"
	exit 1
fi
echo "There are "$oggs" .ogg files in system/build.prop.new, copying to system/build.prop"

echo "changing wifi scan rate from 15 to 180 seconds in system/build.prop"
perl -pi -e 's/wifi.supplicant_scan_interval=15/wifi.supplicant_scan_interval=180/' system/build.prop
grep wifi.supplicant_scan_interval system/build.prop

echo "setting density from 320 to 268 in system/build.prop"
perl -pi -e 's/ro.sf.lcd_density=320/ro.sf.lcd_density=268/' system/build.prop
grep ro.sf.lcd_density system/build.prop

cp system/build.prop system/build.prop.orig
mv system/build.prop.new system/build.prop

echo "setting perms on build.prop"
chmod 644 system/build.prop
chmod 644 system/build.prop.orig

echo "Zipping up your file now"
zip -q -r ~/cm-`/bin/date +%m%d%y`.zip *
adb push ~/cm-`/bin/date +%m%d%y`.zip  /sdcard/Download/
echo "cleaning up..."
rm -rf $CMTMP/*
echo "CM Slim completed."
