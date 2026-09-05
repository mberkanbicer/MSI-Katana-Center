# Phase 4 battery-threshold validation

## Support scope

The initial write path is limited to:

- MSI Katana 17 B13VGK
- board `MS-17L5`
- exact EC firmware `17L5EMS1.115`
- Linux `power_supply` start and end threshold files

Unknown devices, missing firmware, firmware-family-only matches, missing threshold files, and disabled runtime opt-in remain read-only.

## Safety behavior

`SetBatteryThresholds(start, end)` accepts percentages from 0 through 100 and requires `start < end`. It selects the laptop battery while excluding `hidpp_*` peripheral batteries.

The daemon reads the current pair before writing. It orders writes to avoid an invalid intermediate pair, reads the driver-applied values back, accepts documented driver rounding only when the resulting pair remains valid, and restores the original pair after a partial write or invalid read-back. A rollback failure is reported separately.

The method accepts no file paths. It requires the Polkit action `org.msilinux.Center.set-battery-thresholds` and the daemon opt-in `MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES=1`.

## Controlled local validation

Do not automate these steps. Record the original thresholds first.

1. Confirm `status --json` reports the exact supported model, board, and EC firmware.
2. Confirm the battery exposes both semantic threshold files.
3. Install the daemon, systemd unit, D-Bus policy, and Polkit action.
4. Set a systemd override containing `Environment=MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES=1`, then restart the daemon.
5. Run `msicenter battery-thresholds START END` as the desktop user and complete the Polkit prompt.
6. Confirm the returned values and `status --json` match the values read back from the driver. The driver may round to supported values.
7. Verify charging starts below the applied start threshold and stops above the applied end threshold.
8. Restore the original pair through the same command if validation fails or the behavior is unexpected.
9. Disable the opt-in after testing.

Only after successful physical verification should the device provenance set `writes_tested` to `true`.
