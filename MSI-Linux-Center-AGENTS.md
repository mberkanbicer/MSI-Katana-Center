# AGENTS.md — MSI Linux Center

## 0. Purpose of this file

This file is the primary instruction set for Codex and other coding agents working in this repository.

Read this file before changing code.

The project is hardware-control software. Incorrect writes to an embedded controller (EC), ACPI/WMI method, HID device, battery-control interface, or GPU/MUX interface can cause instability, thermal problems, data loss, or hardware/firmware problems.

Therefore:

**Safety and correctness take precedence over feature velocity.**

Do not infer undocumented hardware behavior and do not add hardware writes merely because a register or protocol appears in an external project.

---

# 1. Project mission

MSI Linux Center is intended to become a Linux-native, open-source hardware management application for MSI laptops.

The long-term goal is not to visually clone MSI Center.

The goal is to provide a safe, verifiable and extensible Linux hardware-management platform for MSI laptops, initially using the MSI Katana 17 B13VGK as the reference device.

Target capabilities include:

- hardware/device detection
- EC firmware detection
- CPU/GPU telemetry
- fan RPM and fan state
- MSI performance scenarios
- Cooler Boost
- fan modes
- battery charging thresholds
- custom fan curves
- 4-zone keyboard RGB
- user profiles/scenes
- D-Bus service
- Polkit privilege separation
- Qt 6 / QML desktop UI
- CLI
- diagnostics
- eventually, verified MUX/graphics switching

The implementation language for the hardware/core/daemon side is Rust.

The desktop UI will use Qt 6 / Qt Quick / QML.

The planned IPC layer is D-Bus.

---

# 2. Primary reference hardware

The current reference system has been locally identified as:

| Property | Verified value |
|---|---|
| Manufacturer | Micro-Star International Co., Ltd. |
| Product | MSI Katana 17 B13VGK |
| Board | MS-17L5 |
| Board revision | REV:1.0 |
| BIOS | E17L5IMS.11C |
| EC firmware | 17L5EMS1.115 |
| CPU | Intel Core i9-13900H |
| iGPU | Intel Iris Xe |
| dGPU | NVIDIA GeForce RTX 4070 Laptop GPU 8 GB |
| RGB controller | MSI MysticLight MS-1565 |
| RGB USB VID:PID | 1462:1601 |
| Linux distribution | EndeavourOS |
| Main kernel family during discovery | Linux LTS |

These values came from the local Phase 0 read-only reconnaissance.

The exact EC firmware `17L5EMS1.115` is especially important.

Do not silently broaden exact verification of `17L5EMS1.115` into write permission for every firmware beginning with `17L5EMS1`.

Firmware-family compatibility may be useful for read-only detection, but write capability must remain separately gated.

---

# 3. Current project phase

The repository has completed the Phase 1 read-only core, the Phase 2 runtime-capability/provenance architecture, and the Phase 3 D-Bus daemon layer. The current snapshot is **Phase 4**: gated, Polkit-protected write paths through Linux interfaces, all physically verified on the reference laptop on 2026-09-05 — battery charge thresholds through `power_supply`, and fan mode, Cooler Boost, and Super Battery through `msi-ec`.

It implements:

- DMI identity reading
- MSI EC semantic-state reading through `msi-ec`
- fan RPM reading through `msi_wmi_platform` / hwmon
- laptop battery charge-threshold reading through Linux `power_supply`
- an external JSON device profile with provenance validation
- human-readable and JSON CLI status
- runtime capability output (model-declared vs backend-detected vs readable)
- a fake sysroot fixture for tests and hardware-free development
- a Rust D-Bus daemon with `Device` and `Sensors` interfaces, systemd unit, D-Bus policy, and Polkit action
- the gated `SetBatteryThresholds` write method through Linux `power_supply`
- the gated `SetFanMode` write method through `msi-ec`
- the gated `SetCoolerBoost` write method through `msi-ec`
- the gated `SetSuperBattery` write method through `msi-ec`

Gated hardware write paths exist, all disabled by default (per-feature `MSI_LINUX_CENTER_ENABLE_*_WRITES=0` opt-ins), restricted to the exact verified firmware, and Polkit-authorized: `SetBatteryThresholds`, `SetFanMode`, `SetCoolerBoost`, and `SetSuperBattery`, all physically verified on 2026-09-05.

