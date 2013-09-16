#!/bin/sh
if [ $# != 1 ]; then
  echo "Arguments: $0 </full/path/to/rom.zip>"
  exit 1
fi
mkdir -p $HOME/slimgtmp
rm -rf ~/slimgtmp/*
SLIMFILES=$HOME/slimfiles
SLIMGHOME=$HOME/slimgtmp
cd $SLIMGHOME
echo "unzipping $1 here"
unzip -q -o $1
echo "Removing useless apps"
for k in `cat $SLIMFILES/gapps-to-remove.txt`
do
	echo "Now removing: "$k
	rm system/app/$k
done
echo "Zipping up your file now"
DATE=$(/bin/date +%m%d%y-%H%M)
zip -q -r ~/slimgapps-$DATE.zip *

# test to see if the phone is connected, and if so, push the .zip to it
ADB=$(adb devices | wc -l)
if [ $ADB -ge "3" ]; then
        echo "Phone is connected, pushing .zip file now"
	adb push ~/slimgapps-$DATE.zip  /sdcard/Download/
else
        echo "Phone is not connected, at your convenience run"
	"adb push ~/slimgapps-$DATE.zip  /sdcard/Download/"
fi

echo "Slim Gapps completed."
echo "cleaning up - removing temp dir"
rm -rf ~/slimgtmp/*
