# Project Instructions

Hardware-control software. Safety and correctness beat feature velocity.
Read `MSI-Linux-Center-AGENTS.md` before changing hardware, D-Bus, Polkit, or write paths.

## Tech Stack

Rust 2021 workspace (MSRV 1.75): `msi-core`, `msi-device-db`, `msi-hardware`, `msi-dbus`, `msi-daemon`, `msicenter-cli`.
Qt 6 / QML desktop client in `crates/msicenter-ui` (CMake, not a Cargo member).
IPC: D-Bus `org.msilinux.Center`. Privileged writes live only in the daemon.

## Hardware writes

- Do not run CLI/UI write commands, enable `MSI_LINUX_CENTER_ENABLE_*_WRITES`, or write sysfs/EC/HID from this agent.
- Do not add a write path until `MSI-Linux-Center-AGENTS.md` §35 is satisfied on firmware `17L5EMS1.115`.
- UI and CLI stay unprivileged. Gates (opt-in, exact firmware, Polkit, read-back, rollback) stay in the daemon.
- Phase 5 fan-curve **code is forbidden** until the consent-gated EC table rollback experiment is recorded. Design only: `docs/phase5-fan-curve-design.md`.

## Build & Run

- Rust: `cargo build --release`
- Tests: `cargo test --workspace`
- Clippy: `cargo clippy --workspace --all-targets -- -D warnings`
- Fixture (no hardware): `./scripts/run-fixture.sh`
- Live read-only: `./scripts/run-local-readonly.sh`
- Qt UI: `cmake -S crates/msicenter-ui -B crates/msicenter-ui/build && cmake --build crates/msicenter-ui/build -j`
- Install: `./scripts/setup.sh install` (opt-ins stay off)
- CI: `.github/workflows/ci.yml` (`cargo test` + clippy)
- Index: `codegraph init -y` (local `.codegraph/`, gitignored)

Do not run the CLI with sudo.

## Project Structure

- `crates/msi-core` — domain types
- `crates/msi-device-db` — JSON profiles (`data/devices/`)
- `crates/msi-hardware` — sysfs/HID, `MSI_LINUX_CENTER_SYSROOT`
- `crates/msi-dbus` — D-Bus + Polkit + opt-ins
- `crates/msi-daemon` — systemd binary
- `crates/msicenter-cli` — user CLI
- `crates/msicenter-ui` — Qt/QML client
- `docs/` — phase design and physical validation

## Conventions

- Crate-local `#[cfg(test)]`. No Qt unit tests yet.
- Scene files are user-owned (`~/.config/msi-linux-center`); the daemon never reads them.
- Commits: `feat:`, `fix:`, `docs:`, `ui:`, `rgb:`, `scripts:`, `packaging:`.
