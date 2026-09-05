# Phase 7 — MysticLight MS-1565 (1462:1601) protocol notes

Status: **documentation of cross-referenced sources, no code, no writes.**
Inputs: `msi-katana-rgb` (sarpowsky, protocol by natanalt) and OpenRGB
controller sources, both cloned 2026-09-05 to a temp dir for reference.

## 1. msi-katana-rgb protocol summary (src/keyboard.py)

Transport: USB HID **feature reports** via hidapi
(`send_feature_report`); read-back report ID 1; 64-byte packets.

Packet layout:

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | report id = 2 (write) |
| 1 | 1 | packet id (see below) |
| 2..63 | 62 | payload, zero-padded to 64 |

Packet ids:

| id | hex | meaning |
|---|---|---|
| 1 | 0x01 | select zones — payload: 1 byte zone bitmask |
| 2 | 0x02 | set effect — payload below |
| 160 | 0xA0 | save to flash (persistent) |
| 176 | 0xB0 | load from flash |

Zone bitmask: 4 zones, bits 0–3 left→right; `0b1111` = all.

Effect payload (after packet id 2):

| offset | size | field |
|---|---|---|
| 0 | 1 | effect type |
| 1 | 2 | speed, u16 LE (seconds × 100) |
| 3 | 4 | constant bytes `00 00 0F 01` |
| 7 | 1 | wave direction (0 right→left, 1 left→right) |
| 8.. | 4×N | keyframes: `time(0..100), r, g, b` (last time = 100) |

Effect types: 0 off, 1 steady, 2 breath, 3 color cycle, 4 color wave.

⚠️ The reference tool's convenience methods (`set_color`, `turn_off`) call
`save_to_flash` **by default**. AGENTS §24 requires non-persistent testing
first; any implementation must expose the flash save only as a separate,
explicitly gated action.

## 2. OpenRGB cross-check

- OpenRGB 1.0rc3 (owner's installed version; source tarball
  `release_candidate_1.0rc3`, 2026-09-06): the matching controller is
  **`Controllers/MSIKeyboardController/MSIMysticLightKBController/`**, with
  `REGISTER_HID_DETECTOR_PU("MSI Keyboard MS_1565", DetectMSIKeyboardController,
  MSI_USB_VID 0x1462, 0x1601, 0x00FF, 0x01)` — PID **0x1601 is confirmed**.
  The name shown by the owner in OpenRGB ("MSI MysticLight MS-1565") is the
  USB product string; the detector name is "MSI Keyboard MS_1565".
- The owner confirmed (2026-09-06) that OpenRGB can actually **change the
  keyboard color**, so this controller path is a working reference.
- `Controllers/MSI3ZoneController` (8-byte feature reports, VID
  `0x1770:0xFF00`) is a different device.
- The `MSIMysticLightController` SMBus/motherboard family
  (0x3EA4…0x7C42 detectors) does not include 0x1601, and the "brick"
  caveat applies to that SMBus path, not to the keyboard controller.
- Note: a master-branch clone (mullcom mirror, 2026-09-05) predates the
  RC3 keyboard controller; RC3 is the correct reference revision.

## 3. Cross-source comparison

The 64-byte feature-report scheme (report 2 / packet id / payload, flash
save at 0xA0) is consistent with the "MSI GL66 Mystic Light Keyboard
(64 Byte)" family naming used by OpenRGB's wiki. The OpenRGB 64-byte
keyboard controller source could not be located in master under the
`Controllers/` paths inspected; locating it (or the detector that matches
PID 0x1601) is required before protocol documentation is complete.

## 4. Open questions

1. **RESOLVED (2026-09-06):** the matching OpenRGB controller is
   `MSIMysticLightKBController` (RC3), PID 0x1601 confirmed; the owner can
   change colors with it.
2. Byte-level comparison of `MSIMysticLightKBController.cpp` packet layout
   against the msi-katana-rgb scheme (report 2 / packet ids / effect payload)
   is the next documentation step; any divergence must be recorded here.
3. Baseline: what effect/color is currently active (Windows-set) before
   any first write?

## 5. Sources

- `sarpowsky/msi-katana-rgb` `src/keyboard.py` (protocol by natanalt)
- OpenRGB master, `Controllers/MSI3ZoneController/`,
  `Controllers/MSIMysticLightController/` (detectors)
- OpenRGB Wiki "MSI GL66 Mystic Light Keyboard (64 Byte)"
- AGENTS §24, §6.4
