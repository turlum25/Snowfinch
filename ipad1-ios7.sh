#!/bin/bash

# ---- Resolve script directory ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p $SCRIPT_DIR/bins
curl -L -o $SCRIPT_DIR/bins/xpwntool https://github.com/LukeZGD/Legacy-iOS-Kit/raw/refs/heads/main/bin/macos/xpwntool
curl -L -o $SCRIPT_DIR/bins/iBoot32Patcher https://github.com/LukeZGD/Legacy-iOS-Kit/raw/refs/heads/main/bin/macos/iBoot32Patcher
curl -L -o $SCRIPT_DIR/bins/dmg https://github.com/LukeZGD/Legacy-iOS-Kit/raw/refs/heads/main/bin/macos/dmg
curl -L -o $SCRIPT_DIR/bins/ipwnder32 https://github.com/LukeZGD/Legacy-iOS-Kit/raw/refs/heads/main/bin/macos/ipwnder32
curl -L -o $SCRIPT_DIR/bins/img3maker https://github.com/LukeZGD/Legacy-iOS-Kit/raw/refs/heads/main/bin/macos/img3maker
curl -L -o $SCRIPT_DIR/bins/pzb https://github.com/LukeZGD/Legacy-iOS-Kit/raw/refs/heads/main/bin/macos/pzb
curl -L -o $SCRIPT_DIR/bins/irecovery https://github.com/NyanSatan/SundanceInH2A/raw/refs/heads/master/executables/irecovery
curl -L -o $SCRIPT_DIR/bins/idevicerestore https://github.com/NyanSatan/SundanceInH2A/raw/refs/heads/master/executables/idevicerestore
curl -L -o $SCRIPT_DIR/bins/hfsplus https://github.com/NyanSatan/SundanceInH2A/raw/refs/heads/master/executables/hfsplus
# These are for untethering it, thanks to NyanSatan
curl -L -o $SCRIPT_DIR/bins/rc.boot https://github.com/NyanSatan/SundanceInH2A/raw/refs/heads/master/rc_boot/rc.boot
curl -L -o $SCRIPT_DIR/bins/exploit.dmg https://github.com/NyanSatan/SundanceInH2A/raw/refs/heads/master/exploit/exploit-k48.dmg
chmod +x $SCRIPT_DIR/bins/*
xattr -cr $SCRIPT_DIR/bins/*

echo "iPad 1 haxx"

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 [base ipsw] [target ipsw] [output name]"
    echo ""
    echo "Example:"
    echo "$0 iPad1,1_5.1.1_9B206_Restore.ipsw iPhone3,1_7.0_11A465_Restore.ipsw iPad1,1_7.0_11A465_Restore"
    exit 1
fi

BASE_IPSW="$1"
TARGET_IPSW="$2"
OUTPUT_NAME="$3"

echo "Extracting iOS 5 IPSW"
unzip $BASE_IPSW -d $OUTPUT_NAME
echo "Extracting iOS 7 IPSW"
unzip $TARGET_IPSW -d tmp
echo "Processing iBSS and iBEC"
$SCRIPT_DIR/bins/xpwntool $OUTPUT_NAME/Firmware/dfu/iBSS.k48ap.RELEASE.dfu iBSS.dec -iv 9c69f81db931108e8efc268de3f5d94d -k 92f1cc2ca8362740734d69386fa6dde5582e18786777e1f9772d5dd364d873fb
$SCRIPT_DIR/bins/xpwntool $OUTPUT_NAME/Firmware/dfu/iBEC.k48ap.RELEASE.dfu iBEC.dec -iv bde7b0d5cf7861479d81eb23f99d2e9e -k 1ba1f38e6a5b4841c1716c11acae9ee0fb471e50362a3b0dd8d98019f174a2f2
$SCRIPT_DIR/bins/iBoot32Patcher iBSS.dec iBSS.patched --rsa
$SCRIPT_DIR/bins/iBoot32Patcher iBEC.dec iBEC.patched --rsa --debug -b "rd=md0 -v amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0"
$SCRIPT_DIR/bins/img3maker -f iBSS.patched -o $OUTPUT_NAME/Firmware/dfu/iBSS.k48ap.RELEASE.dfu -t ibss
$SCRIPT_DIR/bins/img3maker -f iBEC.patched -o $OUTPUT_NAME/Firmware/dfu/iBEC.k48ap.RELEASE.dfu -t ibec
rm -rf iBSS.dec iBSS.patched iBEC.dec iBEC.patched
echo "Extracting iOS 7 root filesystem"
$SCRIPT_DIR/bins/dmg extract tmp/038-3447-395.dmg rootfs.raw -k 89d4dadced94577508999a1ce2a08b346328d9b25ad4e63b4220ce441cce35cf9e0a108b
echo "Modifying iOS 7 root filesystem"
$SCRIPT_DIR/bins/hfsplus rootfs.raw grow 2500000000
# $SCRIPT_DIR/bins/hfsplus rootfs.raw untar $SCRIPT_DIR/resources/springboard.tar System/Library/CoreServices/SpringBoard.app/ might not be required atm
# for touchscreen to work
$SCRIPT_DIR/bins/hfsplus rootfs.raw add $SCRIPT_DIR/resources/Common.mtprops usr/share/firmware/multitouch/Common.mtprops
$SCRIPT_DIR/bins/hfsplus rootfs.raw add $SCRIPT_DIR/resources/iPad.mtprops usr/share/firmware/multitouch/iPad.mtprops
# WiFi drivers
$SCRIPT_DIR/bins/hfsplus rootfs.raw mkdir usr/share/firmware/wifi/4329c0
$SCRIPT_DIR/bins/hfsplus rootfs.raw add $SCRIPT_DIR/resources/duo.bin usr/share/firmware/wifi/4329c0/uno.bin
$SCRIPT_DIR/bins/hfsplus rootfs.raw add $SCRIPT_DIR/resources/duo.txt usr/share/firmware/wifi/4329c0/uno.txt
echo "Adding hacktivation"
$SCRIPT_DIR/bins/hfsplus rootfs.raw add $SCRIPT_DIR/resources/MobileGestalt.plist private/var/mobile/Library/Caches/com.apple.MobileGestalt.plist
echo "Building root filesystem"
$SCRIPT_DIR/bins/dmg build rootfs.raw $OUTPUT_NAME/038-4291-006.dmg 
rm -rf "rootfs.raw"
echo "Replacing DeviceTree"
cp $SCRIPT_DIR/dtre/DeviceTree.k48ap.img3 $OUTPUT_NAME/Firmware/all_flash/all_flash.k48ap.production/DeviceTree.k48ap.img3 
echo "Processing restore ramdisk"
$SCRIPT_DIR/bins/xpwntool tmp/038-3373-256.dmg ramdisk.raw -iv 076220ac2c46cd54f1eff12d78f044b2 -k b2101ec5cdd1919c5b0e6dd7116f576ec38b62d9d2880418486fa9f2237e94cc
$SCRIPT_DIR/bins/hfsplus ramdisk.raw grow 20000000
$SCRIPT_DIR/bins/hfsplus ramdisk.raw rm usr/sbin/asr
$SCRIPT_DIR/bins/hfsplus ramdisk.raw add $SCRIPT_DIR/Ramdisk-stuff/asr usr/sbin/asr
$SCRIPT_DIR/bins/hfsplus ramdisk.raw chmod 100755 usr/sbin/asr
$SCRIPT_DIR/bins/hfsplus ramdisk.raw extract usr/local/share/restore/options.n90.plist 
# Add baseband update skip
printf "<key>UpdateBaseband</key><false/>\n" >> options.n90.plist
$SCRIPT_DIR/bins/hfsplus ramdisk.raw rm usr/local/share/restore/options.n90.plist 
$SCRIPT_DIR/bins/hfsplus ramdisk.raw add options.n90.plist usr/local/share/restore/options.k48.plist
echo "Adding untether stuff"
$SCRIPT_DIR/bins/hfsplus ramdisk.raw rm etc/rc.boot
$SCRIPT_DIR/bins/hfsplus ramdisk.raw add $SCRIPT_DIR/bins/rc.boot etc/rc.boot
$SCRIPT_DIR/bins/hfsplus ramdisk.raw chmod 100755 etc/rc.boot
$SCRIPT_DIR/bins/hfsplus ramdisk.raw add $SCRIPT_DIR/bins/exploit.dmg exploit.dmg
$SCRIPT_DIR/bins/img3maker -f ramdisk.raw -o $OUTPUT_NAME/038-4361-021.dmg -t rdsk
rm -rf ramdisk.raw options.n90.plist
echo "Replacing kernelcache with iPhone3,1 7.0 kernelcache"
mv tmp/kernelcache.release.n90 $OUTPUT_NAME/kernelcache.release.k48
rm -rf "tmp"
echo "Finished"




