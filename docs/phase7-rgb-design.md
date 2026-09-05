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
- **No hidraw in this kernel:** no `/dev/hidraw*` nodes, no `hidraw` in
  `/proc/misc`, no `hidraw` driver under `/sys/bus/hid/drivers/` on
  `linux-lts 6.18.49-2` (the `/lib/modules/.../build/.config` value
  `CONFIG_HIDRAW=y` belongs to a different kernel tree — mismatch).
- **hidraw is not needed:** `libusb 1.0.30` and `hidapi 0.15.0` are
  installed; OpenRGB reaches the same device over usbfs via libusb when run
  as root (confirmed working by the owner), and the daemon runs as root.
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
- **OpenRGB (local, 2026-09-05):** version 1.0rc3 installed and used by the
  owner. The device family is registered in OpenRGB as
  "MSI GL66 Mystic Light Keyboard (64 Byte)" (vendor 1462, several PIDs;
  controller sources under `Controllers/MysticLightController/`), i.e. a
  64-byte Mystic Light keyboard protocol family that includes the Katana
  MS-1565 controller. Local check: a non-root OpenRGB server run detected
  **0 controllers** (usbfs access requires root or a udev rule; no hidraw on
  this system), so the owner runs it privileged. **Owner-confirmed on
  2026-09-05:** OpenRGB lists the device as "MSI MysticLight MS-1565"
  (identical to the kernel `HID_NAME`), so PID `1601` is matched inside
  OpenRGB's supported 64-byte family.
- Packet format and report/interface identity must be re-derived from
  `msi-katana-rgb` (project rule §24) and cross-checked against OpenRGB's
  64-byte Mystic Light keyboard controller code; no local capture exists yet.

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
| A. hidapi with **libusb backend** from the root daemon | usbfs via libusb (same path OpenRGB uses) | best available: no hidraw required, vendor HID API, proven working on this device via OpenRGB | needs the `hidapi` Rust crate (libusb feature) or `rusb`; system `libusb 1.0.30` + `hidapi 0.15.0` present; daemon runs as root |
| B. `/dev/hidraw` via hidapi (hidraw backend) | kernel hidraw nodes | cleanest long term ("kernel interface first") | **not available on this kernel** (no CONFIG_HIDRAW build); revisit if the kernel changes |
| C. OpenRGB as a subprocess/backend | external controller | fastest demo, no protocol work | outsources the safety-critical layer; conflicts with the project's "self-contained verified platform" goal; still an option for UI prototyping |

**Recommended direction:** A if the hidraw blocker is lifted (kernel rebuild
or switch to a kernel with `CONFIG_HIDRAW`), otherwise B from the daemon.
Either way the daemon owns the HID device; the GUI stays unprivileged and
talks to a future `org.msilinux.Center1.Rgb` interface over D-Bus.
OpenRGB stays a **reference and validation tool**: its 64-byte Mystic Light
keyboard controller code is cross-checked during protocol documentation
(§24 rule 1–2), and its SDK/CLI can serve as a temporary side-by-side
verifier during the first non-persistent writes.

## 5. Transport decision (2026-09-06)

- The running `linux-lts 6.18.49-2` kernel ships **no hidraw**; the earlier
  `CONFIG_HIDRAW=y` value came from a mismatched build tree. Confirmed:
  no `/proc/misc` entry, no `/sys/bus/hid/drivers/hidraw`.
- **Decision: option A — hidapi with its libusb backend, called from the
  root daemon.** This is exactly how OpenRGB reaches the same device
  (usbfs), and it requires no kernel changes. System `libusb 1.0.30` and
  `hidapi 0.15.0` are installed.
- Revisit hidraw only if the kernel is replaced with one that builds
  `CONFIG_HIDRAW`; no udev rule is needed while only the root daemon talks
  to the device.

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
- OpenRGB Wiki: "MSI GL66 Mystic Light Keyboard (64 Byte)" (supported PID
  family); controller sources `Controllers/MysticLightController/`
- Local OpenRGB 1.0rc3 (2026-09-05): owner-used; non-root server run found
  0 controllers (usbfs needs root/udev; no hidraw on this system)
- linux-hardware.org `usb:1462-1601`
- Local checks 2026-09-05: `lsusb`, `/sys/bus/hid/devices/0003:1462:1601.0001`,
  `/proc/misc`, `/lib/modules/.../.config`
