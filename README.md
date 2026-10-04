# IMS HIDL 继承修复模块（ims_hidl_fix）

把 OS3(A16) 的双模 IMS 客户端（继承 HIDL 接口）替换到 OS4(A17) 上，一次性替换 `ims.apk` + 配套 6 个 so，激活 thyme 原厂 `vendor.qti.hardware.radio.ims@1.7` HIDL HAL，修复无法通话/收发短信的问题。

## 解决什么

OS4（HyperOS4 / Android 17）移植包的 `/system_ext/priv-app/ims/ims.apk` 是纯 Stable AIDL 客户端，而包里的 vendor 仍是 thyme 原厂（只提供 HIDL `vendor.qti.hardware.radio.ims@1.7`），两者对不上 => IMS 永远注册不上 => 无法通话/收发短信。

## v1.1 改了什么

v1.0 只换 `ims.apk`，结果 OS3 的 Java 代码去加载 OS4 的 `/system_ext/lib64/libimsmedia_jni.so`，`JNI_OnLoad` 返回 `JNI_ERR` -> `org.codeaurora.ims` 每 2 秒崩溃一次（`UnsatisfiedLinkError`），`ImsService` 起不来，IMS 依然注册不上。

v1.1 把 OS3 的配套 so 一并替换（6 个，sha256 见 `SOURCE_SHA256.txt`）：

- `libimsmedia_jni.so`
- `lib-imsvt.so`
- `lib-imsvtutils.so`
- `lib-imsvtextutils.so`
- `lib-imsvideocodec.so`
- `libimscamera_jni.so`

## 安装

1. 用 Magisk / KernelSU / APatch 的 App 刷入本 zip；
2. 重启；
3. 首次开机后看日志：模块目录下的 `fix_log.txt`（路径一般为 `/data/adb/modules/ims_hidl_fix/fix_log.txt`，需 Root 管理器的文件浏览）。

## 验证

- `fix_log.txt` 的 `crash check` 段应为空（无 `UnsatisfiedLinkError`）；
- IMS HAL 日志里应出现 `Initializing IImsRadio HIDL ...` 且之后不再有 `ImsRadio HAL is not available`；
- 真机：设置 -> SIM 卡 -> VoLTE 开启后能注册 IMS、能打电话/发短信。

## 回滚

在 Root 管理器里卸载模块（或删除 `/data/adb/modules/ims_hidl_fix`）后重启即恢复原状。

## 已知风险

1. OS4 原版 `ims.apk` 声明 `sharedUserId=android.uid.qtiphone`，OS3 版本没有；Android 15+ 允许"离开 shared uid"，首次开机已自动 `pm clear` 一次；
2. 替换的 6 个 so 同时会被引用 VT（视频通话）的其它组件看到，风险面与 `ims.apk` 本身同级；
3. `libimscamera_jni.so` 在 OS4 原系统里不存在，是 OS3 侧补进来的，若 OS3 apk 不加载它则无任何影响。

## 下载

请从 [Releases](../../releases) 页面下载最新 zip 刷入。

## 免责声明

刷入即代表你理解本模块会替换系统 IMS 组件，可能影响通话/短信/VoLTE/VoWiFi。风险自负；出问题按上面「回滚」一节恢复原状。
