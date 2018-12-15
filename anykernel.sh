# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Kernel Sepolicy Patcher by Zackptg5
do.devicecheck=0
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
'; } # end properties

# shell variables
ramdisk_compression=auto;
is_slot_device=auto;
block=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
# chmod -R 750 $ramdisk/*;
# chmod -R 755 $ramdisk/sbin;
# chown -R root:root $ramdisk/*;


## AnyKernel install
ui_print "Unpacking boot image..."
ui_print " "
dump_boot;

# File list
list=""

keytest() {
  ui_print "- Vol Key Test -"
  ui_print "   Press a Vol Key:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > /tmp/anykernel/events) || return 1
  return 0
}

chooseport() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while true; do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > /tmp/anykernel/events
    if (`cat /tmp/anykernel/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat /tmp/anykernel/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $bin/keycheck
  $bin/keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    abort "   Vol key not detected!"
  fi
}

# begin ramdisk changes
if keytest; then
  FUNCTION=chooseport
else
  FUNCTION=chooseportold
  ui_print "   ! Legacy device detected! Using old keycheck method"
  ui_print " "
  ui_print "- Vol Key Programming -"
  ui_print "   Press Vol Up Again:"
  $FUNCTION "UP"
  ui_print "   Press Vol Down"
  $FUNCTION "DOWN"
fi
ui_print " "
ui_print "- Select Sepolicy -"
ui_print "   Vol+ = Enforcing, Vol- = Permissive"
if $FUNCTION; then
  ui_print "   Setting kernel to enforcing..."
  patch_cmdline "androidboot.selinux=permissive" ""
else
  ui_print "   Setting kernel to permissive..."
  patch_cmdline "androidboot.selinux=permissive" "androidboot.selinux=permissive"
fi

# end ramdisk changes
ui_print " "
ui_print "Repacking boot image..."
write_boot;

## end install
