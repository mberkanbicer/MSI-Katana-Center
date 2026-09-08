# Phase 6 — UI write visual test

Desktop session checklist for write controls in `msicenter-ui`.
Do **not** automate these steps. Do **not** run them from an agent session.

The UI is an unprivileged D-Bus client. Polkit, firmware, and opt-in gates
stay in `msi-daemon`. Record daemon replies verbatim (including refusals).

## Preconditions

- Reference laptop: Katana 17 B13VGK, board `MS-17L5`, EC `17L5EMS1.115`
- Daemon installed; all `MSI_LINUX_CENTER_ENABLE_*_WRITES` still `0` for part A
- Desktop user, no `sudo` on the CLI or UI
- Record `msicenter status --json` before any opt-in change

## A. Opt-ins off (must refuse)

Start the UI as the desktop user. For each control, trigger once and confirm
the daemon `NotSupported` (or equivalent) reason is shown in the status line /
OSD, and that sysfs/EC state is unchanged:

| Control | Where | Shortcut / tray |
|---------|--------|-----------------|
| Fan mode | Power & Fans | — |
| Cooler Boost | Power & Fans | Ctrl+Shift+C, tray |
| Super Battery | Power & Fans | Ctrl+Shift+B, tray |
| Battery thresholds | Battery | Travel arming if used |
| Webcam / webcam-block / Fn | Power & Fans | — |
| RGB color / effect | Keyboard RGB | Ctrl+Shift+L (off), tray |
| Scene apply | Scenes | — |
| Panic reset | — | Ctrl+Shift+P |

RGB flash-save is a separate, higher-risk opt-in. Skip it unless that test is
explicitly scheduled (`docs/phase7-rgb-validation.md`).

## B. One feature at a time (opt-in on)

For **one** already physically verified feature (prefer fan-mode `silent`,
least intrusive):

1. systemd drop-in: only that feature's `ENABLE_*=1`; restart daemon
2. Trigger the matching UI control; complete Polkit
3. Confirm UI reply, `msicenter status`, and sysfs match
4. Restore the previous value through the same UI control
5. Remove the drop-in; confirm the control refuses again

Do not batch unrelated writes. Do not touch Phase 5 fan-curve registers.

## Software stand-in (no display / no hardware)

`./scripts/ui-write-gating-check.sh` checks CLI write commands fail closed
without a system bus, and that the fixture status path still works. It does
not replace this desktop test.

## Record

Date, firmware, which controls were clicked, opt-in state, Polkit result,
whether read-back matched, and any UI mismatch vs CLI.