Do not add EC, fan, RGB, or MUX writes ahead of the phase sequence in §34; each new write path must satisfy the acceptance criteria in §35 first.

---

# 4. Current repository structure

Expected structure:

- `Cargo.toml`
- `README.md`
- `AGENTS.md`
- `crates/msi-core/`
- `crates/msi-device-db/`
- `crates/msi-hardware/`
- `crates/msi-dbus/`
- `crates/msi-daemon/`
- `crates/msicenter-cli/`
- `data/devices/`
- `data/dbus-1/`
- `data/polkit-1/`
- `data/systemd/`
- `docs/`
- `scripts/`
- `tests/fixtures/`

Current crate responsibilities:

## `msi-core`

Domain types only.

Examples:

- `SupportTier`
- `DeviceIdentity`
- `EcStatus`
- `FanReading`
- `BatteryStatus`
- `CapabilitySet`
- `HardwareProvenance`
- `DeviceProfile`
- `SystemStatus`

Keep this crate independent from Linux filesystem details whenever practical.

## `msi-device-db`

Loads and matches device profiles.

Device profiles must remain data-driven.

Do not scatter model-specific `if Katana ...` logic throughout the codebase.

## `msi-hardware`

Contains Linux hardware-reading backends and filesystem abstraction.

All paths must remain redirectable through the fake sysroot mechanism.

## `msi-dbus`

D-Bus service layer shared by the daemon and the CLI.

Implements status collection, the `org.msilinux.Center1.Device` and `.Sensors` interfaces, JSON-encoded properties, Polkit authorization, and the gated `SetBatteryThresholds` method.

## `msi-daemon`

System-bus daemon binary; installs as `msi-linux-center.service`.

Thin entry point around `msi-dbus::run_system_daemon`.

## `msicenter-cli`

User-facing CLI.

It must consume semantic domain objects rather than directly reading hardware paths. `status`/`capabilities` are read-only; `battery-thresholds` requests the daemon write over D-Bus, where firmware, Polkit, and opt-in gates are enforced.

---

# 5. Mandatory design principles

## 5.1 Kernel interface first

Preferred access order:

1. standard Linux kernel interface
2. MSI-specific Linux kernel/platform interface
3. `msi-ec`
4. vendor sysfs/hwmon interface
5. USB/HID when that is the native hardware transport
6. controlled raw EC only when no safer supported interface exists

Examples:

- battery thresholds: use `power_supply`
- actual fan RPM: use `msi_wmi_platform` hwmon where available
- MSI EC semantic state: use `msi-ec`
- RGB: use the validated HID protocol
- raw EC: last resort only

If a standard or kernel-provided interface already solves the problem, do not bypass it with direct EC access.

## 5.2 Semantic APIs only

Future public APIs must expose semantic operations such as:

- `SetPerformanceProfile`
- `SetCoolerBoost`
- `SetBatteryLimit`
- `SetFanMode`
- `SetFanCurve`
- `SetLightingZone`

Never expose a general API like:

- `WriteEc(address, value)`
- `WritePort(...)`
- arbitrary sysfs write
- arbitrary ACPI method execution

Raw primitives may exist in tightly scoped internal research tooling later, but never as a normal application or D-Bus API.

## 5.3 Raw EC is the last resort

Raw EC write support may only be introduced when all of the following are true:

- no safer kernel/interface implementation exists
- the feature has a documented register/protocol mapping
- the exact firmware or explicitly compatible firmware is validated
- the values have an allowlist
- value bounds are validated
- state is read before write where possible
- read-back verification is possible
- rollback or safe reset is defined where possible
- local physical behavior has been verified
- tests cover the mapping and validation logic

## 5.4 Capability-driven application

The UI and CLI must derive available features from runtime/device capabilities.

Do not assume every MSI laptop has:

- the same EC
- the same fan encoding
- the same RGB controller
- the same number of fan channels
- the same battery interface
- the same MUX method
- the same shift modes

Unsupported capabilities must be hidden, unavailable, or clearly marked experimental.

## 5.5 Firmware-gated writes

Use support tiers:

- `unknown`
- `documented`
- `experimental`
- `verified`

These support tiers describe knowledge/support maturity.

They do **not** automatically grant write permission.

