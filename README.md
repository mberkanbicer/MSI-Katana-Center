# MSI Linux Center

Linux-native, open-source hardware management for MSI laptops, developed
against the MSI Katana 17 B13VGK (board MS-17L5, EC `17L5EMS1.115`) as the
reference device. Rust core + D-Bus daemon + Qt/QML desktop client.

Safety-first: every hardware write is firmware-gated, Polkit-authorized,
opt-in per feature, read-back-verified, and only enabled after physical
verification on the reference laptop. See
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) for the rules.

## Phase status

| Phase | Scope | Status |
|---|---|---|
| 0 | read-only hardware reconnaissance | complete |
| 1–2 | read-only core, device database, runtime capabilities, fixture | complete |
| 3 | D-Bus daemon, systemd unit, D-Bus policy, Polkit actions | complete |
| 4 | gated semantic writes (battery thresholds, fan mode, Cooler Boost, Super Battery) | complete — all physically verified 2026-09-05 |
| 5 | custom fan curves | design study: [`docs/phase5-fan-curve-design.md`](docs/phase5-fan-curve-design.md) — no writes until §11 experiment |
| 6 | Qt/QML desktop UI | Material/warm desktop client with sidebar navigation, write controls, RGB color+effect pickers, system tray: [`docs/phase6-ui-design.md`](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | non-persistent `SetRgbColor` physically verified 2026-09-06; effect modes via `SetRgbPresetEffect` implemented (desktop test pending); flash-save implemented, physical test pending |
| 8 | scenes | CLI physically validated; UI apply/import/export; starter examples (Quiet / Cool / Battery saver / Gaming lights) |
| 9 | community diagnostics | `msicenter report` + UI copy; client write log on Diagnostics; unmatched-model JSON, no serials: [`docs/phase9-diagnostics.md`](docs/phase9-diagnostics.md) |
| 10 | MUX | research only; see [`docs/deferred-features-research.md`](docs/deferred-features-research.md) |

## Current scope

- DMI device detection and profile matching with provenance validation
- EC semantic state through `msi-ec` (shift/fan modes, temps, fan levels,
  webcam and Fn/Win key positions — read-only)
- real fan RPM through `msi_wmi_platform`/hwmon (channels kept unmapped)
- battery status and charge thresholds through Linux `power_supply`
- runtime capability reporting (model vs backend vs readable)
- fake-sysroot fixture for hardware-free development
- gated, verified writes: `SetBatteryThresholds`, `SetFanMode`,
  `SetCoolerBoost`, `SetSuperBattery` — disabled by default (per-feature
  daemon opt-ins), exact verified firmware + Polkit required
- gated peripheral writes (physical test pending): `SetWebcam`,
  `SetWebcamBlock`, `SetFnKey` through `msi-ec` sysfs
- D-Bus daemon (`org.msilinux.Center`) and Qt/QML desktop client
- all paths redirectable via `MSI_LINUX_CENTER_SYSROOT`

No MUX or fan-curve write exists yet. RGB steady color and effect modes
are writable (non-persistent; flash-save implemented behind a separate
opt-in but not yet physically tested). Performance-mode writes are
deferred (current EC state `0xc0` is not writable by `msi-ec`; see
`MSI-Linux-Center-AGENTS.md` §6.1).

## Install / uninstall

Builds the release daemon, CLI, and Qt UI, then installs systemd, Polkit,
D-Bus policy, desktop file, and (by default) session autostart. Write
opt-ins stay off.

    ./scripts/setup.sh install
    ./scripts/setup.sh install --no-autostart
    ./scripts/setup.sh uninstall

`uninstall` does not delete `~/.config/msi-linux-center`. Prefix defaults
to `/usr` (`PREFIX`, `SYSCONFDIR`).

## Requirements

Rust toolchain for the core/daemon/CLI; Qt 6 (Core, QML, Quick, DBus) +
cmake for the desktop client (`crates/msicenter-ui/`).

## Run against the included fixture first

    ./scripts/run-fixture.sh
    ./scripts/run-fixture.sh --json

## Run read-only on the real laptop

    ./scripts/run-local-readonly.sh
    cargo run -p msicenter-cli -- status [--json]
    cargo run -p msicenter-cli -- capabilities

Do **not** run the CLI with sudo. Privileged writes are performed only by
the daemon after Polkit authorization.

## Write commands (gated)

Each command requires the daemon to run with the matching opt-in
(`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) and completes a Polkit prompt:

    msicenter battery-thresholds START END      # e.g. 80 90 (UI also has 50–60 / 70–80 / 90–100 presets and travel-to-100%)
    msicenter fan-mode auto|silent|advanced
    msicenter cooler-boost on|off
    msicenter super-battery on|off
    msicenter webcam on|off
    msicenter webcam-block on|off
    msicenter fn-key left|right
    msicenter panic-reset                       # Cooler Boost off, Super Battery off, fan auto
    msicenter scene examples                    # add Quiet/Cool/Battery saver/Gaming lights

With the opt-in disabled the daemon refuses with `NotSupported`. The exact
support scope, gates, and physical verification records live in
[`docs/dbus-contract.md`](docs/dbus-contract.md) and the
`docs/phase4-*-validation.md` files.

## Desktop client

    cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
    ./build/msicenter-ui

Pure D-Bus client: never root, no direct `/sys` access; write controls go
through the daemon's Polkit-gated methods. Overview keeps an in-memory sparkline of CPU temperature and fan RPM
(last 15–60 minutes; Copy CSV). The tray tooltip shows CPU temperature, fan RPM, and Cooler Boost.
The tray menu can set a steady
keyboard color or an amber breathing/cycle/wave effect, apply a saved
scene, and (while the app is running) Ctrl+Shift+C / B / L toggles
Cooler Boost, Super Battery, and keyboard RGB off; Ctrl+Shift+P runs
panic reset (Cooler Boost off, Super Battery off, fan auto — not a
shift-mode change). Cooler Boost can
auto-off after 30 s–15 min; Battery has 50–60 / 70–80 / 90–100 presets
and a travel-to-100% that restores the previous pair after 3–30 days
(UI-owned state in `~/.config/msi-linux-center/ui.json`; lasts only
while the app is running, or on the next launch after the date).
An opt-in on the Scenes page can re-apply a scene at app start
(default off — cold boot stays firmware stock), and another can switch
scenes when you plug or unplug (edge-triggered; default off). Battery-level
rules can apply a scene when capacity crosses a low % while discharging
or a high % while charging (once per crossing; default off). A scene
schedule can apply the first matching weekday/time window when that
window starts (overnight ranges allowed; needs the UI running). An
opt-in CPU temperature alert shows an OSD if the CPU stays over a
threshold for several seconds. Compositor-level
bindings can call the same CLI commands (`msicenter cooler-boost on`,
`msicenter rgb-color f 000000`, `msicenter panic-reset`).

## Sysroot override

All Linux paths can be redirected for tests:

    MSI_LINUX_CENTER_SYSROOT=/some/fake/root cargo run -p msicenter-cli -- status

## D-Bus API

Bus `org.msilinux.Center` (system bus), interfaces
`org.msilinux.Center1.Device` and `.Sensors`, plus the gated write
methods (battery thresholds, fan mode, Cooler Boost, Super Battery, RGB
color, RGB effect preset, RGB flash-save). JSON-encoded properties today;
typed records are planned once the UI/SDK needs them. See
[`docs/dbus-contract.md`](docs/dbus-contract.md).
