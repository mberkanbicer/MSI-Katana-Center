# Phase 7 — RGB non-persistent color validation

## Support scope

The first RGB write path is limited to:

- MSI Katana 17 B13VGK
- MysticLight MS-1565 controller (`1462:1601`, serial `4062C8A28000`)
- a single **non-persistent** steady color over the selected zones
- transport: hidapi/libusb (usbfs) from the root daemon

No flash-save (0xA0), no effects beyond steady, no per-key mode.

## Safety behavior

`SetRgbColor(zones, r, g, b)` validates the zone mask (bits 0-3), requires
the daemon opt-in `MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1` and Polkit action
`org.msilinux.Center.set-rgb-color`, then sends two 64-byte feature
reports (zone select, steady effect with one color keyframe). The device
has no read-back; a reboot or the previous effect state is not preserved by
the daemon — verification is visual, and nothing is written to flash.

## Controlled local validation

Do not automate these steps. Record the current lighting state first.

1. Confirm `msicenter status` shows the RGB controller (name + serial).
2. Install the updated daemon, systemd unit, D-Bus policy, and Polkit action.
3. Set a systemd override with `Environment=MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1`,
   then restart the daemon.
4. Run `msicenter rgb-color f ff0000` as the desktop user and complete the
   Polkit prompt: the whole keyboard should turn solid red (non-persistent).
5. Cross-check with OpenRGB: set the same color in OpenRGB and confirm it
   matches; then set a second color through the CLI (`00ff00`) and confirm
   the keyboard follows without any flash/reboot side effects.
6. Test one zone at a time (`1`, `2`, `4`, `8`) with a distinct color each.
7. Turn the keyboard off with `msicenter rgb-color f 000000`.
8. Disable the opt-in and confirm `SetRgbColor` is rejected while disabled.
9. Reboot and confirm the pre-existing (Windows/MSI Center) effect is back —
   proving nothing was persisted.

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
- opt-in override removed; `SetRgbColor` rejected with
  `org.freedesktop.DBus.Error.NotSupported` while disabled
- no flash-save was ever sent; effect is non-persistent

Outcome: non-persistent RGB color write verification passed.