Future write permission should be determined by a separate write-safety policy.

Unknown firmware must default to read-only.

## 5.6 GUI must never require root

Future architecture:

Qt/QML GUI
→ D-Bus
→ Polkit authorization when needed
→ privileged Rust daemon
→ hardware backend

The UI itself must remain unprivileged.

---

# 6. Known local hardware observations

Preserve these facts unless new local evidence replaces them.

## 6.1 MSI EC interface

The reference machine exposes `msi-ec`.

Observed firmware:

`17L5EMS1.115`

Observed available shift modes:

- `eco`
- `comfort`
- `turbo`

Observed current shift state during Phase 0:

`unknown (192)`

Do not map `unknown (192)` to `sport`, `balanced`, or another semantic name unless independently verified.

Represent unknown vendor states explicitly.

A suitable future domain representation is conceptually:

- known semantic mode
- unknown raw/vendor state

Do not lose the raw value when the semantic mapping is unknown.

### Shift-mode write status (2026-09-05)

`unknown (192)` equals `0xc0`. The `msi-ec` 0.13 driver table for this model family (address `0xd2`) maps `eco`/`comfort`/`turbo` to `0xc2`/`0xc1`/`0xc4`, with a source comment that turbo is "sometimes `0xc0`". Because the driver cannot write `0xc0`, reverting to the current register value after any shift-mode write is impossible through `msi-ec`; a failed or unwanted write would be irreversible without an EC reset.

Performance-mode writes are therefore deferred indefinitely: no safe rollback exists. Do not implement `SetShiftMode` until the driver (or an independently verified mapping) can write and restore every mode value this EC actually uses.

Observed fan modes:

- `auto`
- `silent`
- `advanced`

Other observed readable states include:

- Cooler Boost
- Super Battery
- webcam
- Fn/Win key location
- CPU temperature
- GPU temperature
- CPU/GPU fan-level values

The `msi-ec` realtime fan-speed values must not be assumed to be RPM.

Keep them semantically separate from actual RPM.

## 6.2 Fan RPM

The reference machine exposes an hwmon device named:

`msi_wmi_platform`

It provides active `fan*_input` values in RPM.

For now:

- expose the channels as `fan1`, `fan2`, etc.
- do not label them `CPU fan` or `GPU fan`

The physical mapping has not yet been locally validated.

A controlled physical test is required before the device database may claim:

`fan1 = CPU`
or
`fan2 = GPU`

This is a deliberate safety/correctness rule.

## 6.3 Battery

The laptop battery exposes standard Linux charge thresholds through `power_supply`.

Observed paths include semantic equivalents of:

- `charge_control_start_threshold`
- `charge_control_end_threshold`

This is the preferred battery backend.

Do not implement raw EC battery-limit access while the standard Linux interface works.

## 6.4 RGB

The reference device has:

- controller: `MSI MysticLight MS-1565`
- VID: `1462`
- PID: `1601`

The same controller ID is used by the open-source `msi-katana-rgb` work listed below.

This gives high confidence that the existing HID protocol is a useful reference.

However, local controller identity is verified; local write-protocol behavior has not yet been validated in this project.

Do not enable RGB writes merely from the VID/PID match.

## 6.5 GPU and MUX

The system has Intel integrated graphics and an NVIDIA RTX 4070 Laptop GPU.

Keep these concepts separate:

- PRIME/render offload
- dGPU runtime power state
- hardware MUX state

Do not describe PRIME offload as MUX switching.

No production MUX method has been locally verified yet.

---

# 7. Open-source projects are formal engineering references

The following projects are formal technical/comparative/reverse-engineering inputs, not optional examples:

| Project | URL | Primary use |
|---|---|---|
| GhostDeck | https://github.com/wygodad/ghostdeck | MSI model/firmware knowledge, EC/register research, fan curves, verification methodology |
| msi-ec | https://github.com/BeardOverflow/msi-ec | Linux MSI EC/sysfs semantics, modes, Cooler Boost, temperatures, fan levels and supported models |
| MControlCenter | https://github.com/dmitry-s93/MControlCenter | Comparative Linux MSI feature/UX behavior |
| OpenFreezeCenter | https://github.com/YoCodingMonster/OpenFreezeCenter | privilege separation, Polkit concepts, fan control, simulation and recovery |
| msi-katana-rgb | https://github.com/sarpowsky/msi-katana-rgb | Katana Mystic Light USB/HID protocol and 4-zone RGB research |
| Linux kernel | https://github.com/torvalds/linux | highest-priority implementation reference for hwmon, power_supply, WMI, ACPI, HID, DRM and platform drivers |

