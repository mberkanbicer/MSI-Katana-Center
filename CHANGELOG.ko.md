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
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <b>한국어</b>
  </sub>
</p>

> *이 파일은 커뮤니티가 제공한 번역본입니다. 내용이 상충할 경우 영어 `CHANGELOG.md` 가 기준입니다.*

# 변경 로그

이 프로젝트의 모든 중요한 변경 사항은 이 파일에 기록됩니다. 형식은
대체로 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)을 따르지만,
이 프로젝트는 단일 reference device(MSI Katana 17 B13VGK, firmware
`17L5EMS1.115`)에 대해 검증된 rolling snapshot으로 배포되므로,
엄격한 semantic version bump 대신 development phase 기준으로
정리됩니다.

## [미출시]

### 추가
- `README.md` 에 12개 언어(중국어, 터키어, 독일어, 프랑스어,
  스웨덴어, 이탈리아어, 포르투갈어, 스페인어, 아랍어, 힌디어,
  일본어, 한국어)의 community translations 와 language switcher를
  추가했습니다.
- 동일한 12개 언어로 번역된 GitHub wiki pages 및 이 changelog를
  추가했습니다.
- 필요한 system packages, supported OSes, kernel modules, upstream
  reference projects를 문서화한 `README.md` 의 `Dependencies`
  section을 추가했습니다.
- `README.md` 에 AI-assisted development("vibecoded") disclosure
  notice를 추가했습니다.
- Rust/Platform/Wiki badges 및 재구성된 README layout을 추가했습니다.

### 변경
- 설치되는 systemd unit에서 battery threshold, fan-mode, Cooler
  Boost, RGB, webcam, webcam block, fn-key writes가 이제 **기본적으로**
  활성화됩니다(Super Battery와 non-volatile RGB save는 계속 opt-out).

### 수정
- system `hidapi` package가 호환되지 않을 때 발생하던 CI failures 및
  distro-version linker errors를 해결하기 위해 `hidapi`
  (`linux-static-libusb` backend)를 statically link 했습니다.
- `hidapi` crate가 깔끔하게 build되도록 CI workflow가
  `libhidapi-dev` 를 설치합니다.
- Polkit denial message를 수정하고 rollback failure path에 대한
  coverage를 추가했습니다.

## [0.2.0] — 2026-09-06

### 추가
- **Phase 9 — Community diagnostics**: serial numbers 없는 공유용
  diagnostic bundle을 생성하는 `msicenter report` command.
- **Phase 8 — Scenes**: gated writes의 named bundles,
  `scene list|examples|apply` CLI commands, example scenes
  (quiet / cool / battery saver / gaming rgb), 그리고 optional
  automation triggers(boot, AC/battery switch, battery level,
  schedule)를 갖춘 desktop UI의 Scenes page.
- **Phase 7 — RGB (MysticLight MS-1565)**: read-only HID controller
  probe, unit tests가 있는 protocol packet builder, gated
  non-persistent `SetRgbColor` 및 effect writes(breathing,
  rainbow, wave), gated non-volatile `rgb-save`, 그리고 desktop UI의
  keyboard RGB page.
- **Phase 6 — Qt/QML desktop UI**: 완전한 7페이지 desktop client
  (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes,
  Diagnostics)에 Material-style redesign, sidebar navigation, hero
  thermal card, per-core CPU/per-GPU detail views, sticky quick
  actions, collapsible automation menus, connection/refresh status,
  pending actions용 toast bar를 포함했습니다.
- End-to-end per-core CPU temperature/load 및 per-GPU detail
  reporting(core → daemon → UI).
- Live temperature/RPM tooltip, quick actions, keyboard shortcuts
  (Ctrl+Shift+C/B/L/P)이 있는 system tray icon.

### 변경
- Daemon write handlers 전반의 write-gate checks를 통합하고
  availability tests를 추가했습니다.
- `zbus` version pin을 완화했습니다.

## [0.1.0] — 2026-09-05

### 추가
- **Phase 0–2 — Read-only foundation**: hardware discovery,
  read-only Rust core, device database(`msi-device-db`), runtime
  capability reporting, 하드웨어 없는 development/testing을 위한
  fake-sysroot fixture(`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: `msi-daemon` systemd service, D-Bus
  policy, 모든 privileged method를 gate하는 Polkit actions.
- **Phase 4 — Safe, gated writes**: battery charge threshold, fan
  mode(auto/silent/advanced), Cooler Boost, Super Battery write
  paths. 각 path는 firmware-match gating, 기능별 opt-in
  environment variable, Polkit authorization, failure 시 rollback을
  포함한 read-back verification으로 보호됩니다. 네 가지 write
  path 모두 MSI Katana 17 B13VGK reference device에서 2026-09-05에
  physically verified 되었습니다.
- `msicenter-cli` command-line client(`status`, `capabilities`,
  그리고 gated write subcommands).
- Contributors 및 AI coding agents를 위한
  `MSI-Linux-Center-AGENTS.md` safety rules.
- Deferred features를 위한 design studies: custom fan curves
  (Phase 5, consent-gated EC table rollback experiment 전까지
  design-only) 및 GPU MUX switching(research-only).

[미출시]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
