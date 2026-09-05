# Phase 1 — Read-only Core

> Historical Phase 1 specification. Superseded: the repository now contains the Phase 4 snapshot described in `MSI-Linux-Center-AGENTS.md` §3/§34 (D-Bus daemon, gated battery-threshold write path). This file documents only the Phase 1 scope.

Phase 1 intentionally performs no hardware writes.

## Backends

- DMI: `/sys/class/dmi/id`
- MSI EC semantic state: `/sys/devices/platform/msi-ec`
- Real fan RPM: `msi_wmi_platform` through `/sys/class/hwmon`
- Battery thresholds: `/sys/class/power_supply`

## Explicitly not implemented yet

- D-Bus daemon
- Polkit
- performance/profile writes
- Cooler Boost writes
- fan mode writes
- battery threshold writes
- custom fan curve raw-EC access
- RGB HID writes
- MUX control

## Safety policy

Even though the reference firmware is locally identified as `17L5EMS1.115`, Phase 1 contains no write code. Device database capabilities indicate known hardware support, not permission to write.

The current `msi-ec` shift state `unknown (192)` is preserved verbatim. No forced mapping to Sport or another semantic profile is performed until independently validated.

Fan RPM channels from `msi_wmi_platform` are intentionally exposed as `fan1`, `fan2`, etc. They are not labeled CPU/GPU until a controlled physical mapping test is completed.