If a feature is not understood, also inspect relevant kernel patches, GitHub issues/PRs, model-specific repositories, WMI/ACPI research and HID protocol work.

External findings must be cross-checked and locally validated before production writes are enabled.

# 8. Reference and reverse-engineering policy

The standard workflow for every new hardware feature is:

1. check whether Linux already exposes a standard interface
2. inspect MSI-specific kernel/platform support
3. inspect `msi-ec`
4. inspect GhostDeck
5. inspect other relevant open-source projects
6. compare independent findings
7. document provenance
8. validate read-only behavior locally
9. use Windows/MSI Center observation only if needed
10. reverse-engineer only the unknown remainder
11. perform controlled writes only after explicit safety gates
12. physically verify the effect
13. promote the feature's confidence/support status

The guiding rule is:

**Reuse knowledge, not assumptions.**

Another guiding rule is:

**Reference externally, verify locally.**

---

# 9. Evidence hierarchy

Prefer evidence in roughly this order:

1. current Linux kernel implementation/documentation
2. current `msi-ec` implementation
3. multiple independent open-source projects agreeing
4. GhostDeck verified-model information
5. controlled local read-only observation
6. controlled Windows/MSI Center capture
7. controlled local write test
8. physical verification
9. single issue/comment/community report
10. hypothesis

A hypothesis alone is never sufficient for production write support.

---

# 10. Provenance requirements

Hardware facts stored in the device database should carry provenance.

At minimum, important features should record:

- feature name
- model/firmware scope
- source projects/documents
- local verification status
- whether writes were tested
- confidence/support tier
- notes about ambiguity

Do not add a register mapping to production data without recording where it came from.

Avoid comments such as:

`// from internet`

Use a meaningful source/provenance entry instead.

---

# 11. License and code-reuse policy

Preferred approach:

**Study → understand → document → independently implement**

Direct source-code reuse is not the default.

Before copying code from another repository:

1. identify its license
2. determine compatibility with this repository
3. preserve required notices/attribution
4. document the reused component
5. avoid copying more than necessary

Hardware facts and independently derived protocol understanding should be documented separately from copied implementation code.

Do not silently paste GPL/AGPL code into a differently licensed crate.

The current workspace metadata says `MIT OR Apache-2.0`; do not assume that license choice is final if code reuse later creates compatibility constraints.

---

# 12. Toolchain policy

The user's EndeavourOS system already has the distribution Rust package installed.

Do not require `rustup` unless there is a concrete toolchain reason.

Do not instruct the user to remove the system `rust` package simply to install `rustup`.

The workspace currently declares a minimum Rust version in the root `Cargo.toml`.

Keep the minimum version realistic.

Do not increase MSRV without a reason.

---

# 13. No-sudo development rule for read-only phases

Phase 1 and normal Phase 2 tests should not require `sudo`.

Commands such as these are expected to be safe:

`cargo build`
`cargo test`
`cargo run -p msicenter-cli -- status`
`cargo run -p msicenter-cli -- status --json`
`cargo run -p msicenter-cli -- capabilities`
`./scripts/run-fixture.sh`
`./scripts/run-local-readonly.sh`

Do not introduce a sudo requirement into read-only code.

If a future operation truly requires privilege, it belongs behind the privileged daemon and Polkit, not behind `sudo msicenter`.

---

# 14. Fake sysroot is mandatory infrastructure

All filesystem-based hardware readers must support the fake sysroot.

The environment variable is:

`MSI_LINUX_CENTER_SYSROOT`

This allows tests to redirect:

`/sys/...`

to:

`tests/fixtures/...`

Do not bypass this abstraction by opening absolute `/sys` paths from arbitrary modules.

Any new filesystem hardware backend should be testable using a fixture.

This requirement is essential because CI must never require real MSI hardware.

---

# 15. Required first actions for Codex

Before making meaningful changes:

