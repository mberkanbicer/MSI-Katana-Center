<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — Linux-native, safety-gated fans, battery, and keyboard RGB for MSI laptops, verified on Katana 17 B13VGK">
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)

Linux-native, open-source hardware management for MSI laptops. Developed
against the **MSI Katana 17 B13VGK** (board MS-17L5, EC `17L5EMS1.115`) as
the reference device. Rust core, D-Bus daemon, Qt/QML desktop client.

Every hardware write is firmware-gated, Polkit-authorized, opt-in per
feature, read-back-verified, and only enabled after physical verification
on the reference laptop. See [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)
for the rules.

> **AI-assisted development notice:** This project is fully vibecoded —
> every commit was written by an AI coding agent working from the rules
> in [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md), with a
> human directing scope, reviewing changes, and gating every hardware
> write behind explicit confirmation before it ran on real hardware. No
> line of code, design doc, or physical-verification record was
> generated without that human-in-the-loop review. This does not change
> the [Disclaimer](#disclaimer--use-at-your-own-risk) below: use at your
> own risk, and read the safety gates before enabling any write opt-in.

## Live UI

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="System overview: CPU/GPU temperatures, battery charge, fan mode, and live RPM on the Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Page tour of Cooling, Power, Battery, Keyboard RGB, Scenes, and Diagnostics">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Keyboard RGB page with MysticLight MS-1565 zone preview">
</p>

## What it is

A desktop Center and CLI that read EC shift/fan state, temperatures, RPM,
and battery status — and, when you opt in, apply a small set of verified
writes: charge thresholds, fan mode, Cooler Boost, Super Battery,
webcam/Fn keys, and MysticLight RGB.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML UI and CLI talk over D-Bus and Polkit to msi-daemon, which reaches msi-ec, hwmon, the battery interface, and MysticLight RGB">
</p>

## Features

- **Read-only telemetry** — EC shift/fan modes, CPU/GPU temperatures,
  per-core temperature/load, per-GPU temperature/load, fan levels and
  real RPM, battery status and charge thresholds, runtime capability
  reporting
- **Gated, verified writes** — battery charge thresholds, fan mode,
  Cooler Boost, Super Battery, webcam/webcam-block, Fn/Win key swap
- **Keyboard RGB** — MysticLight MS-1565 steady color and effects
  (breathing, cycle, wave), non-persistent by default; flash-save behind
  a separate opt-in
- **Scenes** — named bundles of the gated writes, with CLI and UI
  apply/import/export, starter examples (Quiet / Cool / Battery saver /
  Gaming lights), optional startup/AC-battery/battery-level/schedule
  automation (all opt-in, all UI-owned)
- **System tray** — live temps/RPM tooltip, quick actions, keyboard
  shortcuts (Ctrl+Shift+C/B/L/P)
- **Desktop UI** — seven pages (Overview, Cooling, Power, Battery,
  Keyboard RGB, Scenes, Diagnostics) with a thermal hero card, sticky
  primary actions, a scene-automation accordion, connection/stale
  status, and a queued action banner
- **Community diagnostics** — `msicenter report` with no serial numbers
  for upstream support requests
- **Fake-sysroot fixture** — hardware-free development and testing via
  `MSI_LINUX_CENTER_SYSROOT`

## Install

Builds the release daemon, CLI, and Qt UI, then installs systemd,
Polkit, D-Bus policy, desktop file, and (by default) session autostart.
The shipped systemd unit enables the battery, fan-mode, cooler-boost,
RGB, webcam, webcam-block, and fn-key write opt-ins by default; Super
Battery and RGB flash-save stay off. Every write remains Polkit-gated,
exact-firmware-matched, and read-back/rollback verified in the daemon
regardless of these defaults — edit
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
before installing if you want a fully read-only default.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` does not delete `~/.config/msi-linux-center`. Prefix defaults
to `/usr` (`PREFIX`, `SYSCONFDIR`).

### Requirements

- Rust toolchain (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) + CMake ≥ 3.21
- Linux with `msi-ec` and `msi_wmi_platform` kernel modules for real
  hardware (both read and write paths degrade gracefully when absent)

See [Dependencies](#dependencies) below for the exact system packages and
supported OSes.

### Build from source

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Dependencies

### Supported OSes

Linux only. Developed and tested on Arch Linux and Ubuntu (CI runs on
`ubuntu-latest`); any distro with `systemd`, `Polkit`, D-Bus, Qt 6, and a
recent Rust toolchain should work. The `msi-ec` and `msi_wmi_platform`
kernel modules are required for real-hardware telemetry/writes, but the
project builds and runs read-only (via the fixture) without them.

### Must-have system packages

| Package | Purpose |
|---|---|
| Rust toolchain ≥ 1.75 (`cargo`) | build all Rust crates |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | desktop UI |
| CMake ≥ 3.21 | Qt UI build |
| `pkg-config` | locates `libusb-1.0` at build time |
| `libusb-1.0-0-dev` (dev headers) | RGB HID backend, statically linked at build time |
| `libudev-dev` | hardware/device enumeration |
| `systemd`, `polkit`, `dbus` (runtime) | daemon service, privilege gating, IPC |
| `libusb-1.0-0` (runtime) | RGB HID backend runtime dependency |

Debian/Ubuntu example (matches CI):

```bash
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev
```

Arch example:

```bash
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

### Key Rust crates

`zbus` (D-Bus), `serde`/`serde_json` (data + device profiles), `hidapi`
(statically-linked `linux-static-libusb` backend for MysticLight RGB —
see [FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)).
Full dependency graph: `Cargo.lock` / each crate's `Cargo.toml`.

### Kernel modules used (read/write backends)

- [`msi-ec`](https://github.com/BeardOverflow/msi-ec) — EC semantic
  state, fan modes, Cooler Boost, Super Battery, webcam/Fn key
- `msi_wmi_platform` / hwmon — real fan RPM
- Linux `power_supply` — battery status and charge thresholds

### Projects referenced during development

This project does not vendor or link against these projects' code; they
were used as research/reference material for MSI hardware behavior,
verified independently before any write path was implemented (see
[Safety Model](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)
and [Contributing](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Contributing)).

| Project | Used for |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSI model/firmware knowledge, EC/register research, fan curves, verification methodology |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux MSI EC/sysfs semantics, modes, Cooler Boost, temperatures, fan levels and supported models |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | Comparative Linux MSI feature/UX behavior |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | privilege separation, Polkit concepts, fan control, simulation and recovery |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana Mystic Light USB/HID protocol and 4-zone RGB research |
| [Linux kernel](https://github.com/torvalds/linux) | highest-priority implementation reference for hwmon, power_supply, WMI, ACPI, HID, DRM and platform drivers |

## Run

Against the included fixture (no hardware needed):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

Read-only on the real laptop:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

Do **not** run the CLI with sudo. Privileged writes are performed only by
the daemon after Polkit authorization.

## Write commands (gated)

Each command requires the daemon to run with the matching opt-in
(`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) and completes a Polkit prompt:

```bash
msicenter battery-thresholds START END      # e.g. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # non-persistent
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # persistent flash save (separate opt-in)
msicenter panic-reset                       # Cooler Boost off, Super Battery off, fan auto
msicenter scene list|examples|apply NAME
```

With the opt-in disabled the daemon refuses with `NotSupported`. The
exact support scope, gates, and physical verification records live in
[`docs/dbus-contract.md`](docs/dbus-contract.md) and the
`docs/phase4-*-validation.md` files.

## Safety model

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Six write gates: firmware match, opt-in, Polkit, read-back, physical verification on Katana 17 B13VGK, and no undocumented registers">
</p>

1. **Firmware gate** — writes only run when the device's EC firmware
   exactly matches a physically verified firmware string
2. **Opt-in gate** — every write family is behind its own per-feature
   daemon environment variable; the shipped systemd unit enables
   battery, fan-mode, cooler-boost, RGB, webcam, webcam-block, and
   fn-key by default (Super Battery and RGB flash-save stay off)
3. **Polkit gate** — every D-Bus write method maps to a Polkit action
4. **Read-back verification** — EC and battery writes are read back and
   verified; failed writes roll back
5. **Physical verification** — a write path ships only after it has been
   exercised on the reference laptop and recorded in `docs/`
6. **No guessing** — undocumented registers are never written; provenance
   for every hardware feature is recorded in the device profile

## Supported devices

| Device | Status |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | verified reference device |
| Other MSI laptops with `msi-ec` | read-only telemetry; writes gated by exact firmware match |
| Unmatched models | read-only + diagnostics report; community support via `msicenter report` |

<details>
<summary>Phase status</summary>

| Phase | Scope | Status |
|---|---|---|
| 0 | read-only hardware reconnaissance | complete |
| 1–2 | read-only core, device database, runtime capabilities, fixture | complete |
| 3 | D-Bus daemon, systemd unit, D-Bus policy, Polkit actions | complete |
| 4 | gated semantic writes (battery thresholds, fan mode, Cooler Boost, Super Battery) | complete — physically verified 2026-09-05 |
| 5 | custom fan curves | [design study](docs/phase5-fan-curve-design.md) — no writes until §11 experiment |
| 6 | Qt/QML desktop UI | complete — [design](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` physically verified; effect modes implemented; flash-save implemented, physical test pending |
| 8 | scenes | complete — CLI + UI validated |
| 9 | community diagnostics | complete — [design](docs/phase9-diagnostics.md) |
| 10 | MUX | research only — [notes](docs/deferred-features-research.md) |

</details>

## Documentation

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — D-Bus API contract
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — MysticLight wire protocol
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — RE inventory
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — safety rules for contributors and agents

## Disclaimer — use at your own risk

This software controls laptop hardware through the embedded controller
(EC), battery charge interfaces, and a USB HID RGB controller. Incorrect
writes to these interfaces can cause instability, thermal problems,
reduced battery life, data loss, or hardware/firmware damage.

**This project is provided "as is", without warranty of any kind, express
or implied. The authors and contributors accept no liability whatsoever
for any damage, data loss, or malfunction arising from the use of this
software — including damage to your laptop, battery, keyboard, or any
other hardware.**

Mitigations built into the project (firmware gating, per-feature opt-ins,
Polkit authorization, read-back verification, physical verification on
the reference device) reduce risk but do not eliminate it. They are
best-effort engineering measures, not guarantees.

- Battery thresholds, fan mode, Cooler Boost, RGB, webcam,
  webcam-block, and Fn key writes are **enabled by default** in the
  installed systemd unit (Super Battery and RGB flash-save stay off);
  only install them if you understand what they do, and edit the unit
  file before installing if you want a fully read-only default
- Behavior is physically verified on the **MSI Katana 17 B13VGK**
  (EC `17L5EMS1.115`) only; other models are gated but unverified
- Do not use this software on a laptop you cannot afford to damage, and
  never enable write opt-ins on critical hardware
- If you are unsure, use the read-only telemetry features only

**Be careful. You are solely responsible for any consequences of using
this software.**

## Contributing

Read [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) first.
Hardware write paths require provenance, gating, and physical
verification records — PRs that skip these will not be merged.

## License

Dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE),
at your option.
