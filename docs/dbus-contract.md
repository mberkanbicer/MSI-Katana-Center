# Future D-Bus contract

Phase 4 added the gated semantic writes for local validation — battery charge
thresholds through Linux `power_supply`, and fan mode, Cooler Boost, and
Super Battery through `msi-ec` (all physically verified on 2026-09-05).
All other interfaces remain read-only.

## Identity and versioning

- Bus name: `org.msilinux.Center`
- Root object: `/org/msilinux/Center`
- Interface prefix: `org.msilinux.Center1`
- Breaking changes require a new numbered interface; compatible properties and methods may be added to `Center1`.

## Read-only interfaces

`org.msilinux.Center1.Device` exposes read-only properties:

- `Identity`: JSON-encoded DMI identity without serial numbers or UUIDs
- `MatchedProfile`: profile ID or an empty string
- `SupportTier`: `unknown`, `documented`, `experimental`, or `verified`
- `RuntimeCapabilities`: JSON-encoded model declaration, backend detection, readability, and support tier per semantic feature

`org.msilinux.Center1.Sensors` exposes read-only properties:

- `EcState`: JSON-encoded semantic `msi-ec` values, preserving unknown vendor values verbatim
- `FanRpm`: JSON-encoded, physically unmapped hwmon channel names and RPM values
- `Battery`: JSON-encoded status, capacity, and available charge thresholds

Methods:

- `Refresh()` refreshes read-only state.
- `SetBatteryThresholds(start, end)` validates percentages, requires exact verified firmware and the `power_supply` backend, obtains Polkit authorization, writes in constraint-safe order, reads back the driver-applied values, and rolls back invalid or partial results.
- `SetFanMode(mode)` requires exact verified firmware and the `msi-ec` backend, restricts `mode` to the driver's `available_fan_modes`, obtains Polkit authorization, writes, reads back the applied value, and restores the previous mode on write or verification failure.
- `SetCoolerBoost(enabled)` requires exact verified firmware and the `msi-ec` backend, obtains Polkit authorization, writes `on`/`off`, reads back the applied value, and restores the previous state on write or verification failure.
- `SetSuperBattery(enabled)` requires exact verified firmware and the `msi-ec` backend, obtains Polkit authorization, writes `on`/`off`, reads back the applied value, and restores the previous state on write or verification failure.
- `SetRgbColor(zones, r, g, b)` requires a profile with a declared RGB controller and the detected USB backend, obtains Polkit authorization, and sends a **non-persistent** steady color (zone select + effect feature reports). No flash-save is ever sent; there is no read-back on this device, so verification is visual.
- `SetRgbEffect(zones, mode, speed_cs, wave_direction, colors)` — non-persistent effect (off/steady/breathing/color-cycle/wave); colors are distributed as evenly spaced keyframes (max 10). Same gates and action as `SetRgbColor`.
- `SaveRgbState()` — **persistent**: saves the last sent state to flash. Requires its own opt-in `MSI_LINUX_CENTER_ENABLE_RGB_FLASH_WRITES=1` and Polkit action `org.msilinux.Center.set-rgb-save` (AGENTS §24 keeps flash writes separate and higher-risk).

Signals:

- `StateChanged()` announces refreshed property data.

Missing kernel interfaces are represented as unavailable capabilities, not service failure. Parse, I/O, and invalid-profile failures use distinct D-Bus errors under `org.msilinux.Center1.Error`.

## Privileged interfaces

Future write methods must be semantic and feature-specific. Raw EC addresses, arbitrary sysfs paths, arbitrary ACPI/WMI methods, and arbitrary HID reports must never be exposed.

Write methods require Polkit authorization in the daemon. The GUI and CLI remain unprivileged. Firmware gates, bounds validation, read-back, and rollback checks live in the daemon trust boundary rather than the UI.

Battery writes are disabled unless the daemon starts with `MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES=1`. This opt-in is for controlled local validation; provenance records `writes_tested: true` since the physical test on 2026-09-05. Authorization uses the Polkit action `org.msilinux.Center.set-battery-thresholds`.

Fan-mode writes follow the same pattern with `MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES=1` and the Polkit action `org.msilinux.Center.set-fan-mode`. The requested mode must be one of the driver's `available_fan_modes`; the daemon restores the previous mode on write or verification failure. Physically verified on 2026-09-05.

Cooler Boost follows the same pattern with `MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES=1` and the Polkit action `org.msilinux.Center.set-cooler-boost`. The daemon restores the previous state on write or verification failure. Physically verified on 2026-09-05.

Super Battery follows the same pattern with `MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES=1` and the Polkit action `org.msilinux.Center.set-super-battery`. The daemon restores the previous state on write or verification failure. Physically verified on 2026-09-05.

RGB color follows the Phase 7 pattern with `MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1`
and the Polkit action `org.msilinux.Center.set-rgb-color`. It sends a
non-persistent steady color or effect to the declared MysticLight
controller over usbfs; flash-save is never part of these calls. Physically
verified on 2026-09-06.

Persistent RGB writes are separate and higher-risk (AGENTS §24):
`SaveRgbState()` needs `MSI_LINUX_CENTER_ENABLE_RGB_FLASH_WRITES=1` and the
Polkit action `org.msilinux.Center.set-rgb-save`. Physical verification
pending.

No other write interface becomes part of `Center1` until its hardware-specific acceptance criteria are met and locally verified.

## Deployment

The daemon runs as root because the kernel threshold files are root-owned, but its systemd unit drops all Linux capabilities. The implementation exposes only the selected laptop battery's semantic threshold files; it accepts no paths or raw write primitives. The D-Bus policy grants only root ownership of `org.msilinux.Center`; unprivileged clients may call it, while Polkit protects the write method.
