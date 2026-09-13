<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — 面向 MSI 笔记本电脑的 Linux 原生、安全门控的风扇、电池与键盘 RGB 管理工具，已在 Katana 17 B13VGK 上验证">
</p>

<p align="center">
  <sub>
    <a href="README.md">English</a> ·
    <b>简体中文</b> ·
    <a href="README.tr.md">Türkçe</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.sv.md">Svenska</a> ·
    <a href="README.it.md">Italiano</a> ·
    <a href="README.pt.md">Português</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.ar.md">العربية</a> ·
    <a href="README.hi.md">हिन्दी</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#依赖)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> 本文件为社区提供的翻译版本，如与英文版存在差异，以
> [英文 README](README.md) 为准。

面向 MSI 笔记本电脑的 Linux 原生开源硬件管理工具。以
**MSI Katana 17 B13VGK**（主板 MS-17L5，EC 固件 `17L5EMS1.115`）
作为参考设备进行开发。核心使用 Rust，配备 D-Bus 守护进程与
Qt/QML 桌面客户端。

每一次硬件写入都经过固件匹配门控、Polkit 授权、按功能单独
opt-in、写后回读校验，并且只有在参考笔记本上完成物理验证后
才会启用。规则详见
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)。

> **AI 辅助开发说明：** 本项目完全由 AI 编程代理（vibecoded）
> 完成开发 —— 每一次提交都是 AI 编程代理依据
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) 中的
> 规则编写的，并由人类负责界定范围、审查改动，且在任何硬件写入
> 于真实设备上执行前都需要人类明确确认后才会放行。没有任何一行
> 代码、设计文档或物理验证记录是在缺乏这种人机协同审查的情况下
> 生成的。这并不改变下方的[免责声明](#免责声明--使用风险自负)：
> 使用风险自负，请在启用任何写入 opt-in 之前先阅读安全门控机制。

## 实机界面截图

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="系统概览：Katana 17 上的 CPU/GPU 温度、电池电量、风扇模式与实时转速">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="页面导览：散热、电源、电池、键盘 RGB、场景与诊断">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="键盘 RGB 页面，展示 MysticLight MS-1565 分区预览">
</p>

## 这是什么

一款桌面端 Center 应用与 CLI 工具，可读取 EC 挡位/风扇状态、
温度、转速与电池状态 —— 在你选择启用（opt-in）之后，还能应用
一小组经过验证的写入操作：充电阈值、风扇模式、Cooler Boost、
Super Battery、摄像头/Fn 键，以及 MysticLight RGB。

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML 界面与 CLI 通过 D-Bus 和 Polkit 与 msi-daemon 通信，后者再访问 msi-ec、hwmon、电池接口与 MysticLight RGB">
</p>

## 功能特性

- **只读遥测** —— EC 挡位/风扇模式、CPU/GPU 温度、逐核心
  温度/负载、逐 GPU 温度/负载、风扇挡位与真实转速、电池状态与
  充电阈值、运行时能力上报
- **门控且已验证的写入** —— 电池充电阈值、风扇模式、
  Cooler Boost、Super Battery、摄像头/摄像头屏蔽、Fn/Win 键互换
- **键盘 RGB** —— MysticLight MS-1565 纯色与效果（呼吸、循环、
  波浪），默认非持久化；闪存保存需要单独的 opt-in
- **场景** —— 将门控写入打包为命名场景，支持 CLI 与 UI 的
  应用/导入/导出，内置示例（安静 / 制冷 / 省电 / 游戏灯光），
  可选的开机启动/交流电-电池切换/电量阈值/定时自动化
  （全部为 opt-in，且全部由 UI 管理）
- **系统托盘** —— 实时温度/转速提示、快捷操作、键盘快捷键
  （Ctrl+Shift+C/B/L/P）
- **桌面界面** —— 七个页面（概览、散热、电源、电池、键盘 RGB、
  场景、诊断），包含温度概览卡片、常驻主操作按钮、场景自动化
  折叠面板、连接/过期状态提示，以及排队操作横幅
- **社区诊断** —— `msicenter report` 不含任何序列号，
  便于提交上游支持请求
- **虚拟 sysroot 测试环境** —— 通过 `MSI_LINUX_CENTER_SYSROOT`
  实现无需真实硬件的开发与测试

## 安装

会构建 release 版本的守护进程、CLI 与 Qt 界面，然后安装
systemd、Polkit、D-Bus 策略、桌面文件，并（默认）配置会话
自启动。随附的 systemd 单元默认启用电池、风扇模式、
Cooler Boost、RGB、摄像头、摄像头屏蔽与 Fn 键写入 opt-in；
Super Battery 与 RGB 闪存保存保持关闭。无论这些默认设置如何，
每一次写入在守护进程中仍会经过 Polkit 门控、精确固件匹配，以及
写后回读/回滚验证 —— 如果你希望默认完全只读，请在安装前编辑
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)。

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` 不会删除 `~/.config/msi-linux-center`。安装前缀默认为
`/usr`（可通过 `PREFIX`、`SYSCONFDIR` 环境变量修改）。

### 环境要求

- Rust 工具链（≥ 1.75）
- Qt 6（Core、QML、Quick、DBus、QuickControls2、Widgets）+
  CMake ≥ 3.21
- 若要在真实硬件上运行，需要 Linux 内核模块 `msi-ec` 与
  `msi_wmi_platform`（缺失时读写路径均会优雅降级）

具体的系统软件包与支持的操作系统详见下方的[依赖](#依赖)部分。

### 从源代码构建

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## 运行

针对内置测试环境运行（无需真实硬件）：

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

在真实笔记本上以只读模式运行：

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

**请勿**使用 `sudo` 运行 CLI。特权写入操作只会由守护进程在
Polkit 授权之后执行。

## 写入命令（门控）

每条命令都要求守护进程在启动时启用对应的 opt-in
（`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`），并需要完成一次
Polkit 授权提示：

```bash
msicenter battery-thresholds START END      # 例如 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # 非持久化
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # 持久化闪存保存（单独的 opt-in）
msicenter panic-reset                       # 关闭 Cooler Boost、关闭 Super Battery、风扇恢复自动
msicenter scene list|examples|apply NAME
```

若对应 opt-in 未启用，守护进程会以 `NotSupported` 拒绝执行。
具体的支持范围、门控条件与物理验证记录见
[`docs/dbus-contract.md`](docs/dbus-contract.md) 与
`docs/phase4-*-validation.md` 系列文件。

## 安全模型

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="六重写入门控：固件匹配、opt-in、Polkit、写后回读、在 Katana 17 B13VGK 上的物理验证、以及禁止写入未记录的寄存器">
</p>

1. **固件门控** —— 只有当设备 EC 固件与经过物理验证的固件
   字符串完全匹配时，写入才会执行
2. **Opt-in 门控** —— 每一类写入都由各自独立的守护进程环境
   变量控制；随附的 systemd 单元默认启用电池、风扇模式、
   Cooler Boost、RGB、摄像头、摄像头屏蔽与 Fn 键
   （Super Battery 与 RGB 闪存保存保持关闭）
3. **Polkit 门控** —— 每个 D-Bus 写入方法都对应一个 Polkit
   动作
4. **写后回读验证** —— EC 与电池写入操作都会被回读并校验；
   失败的写入会自动回滚
5. **物理验证** —— 写入路径只有在参考笔记本上实际验证并记录于
   `docs/` 之后才会发布
6. **绝不猜测** —— 从不写入未文档化的寄存器；每一项硬件功能的
   来源都记录在设备档案中

## 支持的设备

| 设备 | 状态 |
|---|---|
| MSI Katana 17 B13VGK（MS-17L5，EC `17L5EMS1.115`） | 已验证的参考设备 |
| 其他支持 `msi-ec` 的 MSI 笔记本 | 仅只读遥测；写入功能由精确固件匹配门控 |
| 未匹配的型号 | 仅只读 + 诊断报告；可通过 `msicenter report` 获得社区支持 |

<details>
<summary>阶段状态</summary>

| 阶段 | 范围 | 状态 |
|---|---|---|
| 0 | 只读硬件侦察 | 已完成 |
| 1–2 | 只读核心、设备数据库、运行时能力、测试环境 | 已完成 |
| 3 | D-Bus 守护进程、systemd 单元、D-Bus 策略、Polkit 动作 | 已完成 |
| 4 | 门控语义写入（电池阈值、风扇模式、Cooler Boost、Super Battery） | 已完成 —— 已于 2026-09-05 物理验证 |
| 5 | 自定义风扇曲线 | [设计研究](docs/phase5-fan-curve-design.md) —— 在完成 §11 实验前不会编写写入代码 |
| 6 | Qt/QML 桌面界面 | 已完成 —— [设计文档](docs/phase6-ui-design.md) |
| 7 | RGB（MysticLight MS-1565） | `SetRgbColor` 已物理验证；效果模式已实现；闪存保存已实现，物理测试待完成 |
| 8 | 场景 | 已完成 —— CLI 与 UI 均已验证 |
| 9 | 社区诊断 | 已完成 —— [设计文档](docs/phase9-diagnostics.md) |
| 10 | MUX（显卡直连切换） | 仅研究阶段 —— [笔记](docs/deferred-features-research.md) |

</details>

## 文档

- [`docs/dbus-contract.md`](docs/dbus-contract.md) —— D-Bus API 契约
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) —— MysticLight 通信协议
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) —— 逆向工程清单
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) —— 面向贡献者与 AI 代理的安全规则
- [项目 Wiki](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) —— 可浏览版本的安装、安全模型、D-Bus API 与常见问题

## 依赖

**支持的操作系统** —— 仅限 Linux。已在 Arch Linux 与 Ubuntu 上
开发和测试（CI 运行于 `ubuntu-latest`）；任何具备 `systemd`、
Polkit、D-Bus、Qt 6 与较新 Rust 工具链的发行版理论上都可以使用。
若要获取真实硬件的遥测/写入功能，需要 `msi-ec` 与
`msi_wmi_platform` 内核模块 —— 缺少它们时项目仍可构建，并可通过
测试环境以只读方式运行。

**必需的系统软件包**

| 软件包 | 用途 |
|---|---|
| Rust 工具链 ≥ 1.75（`cargo`） | 构建所有 Rust crate |
| Qt 6 ≥ 6.4（Core、Gui、Qml、Quick、DBus、QuickControls2、Widgets） | 桌面界面 |
| CMake ≥ 3.21 | 构建 Qt 界面 |
| `pkg-config` | 构建时定位 `libusb-1.0` |
| `libusb-1.0-0-dev`（开发头文件） | RGB HID 后端，构建时静态链接 |
| `libudev-dev` | 硬件/设备枚举 |
| `systemd`、`polkit`、`dbus`（运行时） | 守护进程服务、权限门控、进程间通信 |
| `libusb-1.0-0`（运行时） | RGB HID 后端的运行时依赖 |

```bash
# Debian/Ubuntu（与 CI 一致）
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**关键 Rust crate** —— `zbus`（D-Bus）、`serde`/`serde_json`
（数据与设备档案）、`hidapi`（用于 MysticLight RGB 的静态链接
`linux-static-libusb` 后端 —— 如果发行版自带的 `hidapi` 包导致
链接错误，参见
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)）。
完整依赖图见 `Cargo.lock` 及各 crate 的 `Cargo.toml`。

