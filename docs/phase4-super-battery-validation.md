# Phase 4 Super Battery validation

## Support scope

The Super Battery write path is limited to:

- MSI Katana 17 B13VGK
- board `MS-17L5`
- exact EC firmware `17L5EMS1.115`
- the Linux `msi-ec` semantic `super_battery` attribute (`on`/`off`)

Unknown devices, missing firmware, firmware-family-only matches, a missing `msi-ec` backend, and a disabled runtime opt-in remain read-only.

## Safety behavior

`SetSuperBattery(enabled)` accepts a boolean and writes `on`/`off` to the `msi-ec` attribute. The daemon reads the previous state before writing, writes, and reads the applied value back. If the driver did not apply the requested state, the daemon restores the previous state. A rollback failure is reported separately.

Super Battery is an MSI battery-preservation mode that changes charging behavior. Toggle it back off after verification; perform the test while the battery is not critically low. Firmware thermal protection is not modified.

The method accepts no file paths or raw EC addresses. It requires the Polkit action `org.msilinux.Center.set-super-battery` and the daemon opt-in `MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES=1`.

## Controlled local validation

Do not automate these steps. Record the original state first.

1. Confirm `status --json` reports the exact supported model, board, EC firmware, and the `msi_ec` backend.
2. Record the current `super_battery` state (expected `off`).
3. Install the updated daemon, systemd unit, D-Bus policy, and Polkit action.
4. Set a systemd override containing `Environment=MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES=1`, then restart the daemon.
5. Run `msicenter super-battery on` as the desktop user and complete the Polkit prompt.
6. Confirm the returned value, `msicenter status`, and the `super_battery` sysfs attribute match (`on`).
7. Restore with `msicenter super-battery off`; confirm the sysfs attribute reads `off`.
8. Disable the opt-in after testing and confirm `SetSuperBattery` is rejected while disabled.

Only after successful physical verification should the device provenance set `writes_tested` to `true`.

## Verification record (2026-09-05)

Performed on the reference laptop (Katana 17 B13VGK, MS-17L5, EC `17L5EMS1.115`):

- original Super Battery state recorded: `off`
- updated daemon, systemd unit, D-Bus policy, and Polkit action installed; opt-in override `Environment=MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES=1`
- `msicenter super-battery on` executed as the desktop user through the Polkit prompt (`auth_admin_keep`)
- returned JSON reported `true`; daemon `status` and the `super_battery` sysfs attribute both read back `on`
- restored with `msicenter super-battery off`; the sysfs attribute read back `off`
- opt-in override removed; daemon restarted with `MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES=0`
- negative check: `msicenter super-battery on` rejected with `org.freedesktop.DBus.Error.NotSupported` while disabled

Outcome: physical Super Battery write verification passed.