1. read `AGENTS.md`
2. read `README.md`
3. read `docs/phase1.md`
4. inspect root `Cargo.toml`
5. inspect every current crate
6. inspect `data/devices/msi-katana-17-b13vgk.json`
7. inspect fixture contents
8. inspect current `git status` if this is a Git repository
9. run formatting/build/tests before assuming the code works

Do not infer the current state from README alone.

Treat code and tests as the source of truth for what currently builds.

---

# 16. Baseline validation commands

Run the following as the normal baseline where available:

`cargo fmt --all -- --check`

`cargo check --workspace`

`cargo test --workspace`

`./scripts/run-fixture.sh`

`./scripts/run-fixture.sh --json`

If Clippy is installed:

`cargo clippy --workspace --all-targets -- -D warnings`

Do not run the real-hardware script automatically in an environment that is not clearly the user's MSI laptop.

When working on the actual reference laptop, the following is still read-only:

`./scripts/run-local-readonly.sh`

Never run future hardware-write commands automatically.

---

# 17. Phase 1 completion criteria

**Status: complete.** The criteria below were satisfied by the Phase 1 snapshot and remain the regression baseline for the read-only core:

- workspace builds cleanly
- formatting passes
- unit tests pass
- fixture tests pass
- CLI status works on fixture
- JSON output is valid and stable enough for tests
- device matching works for the Katana fixture
- unknown devices remain safe/unmatched
- EC firmware is preserved accurately
- `unknown (192)` is not incorrectly normalized
- fan RPM channels remain physically unmapped until verified
- battery thresholds are read through `power_supply`
- no hardware write code exists

If the current snapshot fails to compile, fix Phase 1 before starting larger architecture work.

Prefer root-cause fixes over compatibility wrappers.

---

# 18. Phase 2 goals

**Status: complete.** Sections 18.1–18.6 were implemented in the Phase 2 snapshot (backend discovery, runtime capability report, tests, provenance/error model, D-Bus contract design) and are kept as the architecture rationale.

The minimum useful Phase 2 contained the following.

## 18.1 Stronger backend discovery

Instead of assuming a feature exists merely because a device profile says it does, distinguish:

- declared capability
- runtime backend available
- runtime feature readable
- support confidence

For example:

A profile may know that the model supports fan RPM, but the current kernel might not expose `msi_wmi_platform`.

The runtime state must represent that difference.

## 18.2 Runtime capability report

Add a semantic runtime capability report.

Conceptually distinguish:

- supported by model
- backend detected
- available now
- experimental
- unavailable

Do not use a single boolean for every future capability if richer state is needed.

## 18.3 Tests

Add tests for at least:

- reference-device match
- wrong product / right board behavior
- right product / wrong firmware behavior
- unknown firmware behavior
- missing `msi-ec`
- missing hwmon
- multiple hwmon devices
- zero-valued fan channels
- laptop battery selection excluding peripheral HID batteries
- missing battery thresholds
- `unknown (192)` preservation
- JSON output basic shape

## 18.4 Provenance validation

Ensure device profile provenance is structured and validated.

Avoid free-form provenance becoming unsearchable technical debt.

## 18.5 Error model

Replace ad-hoc error strings with a small, useful error model where justified.

Do not create a huge error framework.

Differentiate at least:

- unavailable interface
- parse error
- I/O error
- invalid profile/database entry

Read-only missing interfaces often represent "feature unavailable", not fatal application errors.

## 18.6 D-Bus contract design only

Phase 2 may define the future D-Bus interface and document it.

Do not yet add privileged hardware writes.

A later phase can add the daemon implementation.

---

# 19. Target architecture after Phase 2

Long-term structure should move toward:

- `msi-core`
- `msi-device-db`
- `msi-hardware`
- `msi-dbus`
- `msi-daemon`
- `msicenter-cli`
- Qt/QML UI

Potential future backend submodules:

- DMI
- hwmon
- msi-ec
- power_supply
- HID/RGB
- graphics
- controlled EC fallback

Keep dependencies directional.

A desirable direction is:

UI/CLI
→ D-Bus/domain API
→ daemon/service
→ hardware abstraction
→ kernel/hardware

Avoid circular dependencies.

---

# 20. Future D-Bus rules

Planned service identity may use a name such as:

`org.msilinux.Center`

Do not freeze a public D-Bus API casually.

Before implementation, document:

