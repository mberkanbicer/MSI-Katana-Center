# Phase 7 — RGB non-persistent color validation

## Support scope

The first RGB write path is limited to:

- MSI Katana 17 B13VGK
- MysticLight MS-1565 controller (`1462:1601`, serial `4062C8A28000`)
- a single **non-persistent** steady color over the selected zones
- transport: hidapi/libusb (usbfs) from the root daemon
- non-persistent effect modes (breathing/cycle/wave) through the daemon
  `SetRgbPresetEffect` semantic method: one user color + mode; the daemon
  derives companion colors (cycle +180°, wave +120/+240°) so clients
  never marshal `a(yyy)` (implemented; desktop visual test pending)

No flash-save (0xA0) in these calls, no per-key mode.

## Safety behavior

`SetRgbColor(zones, r, g, b)` validates the zone mask (bits 0-3), requires
the daemon opt-in `MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1` and Polkit action
`org.msilinux.Center.set-rgb-color`, then sends two 64-byte feature
reports (zone select, steady effect with one color keyframe). The device
has no read-back; a reboot or the previous effect state is not preserved by
the daemon — verification is visual, and nothing is written to flash.

## Controlled local validation

Non-persistent effects (do not automate; low risk — nothing is written to
flash):

1. Confirm `msicenter status` shows the RGB controller (name + serial).
2. Install the updated daemon, systemd unit, D-Bus policy, and Polkit action.
3. Set a systemd override with `Environment=MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1`,
   then restart the daemon.
4. `msicenter rgb-color f ff0000` → whole keyboard solid red.
5. `msicenter rgb-effect f breath 3 ff0000,0000ff` → red/blue breathing.
6. `msicenter rgb-effect f wave 5 ff0000,00ff00,0000ff` → color wave.
7. `msicenter rgb-effect f cycle 4 ff0000,00ff00` → color cycle.
8. Test a single zone: `msicenter rgb-effect 1 steady 1 00ff00`.
9. Clear: `msicenter rgb-color f 000000`.
10. Disable the opt-in and confirm all `SetRgb*` calls are rejected.

### Flash-save validation (separate, higher-risk)

Flash-save overwrites the controller's persistent state — including any
effect set from Windows/MSI Center. Do this only if you intend to keep the
state permanently. Record the current (Windows) effect first, because there
is **no restore path** other than re-flashing from MSI Center later.

1. Set the desired state with non-persistent calls first and confirm it.
2. Add a systemd override with
   `Environment=MSI_LINUX_CENTER_ENABLE_RGB_FLASH_WRITES=1` and restart.
3. Run `msicenter rgb-save` and complete the Polkit prompt.
4. Reboot and confirm the saved state survived.
5. Remove the override; confirm `SaveRgbState` is rejected while disabled.

Only after successful physical verification should the device provenance
set `writes_tested` to `true`.

## Verification record (2026-09-06)

Performed on the reference laptop (Katana 17 B13VGK, controller serial
`4062C8A28000`):

- `msicenter status` reported the controller (name + serial).
- Opt-in override `Environment=MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1`; unit
  updated to allow `AF_NETLINK` (libusb udev monitor) — without it the
  daemon's hidapi init fails.
- `msicenter rgb-color f ff0000` → solid red across all zones
- `msicenter rgb-color 1 00ff00` → zone 1 green
- `msicenter rgb-color f 0000ff` → blue; `msicenter rgb-color f 000000` →
  LEDs off
- `msicenter rgb-effect f breath 3 ff0000,0000ff` → breathing
- `msicenter rgb-effect f wave 5 ff0000,00ff00,0000ff` → color wave
- `msicenter rgb-effect f cycle 4 ff0000,00ff00` → color cycle
- `msicenter rgb-effect 1 steady 1 00ff00` → zone 1 steady green
- opt-in override removed; all `SetRgb*` calls rejected with
  `org.freedesktop.DBus.Error.NotSupported` while disabled
- no flash-save was ever sent; effects are non-persistent

Outcome: non-persistent RGB color and effect write verification passed.
