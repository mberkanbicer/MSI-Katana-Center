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

Provenance `writes_tested` stays false until this run is recorded.
