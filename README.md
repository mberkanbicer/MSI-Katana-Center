# MSI Linux Center — Phase 4 (battery thresholds verified)

Linux-native MSI laptop hardware management project. This snapshot implements the read-only core, runtime capability discovery, the D-Bus service, and the gated, physically verified semantic battery-threshold write path for the MSI Katana 17 B13VGK reference device.

## Current scope

- DMI device detection
- EC firmware/state reading through `msi-ec`
- real fan RPM reading through `msi_wmi_platform`/hwmon
- battery charge-threshold reading through Linux `power_supply`
- external JSON device profile database
- human-readable and JSON CLI output
- fake sysroot fixture for hardware-free development
- model-declared versus runtime-available capability reporting
- structured, validated hardware provenance
- documented future D-Bus contract
- Rust D-Bus daemon with `Device` and `Sensors` interfaces
- hardened systemd service and system-bus policy
- Polkit-protected battery threshold writes with validation, read-back, and rollback
- gated `msi-ec` fan-mode write with validation, read-back, and rollback
- gated `msi-ec` Cooler Boost write with validation, read-back, and rollback
- gated `msi-ec` Super Battery write with validation, read-back, and rollback (pending physical verification)

Battery-threshold, fan-mode, Cooler Boost, and Super Battery writes are disabled by default and require explicit per-feature daemon opt-ins. No RGB, MUX, or fan-curve write exists.

## Reference device

- MSI Katana 17 B13VGK
- board: MS-17L5 REV:1.0
- observed BIOS: E17L5IMS.11C
- observed EC: 17L5EMS1.115
- RGB controller identified separately: MSI MysticLight MS-1565, 1462:1601

The GitHub projects GhostDeck, `msi-ec`, MControlCenter, OpenFreezeCenter and `msi-katana-rgb` are treated as formal technical/reverse-engineering references. External findings are cross-checked and locally validated before production write support is enabled.

## Requirements

Install Rust with `rustup` or your distribution package. On Arch/EndeavourOS, the standard `rustup` package is recommended for development.

## Run against the included fixture first

    ./scripts/run-fixture.sh

JSON output:

    ./scripts/run-fixture.sh --json

## Run read-only on the real laptop

    ./scripts/run-local-readonly.sh

or:

    cargo run -p msicenter-cli -- status

JSON:

    cargo run -p msicenter-cli -- status --json

Capabilities:

    cargo run -p msicenter-cli -- capabilities

Do **not** run the CLI with sudo. Privileged writes are performed only by the daemon after Polkit authorization.

## Sysroot override

All Linux paths can be redirected for tests:

    MSI_LINUX_CENTER_SYSROOT=/some/fake/root cargo run -p msicenter-cli -- status

## D-Bus API

Phase 4 implements the gated battery method in [`docs/dbus-contract.md`](docs/dbus-contract.md). The write path was physically verified on the reference laptop on 2026-09-05 (`SetBatteryThresholds(80, 90)` applied, read back from the driver, and restored to `90/100`; see [`docs/phase4-battery-validation.md`](docs/phase4-battery-validation.md)). The supplied service still keeps `MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES=0`; writes require an explicit daemon opt-in.

Other write operations remain deferred until the safety, firmware, authorization, rollback, and local-verification gates in `MSI-Linux-Center-AGENTS.md` are satisfied.