**使用到的内核模块** —— [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
（EC 语义状态、风扇模式、Cooler Boost、Super Battery、摄像头/Fn 键）、
`msi_wmi_platform`/hwmon（真实风扇转速）、Linux `power_supply`
（电池状态与充电阈值）。

**开发过程中参考的项目** —— 仅作为研究/参考资料使用；本项目
未引用或链接这些项目的代码，且每一条写入路径在上线前都经过独立
验证（详见
[安全模型](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)）：

| 项目 | 用途 |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSI 型号/固件知识、EC/寄存器研究、风扇曲线、验证方法 |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux MSI EC/sysfs 语义、各挡位、Cooler Boost、温度、风扇挡位与支持型号 |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | Linux 下 MSI 功能/交互行为对比参考 |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | 权限分离、Polkit 概念、风扇控制、模拟与恢复 |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana MysticLight USB/HID 协议与 4 分区 RGB 研究 |
| [Linux 内核](https://github.com/torvalds/linux) | hwmon、power_supply、WMI、ACPI、HID、DRM 及平台驱动的最高优先级实现参考 |

## 免责声明 —— 使用风险自负

本软件通过嵌入式控制器（EC）、电池充电接口，以及 USB HID RGB
控制器来控制笔记本硬件。对这些接口的错误写入可能导致系统不
稳定、发热问题、电池寿命下降、数据丢失，或硬件/固件损坏。

**本项目按“原样”提供，不附带任何明示或暗示的担保。作者与贡献者
对因使用本软件而产生的任何损害、数据丢失或故障（包括对你的
笔记本、电池、键盘或任何其他硬件造成的损坏）不承担任何责任。**

项目内置的缓解措施（固件门控、按功能划分的 opt-in、Polkit
授权、写后回读验证、在参考设备上的物理验证）可以降低风险，
但无法消除风险。它们是尽力而为的工程措施，而非任何形式的保证。

- 电池阈值、风扇模式、Cooler Boost、RGB、摄像头、摄像头屏蔽与
  Fn 键写入在安装的 systemd 单元中**默认启用**（Super Battery
  与 RGB 闪存保存保持关闭）；只有在你了解这些功能的作用后才应
  安装，如需完全只读的默认设置，请在安装前编辑该单元文件
- 相关行为仅在 **MSI Katana 17 B13VGK**（EC `17L5EMS1.115`）
  上经过物理验证；其他型号虽有门控但未经验证
- 请勿在你无法承受损坏后果的笔记本上使用本软件，也不要在关键
  硬件上启用写入 opt-in
- 如果你不确定，请只使用只读遥测功能

**请务必小心。使用本软件所产生的一切后果由你自行承担。**

## 贡献指南

请先阅读 [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)。
硬件写入路径需要提供来源说明、门控机制与物理验证记录 ——
缺少这些内容的 PR 将不会被合并。

## 许可证

采用 [MIT](LICENSE-MIT) 或 [Apache-2.0](LICENSE-APACHE) 双重许可，
可自行选择。
