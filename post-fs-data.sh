#!/system/bin/sh
# MI10s 通信与屏幕掉帧修复 v2.0 —— 屏幕掉帧/刷新率抖动修复
# （源自「视频帧率修复 v2.0」，逻辑一致）
#
# 根因（已反汇编 + 日志实锤）：
#   本移植包的框架从不上报「视频场景」→ SurfaceFlinger 的 mi_sf 在播放视频时
#   落入「闲置(idle)」分支。该分支先调用 setIdleFps()；若闲置帧率回退值
#   (MiSurfaceFlingerImpl+0x9b8 = ro.vendor.display.idle_default_fps) 为 0，
#   setIdleFps 直接失败 → 改走 rankFrameRates() → 选中 22.5Hz(=90/4) 并长期不回升。
#   充放电过程中来回跳档（“充满一次电才不抖”）也是同一分支所致。
#
# 修法：
#   把 ro.vendor.display.idle_default_fps 设为与正常档相同的 90（并置 support=1），
#   令 setIdleFps 命中 → 闲置分支直接选定 90Hz，不再掉到 22.5Hz。
#
# 在 post-fs-data 阶段执行（SurfaceFlinger 初始化之前），用 resetprop 生效。

MODDIR=${0%/*}
LOGF=/data/local/tmp/mi10sfix_fps.log

# ---- 定位 resetprop（Magisk / KernelSU / APatch 通用）----
RP=""
for c in resetprop /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop /data/adb/ap/bin/resetprop; do
  if [ "$c" = "resetprop" ]; then
    command -v resetprop >/dev/null 2>&1 && { RP=resetprop; break; }
  elif [ -x "$c" ]; then
    RP="$c"; break
  fi
done
if [ -z "$RP" ]; then
  echo "mi10sfix: resetprop not found" > /dev/kmsg
  exit 0
fi

# ---- 读取配置（不存在则用内置默认）----
[ -f "$MODDIR/config.conf" ] && . "$MODDIR/config.conf"
: "${IDLE_DEFAULT_FPS:=90}"

{
  echo "== mi10sfix fps-fix v2.0 $(date) =="
} > "$LOGF" 2>/dev/null
log() { echo "$1" >> "$LOGF" 2>/dev/null; echo "mi10sfix: $1" > /dev/kmsg; }

$RP ro.vendor.display.idle_default_fps "$IDLE_DEFAULT_FPS"
$RP ro.vendor.display.idle_default_fps.support 1
log "set ro.vendor.display.idle_default_fps=${IDLE_DEFAULT_FPS} (readback=$(getprop ro.vendor.display.idle_default_fps))"
log "set ro.vendor.display.idle_default_fps.support=1 (readback=$(getprop ro.vendor.display.idle_default_fps.support))"
log "done"
