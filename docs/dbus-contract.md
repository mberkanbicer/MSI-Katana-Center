# Future D-Bus contract

Phase 4 adds one gated semantic write for local validation: battery charge thresholds through Linux `power_supply`. All other interfaces remain read-only.

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

Signals:

- `StateChanged()` announces refreshed property data.

Missing kernel interfaces are represented as unavailable capabilities, not service failure. Parse, I/O, and invalid-profile failures use distinct D-Bus errors under `org.msilinux.Center1.Error`.

## Privileged interfaces

Future write methods must be semantic and feature-specific. Raw EC addresses, arbitrary sysfs paths, arbitrary ACPI/WMI methods, and arbitrary HID reports must never be exposed.

Write methods require Polkit authorization in the daemon. The GUI and CLI remain unprivileged. Firmware gates, bounds validation, read-back, and rollback checks live in the daemon trust boundary rather than the UI.

Battery writes are disabled unless the daemon starts with `MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES=1`. This opt-in is for controlled local validation; provenance remains `writes_tested: false` until a physical test succeeds. Authorization uses the Polkit action `org.msilinux.Center.set-battery-thresholds`.

No other write interface becomes part of `Center1` until its hardware-specific acceptance criteria are met and locally verified.

## Deployment

The daemon runs as root because the kernel threshold files are root-owned, but its systemd unit drops all Linux capabilities. The implementation exposes only the selected laptop battery's semantic threshold files; it accepts no paths or raw write primitives. The D-Bus policy grants only root ownership of `org.msilinux.Center`; unprivileged clients may call it, while Polkit protects the write method.
