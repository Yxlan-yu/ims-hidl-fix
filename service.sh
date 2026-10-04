#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/fix_log.txt"
PKG=org.codeaurora.ims

i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 2
  i=$((i + 1))
done
sleep 10

{
  echo "==== $(date) ===="
  echo "--- mounted apk ---"
  ls -l /system_ext/priv-app/ims/ 2>&1
  echo "--- mounted libs ---"
  ls -l /system_ext/lib64/libimsmedia_jni.so /system_ext/lib64/lib-imsvt.so /system_ext/lib64/lib-imsvtutils.so /system_ext/lib64/lib-imsvtextutils.so /system_ext/lib64/lib-imsvideocodec.so 2>&1
  echo "--- pm path ---"
  pm path "$PKG" 2>&1
  echo "--- package info ---"
  dumpsys package "$PKG" 2>/dev/null | grep -E "versionName|userId|codePath|firstInstallTime" | head -8
  echo "--- crash check ---"
  logcat -d -b crash 2>/dev/null | grep -A4 "Process: $PKG" | tail -20
  echo "--- IMS HAL log ---"
  logcat -d 2>/dev/null | grep -E "ImsRadio|imsradio|IImsRadio|MiuiImsReg|ImsServiceController|UnsatisfiedLinkError" | tail -40
} > "$LOG" 2>&1

if [ ! -f "$MODDIR/.datareset" ]; then
  pm clear "$PKG" > /dev/null 2>&1
  touch "$MODDIR/.datareset"
  echo "pm clear executed (first boot after shared-uid leave)" >> "$LOG"
fi
