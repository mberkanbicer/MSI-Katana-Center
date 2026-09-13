<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <b>简体中文</b> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <a href="CHANGELOG.sv.md">Svenska</a> ·
    <a href="CHANGELOG.it.md">Italiano</a> ·
    <a href="CHANGELOG.pt.md">Português</a> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *此文件为社区提供的翻译。如有任何歧义或冲突，以英文版 `CHANGELOG.md` 为准。*

# 更新日志

本文件记录了该项目的所有重要变更。格式大体遵循 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，但分组依据是开发阶段，而不是严格的语义版本升级，因为该项目以滚动快照的方式发布，并针对单一参考设备（MSI Katana 17 B13VGK，固件 `17L5EMS1.115`）进行验证。

## [Unreleased]

### 新增
- `README.md` 的 12 种语言社区翻译（中文、土耳其语、德语、法语、瑞典语、意大利语、葡萄牙语、西班牙语、阿拉伯语、印地语、日语、韩语），并附带语言切换器。
- GitHub wiki 页面以及本更新日志的同样 12 种语言译文。
- `README.md` 中新增 `Dependencies` 部分，记录所需系统包、支持的操作系统、内核模块以及上游参考项目。
- 在 `README.md` 中加入 AI-assisted development（“vibecoded”）披露说明。
- 新增 Rust/Platform/Wiki 徽章，并重构 README 布局。

### 变更
- 在安装后的 systemd 单元中，battery threshold、fan-mode、Cooler Boost、RGB、webcam、webcam block 以及 fn-key 写入现在**默认启用**（Super Battery 和非易失性 RGB save 仍为可选择关闭）。

### 修复
- 将 `hidapi` 静态链接（`linux-static-libusb` 后端），以修复当系统 `hidapi` 包不兼容时出现的 CI 失败和发行版版本相关的链接错误。
- CI 工作流安装 `libhidapi-dev`，使 `hidapi` crate 能够干净构建。
- 修正了 Polkit 拒绝消息，并为回滚失败路径增加了覆盖。

## [0.2.0] — 2026-09-06

### 新增
- **Phase 9 — 社区诊断**：`msicenter report` 命令，生成不包含序列号、可共享的诊断包。
- **Phase 8 — 场景**：受门控写入的具名组合，`scene list|examples|apply` CLI 命令，示例场景（quiet / cool / battery saver / gaming rgb），以及桌面 UI 中带有可选自动触发器（启动、交流电/电池切换、电池电量、定时）的 Scenes 页面。
- **Phase 7 — RGB (MysticLight MS-1565)**：只读 HID 控制器探测、带单元测试的协议数据包构建器、受门控的非持久化 `SetRgbColor` 和效果写入（breathing、rainbow、wave）、受门控的非易失性 `rgb-save`，以及桌面 UI 中的键盘 RGB 页面。
- **Phase 6 — Qt/QML desktop UI**：完整的七页桌面客户端（Overview、Cooling、Power、Battery、Keyboard RGB、Scenes、Diagnostics），具有 Material 风格重设计、侧边栏导航、主视觉散热卡片、按核心 CPU / 按 GPU 的详细视图、固定快速操作、可折叠自动化菜单、连接/刷新状态，以及用于待处理操作的提示条。
- 端到端的按核心 CPU 温度/负载和按 GPU 详细信息报告（core → daemon → UI）。
- 带实时温度/RPM 工具提示、快速操作和键盘快捷键（Ctrl+Shift+C/B/L/P）的系统托盘图标。

### 变更
- 统一了守护进程写入处理程序中的写入门控检查，并增加了可用性测试。
- 放宽了 `zbus` 的版本固定限制。

## [0.1.0] — 2026-09-05

### 新增
- **Phase 0–2 — 只读基础**：硬件发现、只读 Rust 核心、设备数据库（`msi-device-db`）、运行时能力报告，以及用于无硬件开发和测试的 fake-sysroot fixture（`MSI_LINUX_CENTER_SYSROOT`）。
- **Phase 3 — D-Bus daemon**：`msi-daemon` systemd 服务、D-Bus policy，以及为每个特权方法设置门控的 Polkit actions。
- **Phase 4 — 安全、受门控的写入**：电池充电阈值、风扇模式（auto/silent/advanced）、Cooler Boost 和 Super Battery 写入路径；每条路径都受到固件匹配门控、按功能单独选择加入环境变量、Polkit 授权，以及失败时带回滚的回读验证保护。四条写入路径均已于 2026-09-05 在 MSI Katana 17 B13VGK 参考设备上完成物理验证。
- `msicenter-cli` 命令行客户端（`status`、`capabilities` 以及受门控的写入子命令）。
- 面向贡献者和 AI 编码代理的 `MSI-Linux-Center-AGENTS.md` 安全规则。
- 延后特性的设计研究：自定义风扇曲线（Phase 5，在完成同意门控的 EC 表回滚实验之前仅限设计）和 GPU MUX 切换（仅研究）。

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
