<p align="center">
  <sub>
    <b>English</b> ·
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
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

# Changelog

All notable changes to this project are documented in this file. The
format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
grouped by development phase rather than strict semantic version
bumps, since this project ships as a rolling snapshot validated
against a single reference device (MSI Katana 17 B13VGK, firmware
`17L5EMS1.115`).

## [Unreleased]

### Added
- Community translations of `README.md` in 12 languages (Chinese,
  Turkish, German, French, Swedish, Italian, Portuguese, Spanish,
  Arabic, Hindi, Japanese, Korean) with a language switcher.
- Translated GitHub wiki pages and this changelog in the same 12
  languages.
- `Dependencies` section in `README.md` documenting required system
  packages, supported OSes, kernel modules, and upstream reference
  projects.
- AI-assisted development ("vibecoded") disclosure notice in
  `README.md`.
- Rust/Platform/Wiki badges and restructured README layout.

### Changed
- Battery threshold, fan-mode, Cooler Boost, RGB, webcam, webcam
  block, and fn-key writes are now enabled **by default** in the
  installed systemd unit (Super Battery and non-volatile RGB save
  remain opt-out).

### Fixed
- Statically linked `hidapi` (`linux-static-libusb` backend) to fix
  CI failures and distro-version linker errors when the system
  `hidapi` package is incompatible.
- CI workflow installs `libhidapi-dev` so the `hidapi` crate builds
  cleanly.
- Corrected the Polkit denial message and added coverage for the
  rollback failure path.

## [0.2.0] — 2026-09-06

### Added
- **Phase 9 — Community diagnostics**: `msicenter report` command
  producing a shareable diagnostic bundle with no serial numbers.
- **Phase 8 — Scenes**: named bundles of gated writes, `scene
  list|examples|apply` CLI commands, example scenes (quiet / cool /
  battery saver / gaming rgb), and a Scenes page in the desktop UI
  with optional automation triggers (boot, AC/battery switch,
  battery level, schedule).
- **Phase 7 — RGB (MysticLight MS-1565)**: read-only HID controller
  probe, protocol packet builder with unit tests, gated non-persistent
  `SetRgbColor` and effect writes (breathing, rainbow, wave), gated
  non-volatile `rgb-save`, and a keyboard RGB page in the desktop UI.
- **Phase 6 — Qt/QML desktop UI**: full seven-page desktop client
  (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes,
  Diagnostics) with a Material-style redesign, sidebar navigation, a
  hero thermal card, per-core CPU/per-GPU detail views, sticky quick
  actions, collapsible automation menus, connection/refresh status,
  and a toast bar for pending actions.
- Per-core CPU temperature/load and per-GPU detail reporting end to
  end (core → daemon → UI).
- System tray icon with live temperature/RPM tooltip, quick actions,
  and keyboard shortcuts (Ctrl+Shift+C/B/L/P).

### Changed
- Unified write-gate checks across daemon write handlers and added
  availability tests.
- Relaxed the `zbus` version pin.

## [0.1.0] — 2026-09-05

### Added
- **Phase 0–2 — Read-only foundation**: hardware discovery, a
  read-only Rust core, device database (`msi-device-db`), runtime
  capability reporting, and a fake-sysroot fixture for hardware-free
  development and testing (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: `msi-daemon` systemd service, D-Bus
  policy, and Polkit actions gating every privileged method.
- **Phase 4 — Safe, gated writes**: battery charge threshold, fan
  mode (auto/silent/advanced), Cooler Boost, and Super Battery write
  paths, each protected by firmware-match gating, a per-feature
  opt-in environment variable, Polkit authorization, and read-back
  verification with rollback on failure. All four write paths were
  physically verified on the MSI Katana 17 B13VGK reference device on
  2026-09-05.
- `msicenter-cli` command-line client (`status`, `capabilities`,
  and the gated write subcommands).
- `MSI-Linux-Center-AGENTS.md` safety rules for contributors and AI
  coding agents.
- Design studies for deferred features: custom fan curves (Phase 5,
  design-only pending a consent-gated EC table rollback experiment)
  and GPU MUX switching (research-only).

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
