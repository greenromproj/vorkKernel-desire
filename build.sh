#!/bin/bash

DIR=$PWD 
rm Tools/AnyKernel/kernel/zImage
rm -rf Tools/AnyKernel/system/lib/

echo Building the kernel
ARCH=arm CROSS_COMPILE=$ARM_EABI make -j`grep 'processor' /proc/cpuinfo | wc -l`
make ARCH=arm CROSS_COMPILE=$ARM_EABI INSTALL_MOD_PATH=$DIR/Tools/AnyKernel/system modules_install

# signed_file variables

# build date
NOW=$(date +"%d-%b-%y")
# linux version + localversion
localVersion=`cat .config | fgrep CONFIG_LOCALVERSION= | cut -f 2 -d= | sed s/\"//g`
linuxVersion=`cat .config | fgrep "Linux/arm " | cut -d: -f 1 | cut -c13-20`
VERSION=$linuxVersion$localVersion

# CPU/SLAB/IO
CpuSched=`cat .config | grep CONFIG_SCHED_.FS=y | cut -c14-16`
Slab=`cat .config | grep CONFIG_SL.B=y | cut -c8-11`
tmp=`cat .config | fgrep CONFIG_DEFAULT_IOSCHED= | cut -f 2 -d= | sed s/\"//g`
IOSched=$( echo "$tmp" | tr -s  '[:lower:]'  '[:upper:]' )

# HAVS or SVS
AVS=`cat .config | grep CONFIG_MSM_CPU_AVS=y | cut -c20-21`
if [ "$AVS" == "y" ]
	then
		tmp_svshavs="HAVS"
		voltage=`cat .config | grep CONFIG_AVS_...=y | cut -c12-14`
		SVSHAVS=$tmp_svshavs"-"$voltage
			else
		SVSHAVS="SVS"
	fi


signed_file=vorkKernel-$linuxVersion-$SVSHAVS-$CpuSched-$IOSched-$Slab-$NOW.zip

cp arch/arm/boot/zImage Tools/AnyKernel/kernel
rm Tools/AnyKernel/system/lib/modules/$VERSION/build
rm Tools/AnyKernel/system/lib/modules/$VERSION/source
cp Tools/AnyKernel/system/lib/modules/$VERSION/kernel/drivers/net/wireless/bcm4329/bcm4329.ko Tools/AnyKernel/system/lib/modules/

cd Tools/AnyKernel

echo Making update.zip ...
zip -r -y -q update *
echo
echo update.zip created

echo Signing update.zip as $signed_file ...

cp ../signapk_files/testkey.* .
cp ../signapk_files/signapk.jar .

java -jar signapk.jar testkey.x509.pem testkey.pk8 update.zip $signed_file

rm -f testkey.*
rm -f signapk.jar
rm -f update.zip

if [ -d $BUILD_DIR/$linuxVersion ]; then
mv $signed_file $BUILD_DIR/$linuxVersion/$signed_file
else
    mkdir $BUILD_DIR/$linuxVersion
    mv $signed_file $BUILD_DIR/$linuxVersion/$signed_file
fi
cd ../../