- object paths
- interfaces
- methods
- properties
- signals
- authorization requirements
- error semantics
- versioning policy

Never expose raw EC primitives over D-Bus.

Potential semantic interfaces:

- Device
- Sensors
- Performance
- Fan
- Battery
- Lighting
- Graphics
- Profiles
- Diagnostics

---

# 21. Future privileged daemon rules

When writes are eventually introduced:

- daemon is Rust
- daemon runs with only required privileges
- GUI remains unprivileged
- CLI talks to the daemon rather than directly writing hardware
- Polkit controls sensitive methods
- every write is semantically validated
- firmware/write gate is enforced in daemon, not only UI
- daemon does not execute arbitrary shell commands
- daemon does not accept arbitrary file paths from clients
- daemon does not expose arbitrary register writes

Security checks must live at the trust boundary.

Never rely on the GUI to prevent unsafe requests.

---

# 22. Future performance-profile model

Keep MSI EC hardware scenarios separate from Linux CPU power policy.

These are different domains.

Examples of MSI EC state:

- eco
- comfort
- turbo
- unknown vendor state

Examples of Linux power policy:

- power-saver
- balanced
- performance

A future "Scene" may coordinate both, but do not merge them into one low-level enum.

---

# 23. Future fan-control rules

Fan concepts must remain separate:

- fan RPM
- EC fan level/duty-like value
- fan mode
- custom fan curve
- Cooler Boost

Do not conflate them.

Before enabling custom fan curve writes:

1. inspect GhostDeck mapping
2. inspect any relevant `msi-ec` code/issues
3. read factory/current curve if possible
4. save a recoverable baseline
5. validate point count
6. validate temperature ordering
7. validate speed bounds
8. enforce safe high-temperature behavior
9. write minimally
10. read back
11. physically validate fan response
12. implement reset/restore

Do not implement continuous userspace PWM control if firmware curve programming can safely provide the intended behavior.

Firmware thermal protection must never be disabled.

---

# 24. Future RGB rules

RGB must be a separate backend from EC.

Initial transport is expected to be USB HID for the identified MysticLight controller.

Before enabling local writes:

1. inspect `msi-katana-rgb`
2. document packet format
3. confirm report/interface identity
4. test non-persistent state first if the protocol supports it
5. avoid flash/persistent writes until temporary writes are validated
6. test one zone/color at a time
7. add bounds validation
8. add fixture/protocol unit tests

Persistent/flash-save commands are higher risk than temporary lighting changes.

Treat them separately.

---

# 25. Future MUX rules

MUX is intentionally late-stage.

Do not implement it from guesses.

Research order:

1. existing Linux kernel/vendor interface
2. MSI WMI/platform methods
3. ACPI DSDT/SSDT
4. relevant open-source MSI research
5. controlled Windows/MSI Center observation
6. local read-only identification
7. explicit write/reboot testing only after evidence is strong

Differentiate:

- render offload
- GPU power management
- display routing
- true hardware MUX state

A reboot-requiring firmware selection must be modeled explicitly as such.

---

# 26. Reverse-engineering methodology

When a feature is missing, use controlled differential experiments.

For EC research:

- capture state A
- make exactly one MSI Center change
- capture state B
- diff
- repeat
- change only one variable at a time
- cross-check external projects
- identify candidate fields
- confirm correlation
- only then consider write tests

For USB/HID:

- capture reports
- alter one zone/color/effect parameter
- compare packets
- identify fields
- verify checksum/report structure if present
- test temporary commands before persistent commands

For ACPI/WMI:

- inspect tables/interfaces first
- document GUIDs/methods
- avoid executing unknown methods
- compare with kernel/vendor implementations
- distinguish getter from setter behavior

Store research notes under `docs/` or a future `reverse-engineering/` tree.

---

# 27. Coding style

General Rust rules:

- prefer simple, explicit code
- avoid unsafe Rust unless absolutely necessary
- if `unsafe` is introduced later, document invariants next to it
- use descriptive domain names
- avoid abbreviations unless standard in the hardware domain
- keep hardware parsing separate from presentation
- avoid panics for ordinary missing sysfs files
- treat missing optional hardware interfaces as availability state
- use `Result` for actual failures
- preserve unknown raw values instead of silently normalizing them
- avoid premature generic frameworks

Formatting:

