# Phase 4 Cooler Boost validation

## Support scope

The Cooler Boost write path is limited to:

- MSI Katana 17 B13VGK
- board `MS-17L5`
- exact EC firmware `17L5EMS1.115`
- the Linux `msi-ec` semantic `cooler_boost` attribute (`on`/`off`)

Unknown devices, missing firmware, firmware-family-only matches, a missing `msi-ec` backend, and a disabled runtime opt-in remain read-only.

## Safety behavior

`SetCoolerBoost(enabled)` accepts a boolean and writes `on`/`off` to the `msi-ec` attribute. The daemon reads the previous state before writing, writes, and reads the applied value back. If the driver did not apply the requested state, the daemon restores the previous state. A rollback failure is reported separately.

Cooler Boost runs the fans at maximum speed; it is thermally safe (more cooling, never less) but loud, and should be toggled back off after verification. Firmware thermal protection is not modified.

The method accepts no file paths or raw EC addresses. It requires the Polkit action `org.msilinux.Center.set-cooler-boost` and the daemon opt-in `MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES=1`.

## Controlled local validation

Do not automate these steps. Record the original state first.

1. Confirm `status --json` reports the exact supported model, board, EC firmware, and the `msi_ec` backend.
2. Record the current `cooler_boost` state (expected `off`).
3. Install the updated daemon, systemd unit, D-Bus policy, and Polkit action.
4. Set a systemd override containing `Environment=MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES=1`, then restart the daemon.
5. Run `msicenter cooler-boost on` as the desktop user and complete the Polkit prompt. Confirm the fans ramp to maximum (audible) within a few seconds.
6. Confirm the returned value, `msicenter status`, and the `cooler_boost` sysfs attribute match (`on`).
7. Restore with `msicenter cooler-boost off`; confirm the fans return to their previous behavior.
8. Disable the opt-in after testing and confirm `SetCoolerBoost` is rejected while disabled.

Only after successful physical verification should the device provenance set `writes_tested` to `true`.

## Verification record (2026-09-05)

Performed on the reference laptop (Katana 17 B13VGK, MS-17L5, EC `17L5EMS1.115`):

- original Cooler Boost state recorded: `off`
- updated daemon, systemd unit, D-Bus policy, and Polkit action installed; opt-in override `Environment=MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES=1`
- `msicenter cooler-boost on` executed as the desktop user through the Polkit prompt (`auth_admin_keep`); the fans ramped to maximum as expected
- returned JSON reported `true`; daemon `status` and the `cooler_boost` sysfs attribute both read back `on`
- restored with `msicenter cooler-boost off`; sysfs read back `off` and the fans returned to normal behavior
- opt-in override removed; daemon restarted with `MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES=0`
- negative check: `msicenter cooler-boost on` rejected with `org.freedesktop.DBus.Error.NotSupported` while disabled

Outcome: physical Cooler Boost write verification passed.
