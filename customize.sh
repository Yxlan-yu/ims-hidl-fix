#!/system/bin/sh
# MI10s 通信与屏幕掉帧修复 v2.0 — 安装脚本（KernelSU / Magisk 通用）
SKIPUNZIP=0

# ---- 安装器兼容：缺什么函数自带兜底 ----
command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }
command -v abort    >/dev/null 2>&1 || abort()    { echo "$1"; exit 1; }
command -v set_perm >/dev/null 2>&1 || set_perm() { chown "$2:$3" "$1" 2>/dev/null; chmod "$4" "$1" 2>/dev/null; }
command -v set_perm_recursive >/dev/null 2>&1 || set_perm_recursive() {
    chown -R "$2:$3" "$1" 2>/dev/null
    find "$1" -type d -exec chmod "$4" {} + 2>/dev/null
    find "$1" -type f -exec chmod "$5" {} + 2>/dev/null
}

ui_print ""
ui_print "********************************************"
ui_print "*   MI10s 通信与屏幕掉帧修复  v2.0         *"
ui_print "********************************************"
ui_print "- 适用: 小米10s (thyme) HyperOS4 4.0.15.0"
ui_print "-"
ui_print "- 面对的现象:"
ui_print "-   1. 屏幕掉帧/刷新率抖动: 看视频掉到 22.5Hz 不回升,"
ui_print "-      滑动掉帧, 充放电时 60/90 来回跳"
ui_print "-   2. 无法通话/收发短信: IMS 注册不上"
ui_print "-"
ui_print "- 修复原理:"
ui_print "-   1. SurfaceFlinger 启动前把闲置帧率回退值钉为 90Hz,"
ui_print "-      令 setIdleFps 命中, 不再掉 22.5Hz 与来回跳档"
ui_print "-      配置: /data/adb/modules/mi10sfix/config.conf"
ui_print "-   2. 把 IMS 客户端换回含 HIDL 回退的版本并接通原厂"
ui_print "-      HIDL@1.7 HAL, 恢复 IMS 注册"
ui_print "-"
ui_print "- 附带: 开机后自动「锁屏 -> 亮屏」一次"
ui_print "- 兼容: KernelSU / Magisk"
ui_print "- 设置权限..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/system" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
# 清理历史版本残留的开关/flag 文件（若有）
rm -f "$MODPATH"/boot_fake_active "$MODPATH"/manual_fake_active "$MODPATH"/active "$MODPATH"/real_bat 2>/dev/null
ui_print "- 完成, 请重启生效"
ui_print "- 若已装过会修改相同项目的旧模块, 建议先卸载后再刷入"
