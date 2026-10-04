#!/system/bin/sh
ui_print "***************************************"
ui_print "* IMS HIDL 继承修复 v1.1              *"
ui_print "***************************************"
ui_print "- 来源: OS3(A16) /system_ext/priv-app/ims/ims.apk"
ui_print "- 来源: OS3(A16) /system_ext/lib64/libimsmedia_jni + lib-imsvt* (6 个 so)"
ui_print "- 目标: 替换 OS4(A17) 同路径的纯 AIDL 版 ims.apk 及其不配套的 so"
ui_print "- 目的: 连上 thyme vendor 的 IMS HIDL@1.7, 恢复 IMS 通话/短信"
ui_print "- 回滚 = 卸载本模块并重启"
ui_print "- 设置权限..."
set_perm_recursive "$MODPATH/system" 0 0 0755 0644
ui_print "- 完成, 请重启生效"
