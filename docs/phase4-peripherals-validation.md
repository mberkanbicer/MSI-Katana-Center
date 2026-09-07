# Phase 4 peripherals validation (webcam, webcam block, Fn/Win)

## Support scope

Limited to the Katana 17 B13VGK, board `MS-17L5`, EC `17L5EMS1.115`, through
`msi-ec` sysfs:

- `webcam` / `webcam_block` — `on`/`off`
- `fn_key` — `left`/`right` (Win key is the other side of the same swap)

## Safety

Each method reads the previous value, writes, reads back, and restores on
mismatch. No raw addresses. Opt-ins default off:

- `MSI_LINUX_CENTER_ENABLE_WEBCAM_WRITES=1`
- `MSI_LINUX_CENTER_ENABLE_WEBCAM_BLOCK_WRITES=1`
- `MSI_LINUX_CENTER_ENABLE_FN_KEY_WRITES=1`

Polkit: `org.msilinux.Center.set-webcam`, `.set-webcam-block`, `.set-fn-key`.

Webcam block is a hardware kill: the keyboard webcam key cannot re-enable the
camera while it is on. Test last and restore `off`.

## Controlled local validation

Do not automate. Record the original `msicenter status` lines first.

1. Install the daemon, Polkit actions, and systemd unit; restart the daemon.
2. Enable one opt-in at a time via a systemd override; restart.
3. `msicenter webcam off` then `on` — confirm sysfs and the camera node.
4. `msicenter fn-key left` then restore `right` (or whatever the original was).
5. Only if you intend to: `msicenter webcam-block on`, confirm the camera stays
   off, then `webcam-block off`.
6. Remove the override; confirm writes return `NotSupported`.

Provenance `writes_tested` stays false per remaining feature until that run is recorded.

## Verification record — webcam on/off (2026-09-07)

Performed on the reference laptop (Katana 17 B13VGK, MS-17L5, EC `17L5EMS1.115`):

- original state: webcam `on`, webcam_block `off`, Fn `right`, Win `left`
- drop-in `Environment=MSI_LINUX_CENTER_ENABLE_WEBCAM_WRITES=1`; daemon restarted; `systemctl show` reported `WEBCAM_WRITES=1` and `WEBCAM_BLOCK_WRITES=0`
- `msicenter webcam off` → D-Bus `{"webcam":false}`, sysfs `off`
- `msicenter webcam on` → D-Bus `{"webcam":true}`, sysfs `on`
- drop-in removed; daemon restarted
- negative check: `msicenter webcam off` rejected with `org.freedesktop.DBus.Error.NotSupported` (`webcam writes disabled`)

Outcome: physical webcam on/off write verification passed. `webcam_block` and `fn_key` writes are still untested.

## Verification record — Fn/Win swap (2026-09-07)

Performed on the reference laptop (Katana 17 B13VGK, MS-17L5, EC `17L5EMS1.115`):

- original state: Fn `right`, Win `left`
- drop-in `Environment=MSI_LINUX_CENTER_ENABLE_FN_KEY_WRITES=1`; daemon restarted; `systemctl show` reported `FN_KEY_WRITES=1`
- `msicenter fn-key left` → D-Bus `{"fn_key":"left","win_key":"right"}`, sysfs `left` / `right`
- `msicenter fn-key right` → D-Bus `{"fn_key":"right","win_key":"left"}`, sysfs `right` / `left`
- drop-in removed; daemon restarted
- negative check: `msicenter fn-key left` rejected with `org.freedesktop.DBus.Error.NotSupported` (`fn-key writes disabled`)

Outcome: physical Fn/Win swap write verification passed.

## Verification record — webcam block (2026-09-07)

Performed on the reference laptop (Katana 17 B13VGK, MS-17L5, EC `17L5EMS1.115`):

- original state: webcam_block `off`
- drop-in `Environment=MSI_LINUX_CENTER_ENABLE_WEBCAM_BLOCK_WRITES=1`; daemon restarted; `systemctl show` reported `WEBCAM_BLOCK_WRITES=1`
- `msicenter webcam-block on` → D-Bus `{"webcam_block":true}`, sysfs `on`
- `msicenter webcam-block off` → D-Bus `{"webcam_block":false}`, sysfs `off`
- drop-in removed; daemon restarted
- negative check: `msicenter webcam-block on` rejected with `org.freedesktop.DBus.Error.NotSupported` (`webcam-block writes disabled`)

Outcome: physical webcam-block write verification passed. All three peripheral write paths in this document are now verified.
