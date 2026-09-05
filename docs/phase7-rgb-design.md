# Phase 7 — RGB (MysticLight MS-1565): design study

Status: **pre-design, no code.** Follows the Phase 5/6 pattern: record local
hardware facts, analyze backend options against AGENTS rules (§24), list the
safety gates and open decisions.

Acceptance criteria: local evidence recorded with dates; §24 rules mapped to
concrete checks; backend options analyzed; local blocker (hidraw) documented
with remediation paths; no implementation code.

## 1. Reference device evidence (2026-09-05)

Local observations on the Katana 17 B13VGK:

- USB device present: `1462:1601` "Micro Star International MysticLight MS-1565"
  (`lsusb`), one interface (`bNumInterfaces 1`), `bInterfaceClass 3`
  (Human Interface Device).
- HID device registered: `/sys/bus/hid/devices/0003:1462:1601.0001`,
  `HID_NAME=MSI MysticLight MS-1565`, bound to `hid-generic`,
  `HID_PHYS=usb-0000:00:14.0-7/input0`, `HID_UNIQ=4062C8A28000`.
- **Local blocker:** no `/dev/hidraw*` nodes exist and no `hidraw` entry in
  `/proc/misc` anywhere on this system, even though
  `/lib/modules/$(uname -r)/build/.config` reports `CONFIG_HIDRAW=y`
  (config/build tree may not match the running kernel). Other HID devices
  (Logitech hidpp, touchpad) also lack hidraw nodes.
- The profile declares `rgb: true` with `rgb_usb_vid/pid`; the daemon already
  detects the backend via USB VID/PID (`has_usb_device`, `rgb_hid` flag).

## 2. External references (2026-09-05)

- The `1462:1601` controller is common to Katana 15/17, Bravo 15, Pulse 15/17
  (linux-hardware.org).
- OpenRGB supports the laptop path; its disabled "MSI Mystic Light" code
  concerns motherboard **SMBus** controllers (brick reports) — a different
  transport from this laptop's USB HID controller.
- Tools of the same family talk to the controller through `/dev/hidraw*`
  (hidapi) or raw USB with a udev rule granting the user access
  (`msi-perkeyrgb`, `msi-katana-rgb`).
- Packet format and report/interface identity must be re-derived from
  `msi-katana-rgb` (project rule §24) and ideally captured from MSI Center on
  Windows; no local capture exists yet.

## 3. AGENTS §24 rule mapping (pre-write checklist)

1. Inspect `msi-katana-rgb` — implementation phase task, before any write code.
2. Document the packet format — deliverable of the same phase (docs/).
3. Confirm report/interface identity against the local device
   (HID descriptor read over the chosen backend).
4. Test non-persistent state first if the protocol supports it.
5. Avoid flash/persistent writes until temporary writes are validated.
6. Test one zone/color at a time.
7. Add bounds validation (zone indexes, channel values, color ranges).
8. Add fixture/protocol unit tests with captured packets.

Persistent/flash-save commands are treated as a separate, higher-risk feature.

## 4. Backend options

| Option | Path | Fit | Notes |
|---|---|---|---|
| A. `/dev/hidraw` via hidapi | standard kernel HID raw node | best ("kernel interface first") | **blocked locally**: no hidraw nodes on this kernel; needs kernel/module fix or a different kernel line first |
| B. libusb over usbfs (`/dev/bus/usb`) | raw USB control/interrupt transfers | works without hidraw; daemon runs as root anyway | more raw than hidraw; still the official USB transport; needs the interface to be detached/claimed carefully |
| C. OpenRGB as a subprocess/backend | external controller | fastest demo, no protocol work | outsources the safety-critical layer; conflicts with the project's "self-contained verified platform" goal; still an option for UI prototyping |

**Recommended direction:** A if the hidraw blocker is lifted (kernel rebuild
or switch to a kernel with `CONFIG_HIDRAW`), otherwise B from the daemon.
Either way the daemon owns the HID device; the GUI stays unprivileged and
talks to a future `org.msilinux.Center1.Rgb` interface over D-Bus.

## 5. Local blocker remediation paths (hidraw)

- Check whether the running kernel actually ships hidraw (`/proc/misc`,
  `/dev/hidraw*`); if the build config mismatches, rebuild/replace the LTS
  kernel or use the fallback kernel line.
- If hidraw becomes available: add a udev rule granting the daemon (root) —
  and only optionally the desktop user — access to the device node.
- Re-verify with `ls /dev/hidraw*` + `hidapi` enumeration before any write.

## 6. Architecture sketch (future, no code)

```
msi-hardware (daemon, root)
  -> rgb backend (hidraw or libusb): open device, enumerate reports
msi-dbus: org.msilinux.Center1.Rgb
  -> properties: controller present, zones/effects (read)
  -> methods (future, gated): SetLightingZone / SetEffect — semantic only,
     no raw report API (§5.2)
msicenter-ui: RGB section under the same Polkit-gated write pattern
```

Per-feature gates from §35 apply: Polkit action, daemon opt-in env, exact
device identity check (VID/PID + HID_UNIQ), provenance `writes_tested` only
after physical validation, non-persistent first.

## 7. Open decisions / unknowns

- Running kernel hidraw availability (config mismatch vs reality).
- Exact report IDs and packet layout for this controller (from `msi-katana-rgb`
  + optional Windows capture); whether the protocol has a non-persistent mode.
- Whether any effect currently active on the device (user's Windows-set color)
  must be captured as a baseline before the first write.
- udev/access policy: daemon-only vs desktop-user access.

## 8. Sources

- AGENTS §24 (RGB rules), §6.4 (controller identity), §5.2 (semantic APIs), §35
- `msi-katana-rgb` (sarpowsky) — protocol reference (project rule)
- `msi-perkeyrgb` (Askannz) — hidraw/hidapi technique + udev
- OpenRGB README (MSI SMBus caveat; laptop USB path distinct)
- linux-hardware.org `usb:1462-1601`
- Local checks 2026-09-05: `lsusb`, `/sys/bus/hid/devices/0003:1462:1601.0001`,
  `/proc/misc`, `/lib/modules/.../.config`
