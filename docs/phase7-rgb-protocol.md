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

## 2. OpenRGB cross-check (2026-09-05)

- `Controllers/MSI3ZoneController` (8-byte feature reports, VID
  `0x1770:0xFF00`) — SteelSeries/MSI 3-zone keyboard; **not this device**.
- `Controllers/MSIMysticLightController` registers USB detectors for VID
  `0x1462` with motherboard-style PIDs (0x3EA4, 0x4459, 0x7B10…0x7C42);
  **0x1601 is not among the detectors seen in master**.
- The owner reports OpenRGB (1.0rc3) lists the device as
  "MSI MysticLight MS-1565" (equals the USB/HID product string).
  Whether OpenRGB can actually drive it (detector match, not just listing)
  is **unconfirmed** — see open questions.

## 3. Cross-source comparison

The 64-byte feature-report scheme (report 2 / packet id / payload, flash
save at 0xA0) is consistent with the "MSI GL66 Mystic Light Keyboard
(64 Byte)" family naming used by OpenRGB's wiki. The OpenRGB 64-byte
keyboard controller source could not be located in master under the
`Controllers/` paths inspected; locating it (or the detector that matches
PID 0x1601) is required before protocol documentation is complete.

## 4. Open questions

1. Which OpenRGB controller (if any) matches PID 0x1601, and does it use
   the same 64-byte layout? (Search outside `Controllers/` — e.g.
   detectors/registration tables — or confirm via a fresh `git grep` with
   full blobs.)
2. Can the owner actually change colors in OpenRGB for this device, or is
   it only listed?
3. Baseline: what effect/color is currently active (Windows-set) before
   any first write?

## 5. Sources

- `sarpowsky/msi-katana-rgb` `src/keyboard.py` (protocol by natanalt)
- OpenRGB master, `Controllers/MSI3ZoneController/`,
  `Controllers/MSIMysticLightController/` (detectors)
- OpenRGB Wiki "MSI GL66 Mystic Light Keyboard (64 Byte)"
- AGENTS §24, §6.4
