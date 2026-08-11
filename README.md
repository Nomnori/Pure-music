# Pure Music（Fork）

<p align="center">
  <img src="app_icon.png" width="80" height="80" alt="Pure Music Logo">
</p>

<p align="center">
  基于上游项目的 Windows 本地音乐播放器 Fork
</p>

<p align="center">
  <a href="https://github.com/Nomnori/Pure-music"><img src="https://img.shields.io/badge/Repo-Nomnori%2FPure--music-blue?style=flat-square" alt="Fork Repo"></a>
  <a href="https://github.com/qingyueyin/Pure-music"><img src="https://img.shields.io/badge/Upstream-qingyueyin%2FPure--music-lightgrey?style=flat-square" alt="Upstream"></a>
  <img src="https://img.shields.io/badge/Platform-Windows-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/License-GPL--3.0-green?style=flat-square" alt="License">
</p>

本仓库是 [qingyueyin/Pure-music](https://github.com/qingyueyin/Pure-music) 的 Fork，由 [Nomnori](https://github.com/Nomnori) 维护。

上游是完整的本地音乐播放器；本 Fork 在保留原有功能的基础上，主要补充 Windows 播放设备与音量相关能力，并自行构建发布。

- **上游仓库**：https://github.com/qingyueyin/Pure-music
- **上游文档**：仓库内 `page/docs/guide/`
- **本 Fork 问题反馈**：请在本仓库提 Issue

---

## 本 Fork 的改动

相对上游，当前分支主要包含：

| 方向 | 说明 |
|------|------|
| 播放设备选择 | 设置 → 高级 → 播放设备，枚举系统输出设备并切换 BASS 输出 |
| 设备名显示 | 通过 Rust MMDevice 读取设备友好名，避免乱码 |
| 设备匹配 | 用 BASS `driver` 与 Windows endpoint ID 对齐，切换后声音走正确通道 |
| 系统音量 | 改用 Rust WASAPI 控制，替代插件方案，减少 COM 冲突 |
| 音量界面 | 音量调节改为 Dialog，拖动时延迟落盘，修复闪退与卡顿 |
| 设置页稳定性 | 修复高级设置 Tab 与部分控件触发的布局崩溃 |

完整提交记录见 [feat/output-device-selection](https://github.com/Nomnori/Pure-music/tree/feat/output-device-selection) 分支。

---

## 下载与使用

本 Fork **暂无 GitHub Release**。需要可直接使用本地打包产物，或自行编译：

- 便携版 zip：`output/pure_music_2.2.0_release_portable.zip`（本地构建后生成）
- 上游正式版：见 [qingyueyin/Pure-music Releases](https://github.com/qingyueyin/Pure-music/releases)

便携版解压后运行 `pure_music.exe`，数据保存在 exe 同级 `data/` 目录。

---

## 界面预览

界面与上游一致，截图仅供预览参考。

<details>
<summary>展开截图</summary>

**深色模式**

<img src="screenshot/深色主页.png" width="380" alt="深色主页">
<img src="screenshot/深色播放页.png" width="380" alt="深色播放页">

**浅色模式**

<img src="screenshot/浅色主页.png" width="380" alt="浅色主页">
<img src="screenshot/浅色播放页.png" width="380" alt="浅色播放页">

**曲库与歌词**

<img src="screenshot/歌单页.png" width="330" alt="歌单页">
<img src="screenshot/左对齐主题色歌词.png" width="330" alt="桌面歌词">

</details>

---

## 功能概览

继承上游能力，包括但不限于：

- Material You 界面、封面取色、流光背景、沉浸模式
- 多格式歌词（TTML / LRC / 增强 LRC 等）与在线歌词源
- 10 段 EQ、音调 / 变速、WASAPI 独占、ReplayGain
- 本地曲库、歌单、统计、SMTC、全局快捷键

本 Fork 额外强调：

- **播放设备选择**
- **Rust WASAPI 系统音量** + 应用音量独立调节

快捷键：`Space` 播放/暂停，`Ctrl + ←/→` 切歌，`Ctrl + ↑/↓` 应用音量，`F1` 沉浸模式。

---

## 开发与构建

### 环境

- Flutter ≥ 3.38.4
- Rust / Cargo
- Windows 10+

### 日常开发

```powershell
flutter pub get
flutter run -d windows

# 修改 Rust 后
flutter_rust_bridge_codegen generate
```

### 打包

```powershell
# 便携版 zip
.\build_windows.ps1 -Version 2.2.0 -Mode 2 -NonInteractive

# 安装版（需 Inno Setup 6/7）
.\build_windows.ps1 -Version 2.2.0 -Mode 3 -NonInteractive
```

| 模式 | 作用 |
|------|------|
| 1 | 编译便携版（仅文件夹） |
| 2 | 编译便携版并打 zip |
| 3 | 编译并制作安装器 |
| 4 | 跳过编译，打包已有 Release 产物 |
| 5 | 跳过编译，制作安装器 |

产物输出到 `output/`。更完整的构建说明见 `page/docs/dev/build.md`。

### Windows 符号链接

若提示 `Building with plugins requires symlink support`：

1. 打开 **设置 → 隐私和安全性 → 开发者选项 → 开发人员模式**（推荐）
2. 或以管理员身份运行终端

也可先手动建立插件 junction，再 `flutter build windows --release`，最后用 `-Mode 4` 仅打包。

---

## 致谢

- 原项目：[qingyueyin/Pure-music](https://github.com/qingyueyin/Pure-music)
- 更早渊源：[coriander_player](https://github.com/Ferry-200/coriander_player)
- 主要依赖：BASS、Flutter、flutter_rust_bridge、lofty、window_manager 等

上游贡献者见 [qingyueyin/Pure-music/graphs/contributors](https://github.com/qingyueyin/Pure-music/graphs/contributors)。

---

## License

本项目继承上游 **GNU General Public License v3.0**。

- 使用或修改时请遵守 GPL-3.0
- 请注明出处：本 Fork 链接与上游 [qingyueyin/Pure-music](https://github.com/qingyueyin/Pure-music) 链接

---

## 免责声明

- 本项目为开源学习用途，软件不包含任何音乐或歌词版权内容
- 在线歌词数据来自第三方平台，仅供个人学习参考
- 使用本软件产生的法律问题由使用者自行承担

---

<div align="center">
  Fork maintained by <a href="https://github.com/Nomnori">Nomnori</a><br>
  Based on <a href="https://github.com/qingyueyin/Pure-music">qingyueyin/Pure-music</a>
</div>
