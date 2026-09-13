<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <a href="CHANGELOG.sv.md">Svenska</a> ·
    <a href="CHANGELOG.it.md">Italiano</a> ·
    <a href="CHANGELOG.pt.md">Português</a> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <b>日本語</b> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *このファイルはコミュニティ提供の翻訳です。内容に相違がある場合は英語版 `CHANGELOG.md` を正とします。*

# 変更履歴

このプロジェクトにおける注目すべき変更はすべてこのファイルに記録
されています。形式はおおむね [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
に従いますが、このプロジェクトは単一の reference device（MSI
Katana 17 B13VGK、firmware `17L5EMS1.115`）に対して検証された
rolling snapshot として提供されるため、厳密な semantic version
bump ではなく development phase ごとに整理されています。

## [未リリース]

### 追加
- `README.md` の 12 言語（中国語、トルコ語、ドイツ語、フランス語、
  スウェーデン語、イタリア語、ポルトガル語、スペイン語、アラビア語、
  ヒンディー語、日本語、韓国語）への community translations と
  language switcher を追加。
- 同じ 12 言語への GitHub wiki pages とこの changelog の翻訳を追加。
- 必要な system packages、supported OSes、kernel modules、upstream
  reference projects を記載した `README.md` の `Dependencies`
  section を追加。
- `README.md` に AI-assisted development（"vibecoded"）の
  disclosure notice を追加。
- Rust/Platform/Wiki badges と再構成した README layout を追加。

### 変更
- インストールされる systemd unit で、battery threshold、fan-mode、
  Cooler Boost、RGB、webcam、webcam block、fn-key の writes が
  **既定で** 有効になりました（Super Battery と non-volatile RGB save
  は引き続き opt-out）。

### 修正
- system の `hidapi` package が互換でない場合に発生する CI failures
  と distro-version linker errors を修正するため、`hidapi`
  （`linux-static-libusb` backend）を statically link しました。
- `hidapi` crate が問題なく build できるよう、CI workflow が
  `libhidapi-dev` をインストールするようになりました。
- Polkit denial message を修正し、rollback failure path の coverage
  を追加しました。

## [0.2.0] — 2026-09-06

### 追加
- **Phase 9 — Community diagnostics**: serial numbers を含まない
  共有可能な diagnostic bundle を生成する `msicenter report`
  command。
- **Phase 8 — Scenes**: gated writes の named bundles、
  `scene list|examples|apply` CLI commands、example scenes
  （quiet / cool / battery saver / gaming rgb）、そして optional
  automation triggers（boot、AC/battery switch、battery level、
  schedule）を備えた desktop UI の Scenes page。
- **Phase 7 — RGB (MysticLight MS-1565)**: read-only HID controller
  probe、unit tests 付き protocol packet builder、gated
  non-persistent `SetRgbColor` と effect writes（breathing,
  rainbow, wave）、gated non-volatile `rgb-save`、desktop UI の
  keyboard RGB page。
- **Phase 6 — Qt/QML desktop UI**: 7ページ構成の desktop client
  （Overview、Cooling、Power、Battery、Keyboard RGB、Scenes、
  Diagnostics）に、Material-style redesign、sidebar navigation、
  hero thermal card、per-core CPU/per-GPU detail views、sticky
  quick actions、collapsible automation menus、connection/refresh
  status、pending actions 用 toast bar を搭載。
- Per-core CPU temperature/load と per-GPU detail reporting を
  end-to-end で実装（core → daemon → UI）。
- Live temperature/RPM tooltip、quick actions、keyboard shortcuts
  （Ctrl+Shift+C/B/L/P）付きの system tray icon。

### 変更
- Daemon write handlers 全体で write-gate checks を統一し、
  availability tests を追加。
- `zbus` version pin を緩和。

## [0.1.0] — 2026-09-05

### 追加
- **Phase 0–2 — Read-only foundation**: hardware discovery、
  read-only Rust core、device database（`msi-device-db`）、runtime
  capability reporting、hardware-free development/testing のための
  fake-sysroot fixture（`MSI_LINUX_CENTER_SYSROOT`）。
- **Phase 3 — D-Bus daemon**: `msi-daemon` systemd service、D-Bus
  policy、すべての privileged method を gate する Polkit actions。
- **Phase 4 — Safe, gated writes**: battery charge threshold、fan
  mode（auto/silent/advanced）、Cooler Boost、Super Battery の
  write paths。各 path は firmware-match gating、per-feature
  opt-in environment variable、Polkit authorization、failure 時の
  rollback 付き read-back verification で保護されています。
  これら 4 つの write paths は、MSI Katana 17 B13VGK reference
  device で 2026-09-05 に physically verified されました。
- `msicenter-cli` command-line client（`status`、`capabilities`、
  gated write subcommands）。
- Contributors と AI coding agents のための
  `MSI-Linux-Center-AGENTS.md` safety rules。
- Deferred features の design studies: custom fan curves（Phase 5、
  consent-gated EC table rollback experiment 待ちの design-only）
  と GPU MUX switching（research-only）。

[未リリース]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