`cargo fmt`

Linting:

prefer clean Clippy where practical.

Do not add a dependency for something that can be implemented clearly with the standard library unless the dependency provides meaningful value.

---

# 28. Testing philosophy

Tests are required for behavior that protects hardware correctness.

High-value tests include:

- firmware matching
- bounds validation
- device matching
- register/protocol encoding
- fan curve validation
- parsing
- runtime capability detection
- safety gates

Avoid low-value tests that merely duplicate trivial getters.

Any future write-capable feature should have more validation tests than ordinary display code.

CI must never require real MSI hardware.

Use fixtures and replay data.

---

# 29. Device database rules

Device profiles should remain external data where practical.

Do not put marketing names, firmware prefixes, USB IDs and feature mappings into many unrelated Rust source files.

The database should eventually be able to express:

- model identity
- board identity
- firmware family
- exact verified firmware
- support tier
- runtime-capability hints
- HID identity
- fan-channel mapping after validation
- feature-specific backend preference
- provenance
- write-verification status

Be cautious with booleans such as `rgb: true`.

Over time, richer capability metadata may be necessary.

Migrate deliberately rather than creating parallel incompatible schemas.

---

# 30. Diagnostics requirements

Diagnostics should eventually report:

- DMI model
- board
- BIOS
- EC firmware
- kernel
- relevant driver/backend availability
- hwmon names/channels
- battery-interface availability
- HID MSI controller identity
- GPU runtime state
- capabilities
- support tier
- provenance/database revision

Diagnostics intended for sharing must exclude by default:

- hostname
- user name
- system serial number
- UUID
- MAC addresses
- IP addresses
- Wi-Fi SSIDs
- personal file paths
- unrelated Bluetooth device names
- kernel journal unless explicitly sanitized

Do not reintroduce raw `journalctl` output into a shareable diagnostics report.

---

# 31. Privacy rule learned from Phase 0

An earlier reconnaissance script claimed to omit personal network information but included kernel journal output that could contain:

- hostname
- MAC addresses
- access-point addresses
- personal Bluetooth-device labels

This was corrected conceptually by removing kernel journal output from the shareable report.

Do not repeat this mistake.

Privacy claims must match the actual data collected.

---

# 32. Git behavior

If this is already a Git repository, inspect `git status`, preserve user changes, keep patches scoped, do not rewrite history, and run tests after modifications. If it is not a Git repository, do not initialize one unless asked.

# 33. Do not overengineer

For each task:

1. understand the requirement
2. identify the smallest root-cause change
3. implement only what is necessary
4. test it
5. stop

Do not introduce:

- plugin frameworks without a current need
- async runtimes before a service actually needs async behavior
- complex dependency injection for simple filesystem readers
- speculative cross-platform support
- multiple parallel hardware abstractions solving the same problem
- compatibility layers for hypothetical future APIs

Planning may be thorough.

Execution should remain minimal.

---

# 34. Phase sequence

Follow this sequence unless the user explicitly changes priorities.

## Phase 0 — complete

Read-only hardware reconnaissance.

## Phase 1 — complete

Read-only Rust core + device database + hardware readers + CLI + fixture.

## Phase 2 — complete

- compile/test stabilization
- stronger runtime capabilities
- better test coverage
- provenance/schema improvement
- backend discovery
- D-Bus API design documentation

Still read-only.

## Phase 3 — complete

- Rust daemon skeleton
- D-Bus implementation
- systemd service
- no hardware writes initially

## Phase 4 — current

First safe semantic writes, preferably through existing Linux interfaces.

Status:

- battery threshold — implemented and physically verified (2026-09-05; gated through `power_supply`)
- cooler_boost — implemented and physically verified (2026-09-05; gated through `msi-ec`)
- performance mode — deferred (see §6.1: current state `0xc0` is not writable by `msi-ec`, so no safe rollback exists)
- fan mode — implemented and physically verified (2026-09-05; gated through `msi-ec`)
- Super Battery — implemented and physically verified (2026-09-05; gated through `msi-ec`)

Each feature must be introduced separately and locally validated.

## Phase 5 — next

Custom fan curves with explicit EC safety controls.

Design study (no code): `docs/phase5-fan-curve-design.md`.

## Phase 6

Qt 6 / QML UI.

