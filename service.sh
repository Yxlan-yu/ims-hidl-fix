#!/system/bin/sh
# MI10s 通信与屏幕掉帧修复 v2.0
# 屏幕掉帧/刷新率抖动的修复在 post-fs-data.sh 完成（须在 SurfaceFlinger 之前设属性），
# 本脚本负责两项收尾：
#   (1) 一开机完成就尽早自动「锁屏 -> 亮屏」一次；
#   (2) IMS 修复的收尾诊断：等开机完成 -> 写 fix_log.txt -> 首次开机 pm clear 一次。

MODDIR="${0%/*}"
FIXLOG="$MODDIR/fix_log.txt"
DATAFLAG="$MODDIR/.datareset"

# ---- 读取配置（不存在则用内置默认）----
[ -f "$MODDIR/config.conf" ] && . "$MODDIR/config.conf"
: "${AUTO_LOCK_WAKE:=1}"
: "${LOCK_WAKE_DELAY:=1}"

PKG=org.codeaurora.ims

# 等开机完成（0.3s 一轮，尽快抓到 boot_completed）
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 1000 ]; do
    sleep 0.3
    i=$((i + 1))
done

# ---- (1) 尽早执行：开机后自动「锁屏 -> 亮屏」----
LW=""
if [ "$AUTO_LOCK_WAKE" = "1" ] && command -v input >/dev/null 2>&1; then
    sleep "$LOCK_WAKE_DELAY"
    input keyevent 223   # KEYCODE_SLEEP  熄屏并锁屏
    sleep 1
    input keyevent 224   # KEYCODE_WAKEUP 亮屏（停在锁屏界面）
    LW="auto lock+wake done ($(date), uptime=$(cut -d. -f1 /proc/uptime)s)"
fi

# ---- (2) IMS 诊断（放在锁屏亮屏之后，不影响其时机）----
sleep 5
{
    echo "==== $(date) ===="
    echo "--- mounted apk ---"
    ls -l /system_ext/priv-app/ims/ 2>&1
    echo "--- mounted libs ---"
    ls -l /system_ext/lib64/libimsmedia_jni.so /system_ext/lib64/lib-imsvt.so /system_ext/lib64/lib-imsvtutils.so /system_ext/lib64/lib-imsvtextutils.so /system_ext/lib64/lib-imsvideocodec.so /system_ext/lib64/libimscamera_jni.so 2>&1
    echo "--- pm path ---"
    pm path "$PKG" 2>&1
    echo "--- package info ---"
    dumpsys package "$PKG" 2>/dev/null | grep -E "versionName|userId|codePath|firstInstallTime" | head -8
    echo "--- crash check ---"
    logcat -d -b crash 2>/dev/null | grep -A4 "Process: $PKG" | tail -20
    echo "--- IMS HAL log ---"
    logcat -d 2>/dev/null | grep -E "ImsRadio|imsradio|IImsRadio|MiuiImsReg|ImsServiceController" | grep -v adbd | tail -40
} > "$FIXLOG" 2>&1

if [ ! -f "$DATAFLAG" ]; then
    pm clear "$PKG" > /dev/null 2>&1
    touch "$DATAFLAG"
    echo "pm clear executed (first boot after shared-uid leave)" >> "$FIXLOG"
fi

[ -n "$LW" ] && echo "$LW" >> "$FIXLOG"
exit 0
