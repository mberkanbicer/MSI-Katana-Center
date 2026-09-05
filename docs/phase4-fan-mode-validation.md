# Phase 4 fan-mode validation

## Support scope

The fan-mode write path is limited to:

- MSI Katana 17 B13VGK
- board `MS-17L5`
- exact EC firmware `17L5EMS1.115`
- the Linux `msi-ec` semantic `fan_mode` attribute

The requested mode must be present in the driver's `available_fan_modes` read at runtime. Observed modes on the reference laptop: `auto`, `silent`, `advanced`.

Unknown devices, missing firmware, firmware-family-only matches, a missing `msi-ec` backend, and a disabled runtime opt-in remain read-only.

## Safety behavior

`SetFanMode(mode)` accepts only driver-declared mode names and rejects anything else as invalid arguments. The daemon reads the previous mode before writing, writes the requested mode, and reads the applied value back. If the driver did not apply the requested mode, the daemon restores the previous mode. A rollback failure is reported separately.

Fan mode is a distinct concept from fan RPM, fan level, custom fan curves, and Cooler Boost (`MSI-Linux-Center-AGENTS.md` §23); this path never touches those. Firmware thermal protection is not modified.

The method accepts no file paths or raw EC addresses. It requires the Polkit action `org.msilinux.Center.set-fan-mode` and the daemon opt-in `MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES=1`.

## Controlled local validation

Do not automate these steps. Record the original fan mode first.

1. Confirm `status --json` reports the exact supported model, board, EC firmware, and the `msi_ec` backend.
2. Record the current fan mode and the `available_fan_modes` list.
3. Install the updated daemon, systemd unit, D-Bus policy, and Polkit action.
4. Set a systemd override containing `Environment=MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES=1`, then restart the daemon.
5. Run `msicenter fan-mode MODE` as the desktop user (prefer `silent`, the least intrusive alternative to `auto`) and complete the Polkit prompt. Run it under low load and listen for the expected fan behavior change.
6. Confirm the returned value, `msicenter status`, and the `fan_mode` sysfs attribute match.
7. Restore the original mode (`auto`) through the same command.
8. Disable the opt-in after testing and confirm `SetFanMode` is rejected while disabled.

Only after successful physical verification should the device provenance set `writes_tested` to `true`.

## Verification record (2026-09-05)

Performed on the reference laptop (Katana 17 B13VGK, MS-17L5, EC `17L5EMS1.115`):

- original fan mode recorded: `auto`; driver modes: `auto`, `silent`, `advanced`
- updated daemon, systemd unit, D-Bus policy, and Polkit action installed; opt-in override `Environment=MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES=1`
- `msicenter fan-mode silent` executed as the desktop user through the Polkit prompt (`auth_admin_keep`)
- returned JSON reported `silent`; daemon `status` and the `fan_mode` sysfs attribute both read back `silent`
- restored with `msicenter fan-mode auto`; sysfs read back `auto`
- opt-in override removed; daemon restarted with `MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES=0`
- negative check: `msicenter fan-mode silent` rejected with `org.freedesktop.DBus.Error.NotSupported` while disabled; the mode stayed `auto`

Outcome: physical fan-mode write verification passed.