Architecture plan (no code): `docs/phase6-ui-design.md`.

Milestone 1 (read-only dashboard skeleton) implemented in
`crates/msicenter-ui/` (C++17 + QtDBus client, QML views); runs against the
live daemon, verified on 2026-09-05. Milestone 2 adds write controls for the
four verified features (fan mode, Cooler Boost, Super Battery, battery
thresholds); all calls go through the daemon's Polkit-gated methods and the
UI reports daemon replies/refusals verbatim. Write controls were verified
via CLI; UI-side interaction needs a desktop visual test.

## Phase 7

RGB HID control.

Design study: `docs/phase7-rgb-design.md` — transport decision 2026-09-06:
hidapi with libusb backend from the root daemon (no hidraw on this kernel;
system libusb/hidapi present; same path OpenRGB uses). Protocol notes:
`docs/phase7-rgb-protocol.md`. Packet builder implemented and unit-tested
(no device writes): `msi-hardware::rgb` (zone-select + set-effect packets,
validation, keyframe cap 10). Daemon usbfs probe verified on hardware
2026-09-06 (serial 4062C8A28000). Gated non-persistent `SetRgbColor` write
path implemented and physically verified 2026-09-06
(`docs/phase7-rgb-validation.md`). Non-persistent `SetRgbEffect` (modes)
and the separate, higher-risk flash-save `SaveRgbState` are implemented;
flash-save physical verification pending.

## Phase 8

Scenes/profiles.

Design study: `docs/phase8-scenes-design.md` — user-owned scene file,
sequential per-setting gated writes, no new daemon surface. CLI
`scene list`/`scene apply` implemented 2026-09-06; UI scene section
pending.

## Phase 9

Community diagnostics and unsupported-model workflow.

## Phase 10

MUX research and, only if verified, controlled support.

---

# 35. Required acceptance criteria before a hardware write

**Status:** satisfied and physically verified for the battery-threshold write path (2026-09-05). The gates below remain mandatory for every future hardware write.

Do not add a new production hardware write until:

- Phase 1 tests are stable
- Phase 2 runtime capability model is stable enough
- device matching is reliable
- exact firmware identity is available
- unknown firmware behavior is tested
- daemon trust boundary is defined
- semantic write API is defined
- Polkit approach is planned
- feature-specific rollback/read-back plan exists
- source provenance is documented
- local user explicitly intends to test the write

The first write should be a low-risk, semantically bounded feature already exposed through a Linux interface or `msi-ec`, not raw EC fan programming.

---

# 36. Definition of done for an individual feature

Read-only features require the correct backend, graceful missing-backend handling, parsing tests, fixture coverage and provenance. Write features additionally require exact support scope, safety validation, authorization, read-back/rollback where applicable, local physical verification and safe unknown-firmware behavior.

# 37. Recommended initial Codex task

> Historical guidance for the Phase 1 starting point. The repository has since completed Phases 1–3 and reached the Phase 4 snapshot described in §34; follow the §34 phase sequence instead of starting over.

If starting from the current Phase 1 snapshot, the recommended first Codex task is:

**Stabilize and finish Phase 1 before adding Phase 2 architecture.**

Specifically:

1. run `cargo fmt --all -- --check`
2. run `cargo check --workspace`
3. run `cargo test --workspace`
4. run `./scripts/run-fixture.sh`
5. inspect any failures
6. make the minimum fixes required
7. add missing high-value Phase 1 tests
8. verify `status --json`
9. verify unknown-device safety
10. update README/docs only if behavior changed

Do not add write features during this task.

After Phase 1 passes cleanly, proceed to a separate Phase 2 task.

---

# 38. Suggested Phase 2 task prompt

After Phase 1 is clean, implement Phase 2 runtime capability discovery while remaining strictly read-only. Distinguish model-declared support from runtime backend availability, add fake-sysroot tests, preserve unknown EC states, keep fan channels unmapped, and document rather than implement the future D-Bus contract.

# 39. Final safety reminder

This project controls laptop hardware.

Never trade safety for convenience.

When uncertain:

- read instead of write
- preserve raw/unknown state
- document the uncertainty
- compare external sources
- test with fixtures
- ask for or perform local validation before enabling write support

The desired engineering style is:

**safe, evidence-based, minimal, testable, Linux-native, and extensible.**
