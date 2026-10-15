# MI10s 通信与屏幕掉帧修复（mi10sfix）

针对小米 10s（thyme）HyperOS4 4.0.15.0 移植包的两个系统级问题的修复模块，兼容 **KernelSU / Magisk**。

- **适用**：小米 10s（thyme），HyperOS4 4.0.15.0 移植包（Android 17）
- **作者**：Yxlan-yu
- **版本**：v2.0

## 解决什么

### 一、屏幕掉帧 / 刷新率抖动

- 看视频时画面帧率掉到 22.5Hz，且长期不回升，越看越卡；
- 滑动列表、刷桌面时一顿一顿地掉帧、刷新率抖动；
- 充电 / 放电过程中刷新率在 60 与 90 之间来回跳，要充满一次电之后才不抖。

**原因**：本移植包框架没有向 SurfaceFlinger 的 mi_sf 上报“视频场景”，播放视频时界面落入“闲置(idle)”分支。该分支会先调用 `setIdleFps()` 去取“闲置帧率回退值”（属性 `ro.vendor.display.idle_default_fps`）；该回退值默认为 0，取不到 → `setIdleFps` 直接失败 → 改走通用排序，于是选中 22.5Hz（= 90/4）并长期不回升。充电 / 放电时同样落入该分支，导致刷新率在 60 / 90 之间来回跳。

**修复**：在 SurfaceFlinger 启动之前（post-fs-data 阶段）用 resetprop 把 `ro.vendor.display.idle_default_fps` 设为 90、`.support` 设为 1，令 `setIdleFps` 直接命中 → 闲置分支选定 90Hz，不再掉 22.5Hz，也不再 60/90 抖动。

- 档位可配：`/data/adb/modules/mi10sfix/config.conf` 的 `IDLE_DEFAULT_FPS`（默认 90）；
- 日志：`/data/local/tmp/mi10sfix_fps.log`。

### 二、无法通话 / 收发短信

- 拨号、收发短信、VoLTE 全部不可用，IMS 注册不上。

**原因**：OS4（A17）自带的 `ims.apk` 是纯 Stable AIDL 客户端，而包内 vendor 仍是 thyme 原厂栈（只提供 HIDL `ims@1.7`），两者接口对不上 → IMS 注册不上，通话、短信全不可用。

**修复**：把 IMS 客户端换回带 HIDL 回退的版本，并同步替换其配套的 6 个 so，接通原厂 HIDL@1.7 HAL，恢复 IMS 注册；首次开机自动做一次数据清理，保证注册正常。

- 来源文件校验见 `SOURCE_SHA256.txt`；
- 日志：`/data/adb/modules/mi10sfix/fix_log.txt`。

### 附带动作

开机后自动执行一次「锁屏 → 亮屏」，帮助显示 / 刷新率状态在开机后立即归位（可在 `config.conf` 中设 `AUTO_LOCK_WAKE=0` 关闭）。

## 安装

1. 用 KernelSU / Magisk 管理器刷入本 zip；
2. 重启；
3. 若已装过会修改相同项目的旧模块，建议先卸载后再刷入，避免设置重复冲突。

## 验证

- **掉帧**：播放一段视频，帧率应稳定在 90Hz，不再跳 22.5Hz；`mi10sfix_fps.log` 里可看到 `idle_default_fps=90` 的回读值。
- **通信**：`fix_log.txt` 的 `crash check` 段应为空（无崩溃）；IMS HAL 日志出现 `Initializing IImsRadio HIDL ...`，不再有 `ImsRadio HAL is not available`。
- **真机**：VoLTE 开启后能注册 IMS，能打电话 / 发短信。

## 回滚

- 帧率：卸载本模块并重启（resetprop 属性随重启消失）；临时可编辑 `config.conf` 后重启，或直接改档位。
- IMS：卸载本模块并重启，全部恢复原状。

## 已知风险

1. IMS 客户端未声明原系统的 `sharedUserId`，首次开机已自动清理一次数据（Android 15+ 允许离开 shared uid）；
2. 同步替换的 6 个 so 会被视频通话组件一并引用，风险面与 `ims.apk` 本身同级；
3. 其中 `libimscamera_jni.so` 为来源侧新增文件，若客户端不加载它则无任何影响；
4. 掉帧修复只改运行时属性，不改任何 .so / 分区文件，可随时回滚。

## 下载

请从 [Releases](../../releases) 页面下载最新 zip 刷入。

## 免责声明

刷入即代表你理解本模块会修改系统 IMS 组件与显示相关运行时属性，可能影响通话 / 短信 / VoLTE / 显示刷新率。风险自负；出问题按上面「回滚」一节恢复原状。
