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
| 5 | custom fan curves | design study: [`docs/phase5-fan-curve-design.md`](docs/phase5-fan-curve-design.md) |
| 6 | Qt/QML desktop UI | milestone 2 in `crates/msicenter-ui/`; plan: [`docs/phase6-ui-design.md`](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | protocol documented + packet builder tested; design: [`docs/phase7-rgb-design.md`](docs/phase7-rgb-design.md), protocol: [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) |

## Current scope

- DMI device detection and profile matching with provenance validation
- EC semantic state through `msi-ec` (shift/fan modes, temps, fan levels)
- real fan RPM through `msi_wmi_platform`/hwmon (channels kept unmapped)
- battery status and charge thresholds through Linux `power_supply`
- runtime capability reporting (model vs backend vs readable)
- fake-sysroot fixture for hardware-free development
- gated, verified writes: `SetBatteryThresholds`, `SetFanMode`,
  `SetCoolerBoost`, `SetSuperBattery` — disabled by default (per-feature
  daemon opt-ins), exact verified firmware + Polkit required
- D-Bus daemon (`org.msilinux.Center`) and Qt/QML desktop client
- all paths redirectable via `MSI_LINUX_CENTER_SYSROOT`

No RGB, MUX, or fan-curve write exists yet. Performance-mode writes are
deferred (current EC state `0xc0` is not writable by `msi-ec`; see
`MSI-Linux-Center-AGENTS.md` §6.1).

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

    msicenter battery-thresholds START END      # e.g. 80 90
    msicenter fan-mode auto|silent|advanced
    msicenter cooler-boost on|off
    msicenter super-battery on|off

With the opt-in disabled the daemon refuses with `NotSupported`. The exact
support scope, gates, and physical verification records live in
[`docs/dbus-contract.md`](docs/dbus-contract.md) and the
`docs/phase4-*-validation.md` files.

## Desktop client

    cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
    ./build/msicenter-ui

Pure D-Bus client: never root, no direct `/sys` access; write controls go
through the daemon's Polkit-gated methods.

## Sysroot override

All Linux paths can be redirected for tests:

    MSI_LINUX_CENTER_SYSROOT=/some/fake/root cargo run -p msicenter-cli -- status

## D-Bus API

Bus `org.msilinux.Center` (system bus), interfaces
`org.msilinux.Center1.Device` and `.Sensors`, plus the four gated write
methods. JSON-encoded properties today; typed records are planned once the
UI/SDK needs them. See [`docs/dbus-contract.md`](docs/dbus-contract.md).
