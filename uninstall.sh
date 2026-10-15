#!/system/bin/sh
# MI10s 通信与屏幕掉帧修复 v2.0 —— 卸载时还原帧率属性
# （注：resetprop 修改为运行时属性，重启后自动消失；此处为即时还原。）

MODDIR=${0%/*}

RP=""
for c in resetprop /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop /data/adb/ap/bin/resetprop; do
  if [ "$c" = "resetprop" ]; then
    command -v resetprop >/dev/null 2>&1 && { RP=resetprop; break; }
  elif [ -x "$c" ]; then
    RP="$c"; break
  fi
done
[ -z "$RP" ] && exit 0

$RP --delete ro.vendor.display.idle_default_fps
$RP --delete ro.vendor.display.idle_default_fps.support
echo "mi10sfix: fps props restored" > /dev/kmsg
