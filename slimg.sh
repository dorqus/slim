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
zip -q -r ~/slimgapps-`/bin/date +%m%d%y`.zip *
adb push ~/slimgapps-`/bin/date +%m%d%y`.zip  /sdcard/Download/
echo "Slim Gapps completed."
echo "cleaning up - removing temp dir"
rm -rf ~/slimgtmp/*
