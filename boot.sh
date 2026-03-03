#!/bin/bash

# ---- Resolve script directory ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

$SCRIPT_DIR/bins/pzb -g Firmware/dfu/iBSS.k48ap.RELEASE.dfu https://secure-appldnld.apple.com/iOS5.1.1/041-4292.02120427.Tkk0d/iPad1,1_5.1.1_9B206_Restore.ipsw
$SCRIPT_DIR/bins/pzb -g Firmware/dfu/iBEC.k48ap.RELEASE.dfu https://secure-appldnld.apple.com/iOS5.1.1/041-4292.02120427.Tkk0d/iPad1,1_5.1.1_9B206_Restore.ipsw
$SCRIPT_DIR/bins/pzb -g Firmware/all_flash/all_flash.k48ap.production/DeviceTree.k48ap.img3 https://secure-appldnld.apple.com/iOS5.1.1/041-4292.02120427.Tkk0d/iPad1,1_5.1.1_9B206_Restore.ipsw
$SCRIPT_DIR/bins/pzb -g kernelcache.release.n90 https://secure-appldnld.apple.com/iOS7/091-9485.20130918.Xa98u/iPhone3,1_7.0_11A465_Restore.ipsw
$SCRIPT_DIR/bins/xpwntool iBSS.k48ap.RELEASE.dfu iBSS.dec -iv 9c69f81db931108e8efc268de3f5d94d -k 92f1cc2ca8362740734d69386fa6dde5582e18786777e1f9772d5dd364d873fb
$SCRIPT_DIR/bins/xpwntool iBEC.k48ap.RELEASE.dfu iBEC.dec -iv bde7b0d5cf7861479d81eb23f99d2e9e -k 1ba1f38e6a5b4841c1716c11acae9ee0fb471e50362a3b0dd8d98019f174a2f2
$SCRIPT_DIR/bins/iBoot32Patcher iBSS.dec iBSS.patched --rsa
$SCRIPT_DIR/bins/iBoot32Patcher iBEC.dec iBEC.patched --rsa --ticket --debug -b "serial=3 amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0"
$SCRIPT_DIR/bins/img3maker -f iBSS.patched -o iBSS -t ibss
$SCRIPT_DIR/bins/img3maker -f iBEC.patched -o iBEC -t ibec
rm -rf iBSS.dec iBSS.patched iBEC.dec iBEC.patched
$SCRIPT_DIR/bins/xpwntool DeviceTree.k48ap.img3 DeviceTree.raw -iv e0a3aa63dae431e573c9827dd3636dd1 -k 50208af7c2de617854635fb4fc4eaa8cddab0e9035ea25abf81b0fa8b0b5654f
python3.11 $SCRIPT_DIR/dtre/ddt.py apply DeviceTree.raw DeviceTree.patch $SCRIPT_DIR/dtre/hoodoo_innsbruck.diff
$SCRIPT_DIR/bins/img3maker -f DeviceTree.patch -o DeviceTree -t dtre
rm -rf DeviceTree.raw DeviceTree.patch
$SCRIPT_DIR/bins/ipwnder32 -p
$SCRIPT_DIR/bins/irecovery -f iBSS
sleep 4
$SCRIPT_DIR/bins/irecovery -f iBEC 
sleep 4
$SCRIPT_DIR/bins/irecovery -f DeviceTree
$SCRIPT_DIR/bins/irecovery -c devicetree
$SCRIPT_DIR/bins/irecovery -f kernelcache.release.n90
$SCRIPT_DIR/bins/irecovery -c bootx
