# Phase 5 — Custom fan curve: design study

Status: **pre-design, no code.** This document collects the hardware evidence,
backend options, safety gates, and open decisions required before any custom
fan-curve implementation can start. It follows `MSI-Linux-Center-AGENTS.md`
§23 ("Future fan-control rules") and §5.3 (raw EC as last resort).

Acceptance criteria for this document: (1) all local hardware facts are
recorded with dates; (2) every backend option is analyzed against AGENTS
principles; (3) the §23 safety-gate list is mapped to concrete checks;
(4) open decisions are explicit; (5) no implementation code is added.

## 1. Reference device evidence (2026-09-05)

Local, read-only observations on the Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`):

- `msi-ec` 0.13 exposes `fan_mode` with driver presets `auto` / `silent` / `advanced`
  (EC register `0xd4`); no `basic` mode on this model.
- The `msi-ec` 0.13 source contains **no fan-curve or PWM code path**; custom
  curves cannot be expressed through the current driver.
- `msi_wmi_platform` hwmon exposes only `fan*_input` RPM; **no `pwm*` or
  `*_auto_point*` attributes** exist for this device.
- No hwmon device on this machine exposes PWM controls.

External, cross-checked references:

- GhostDeck (`wygodad/ghostdeck`) lists the `17L5EMS1.*` EC family as **tested**,
  with fan curve **editable**. It documents fixed G2 fan-curve EC tables at
  CPU `0x6A`/`0x72` and GPU `0x82`/`0x8A`, the same addresses MControlCenter
  writes across the family.
- GhostDeck writes EC registers through the official MSI WMI method
  `MSI_ACPI.Set_Data` (32-byte package), the same interface MSI Center uses.
  Writes are **volatile**: a reboot restores firmware defaults.
- MControlCenter applies curves in userspace through EC access
  (`ec_sys write_support=1`) — the raw-EC path.
- A `msi-wmi-platform` patch series adds real hwmon fan-curve tables
  (`pwm*_auto_point*_temp/_pwm`) for WMI devices, but that support does not
  exist for this device's driver today.

## 2. Concept separation (AGENTS §23)

The feature must keep these distinct and never conflate them:

- fan RPM (`fan*_input`, `msi_wmi_platform`)
- EC fan level / duty-like values (`msi-ec` realtime fan speeds — not RPM)
- fan mode (`fan_mode`: auto / silent / advanced)
- **custom fan curve (Phase 5 — this design)**
- Cooler Boost (independent maximum-fan toggle)

A custom curve is a temperature→speed policy that only applies while the EC
runs in an appropriate mode. Firmware thermal protection must never be
disabled by any curve.

## 3. Target behavior

User intent (future UI/CLI): define a per-CPU and per-GPU curve of points
`(temperature, fan speed)` and have the EC follow it instead of its built-in
`advanced` profile.

Semantic API shape (no raw registers):

```rust
// msi-core sketch only — not implemented
pub struct FanCurvePoint { pub temperature_c: u8, pub speed_percent: u8 }
pub struct FanCurve { pub points: Vec<FanCurvePoint> }
// D-Bus (future): SetFanCurve(cpu_or_gpu, curve), ResetFanCurve(cpu_or_gpu)
```

## 4. Backend options

| Option | Path | Fit with AGENTS | Risks / cost |
|---|---|---|---|
| A. Extend `msi-ec` with fan-curve support | add a per-model curve feature and semantic sysfs attrs to the DKMS driver | best: "kernel interface first", semantic, no raw EC in the app | driver work + DKMS rebuild; needs per-model reverse engineering; multi-week effort |
| B. WMI `MSI_ACPI.Set_Data` from a daemon path | official MSI WMI method (GhostDeck-proven) | medium-high: official vendor interface, volatile writes | no in-kernel Linux helper exists for this method; needs a kernel module or accepted WMI evaluate path; unverified on this exact EC |
| C. `ec_sys` write_support raw EC | userspace EC byte writes (MControlCenter path) | low: raw EC is "last resort" per §5.3 | no driver validation, no read-back semantics, model-specific addresses; requires re-deriving + proving every register |

**Recommended direction: Option A (extend `msi-ec`)** — it matches the project's
kernel-first principle and would make the curve readable and verifiable through
the same sysfs abstraction the rest of this project uses. Options B/C remain
documented fallbacks if upstream work stalls; they require an explicit safety
review before any write code.

## 5. Safety gates before ANY curve write (from AGENTS §23)

1. Inspect GhostDeck `Devices.cs` mapping for `17L5EMS1.115` (CPU/GPU table
   layout, point count, value encoding).
2. Inspect relevant `msi-ec` code/issues for curve semantics on the G2 family.
3. Read the factory/current curve if the chosen backend can read it; otherwise
   treat the curve as unreadable and require a different rollback strategy.
4. Save a recoverable baseline (current EC curve snapshot or documented factory
   default) before the first write.
5. Validate point count (bounds per backend table).
6. Validate temperature ordering (strictly ascending).
7. Validate speed bounds (0–100% and any per-point EC encoding limits).
8. Enforce safe high-temperature behavior (speed at the top temperature must
   not drop below the vendor default; never allow a curve that reduces cooling
   above the highest point).
9. Write minimally (smallest table change that expresses the curve).
10. Read back through the same backend and verify exact equality.
11. Physically validate fan response across at least two curve points.
12. Implement reset/restore (`ResetFanCurve`) with a documented default.

Per-feature gates from §35 also apply: exact verified firmware only, Polkit
action, per-feature daemon opt-in (`MSI_LINUX_CENTER_ENABLE_FAN_CURVE_WRITES=1`),
read-back + rollback, provenance (`writes_tested`) updated only after physical
verification.

## 6. Open decisions / unknowns

- Does the `17L5EMS1.115` EC store a writable curve, or only a fixed 6-level
  `advanced` table? (GhostDeck says editable for the family; must be confirmed
  on this exact firmware with a read-only capture first.)
- Exact curve layout for this EC: point count, temperature granularity, speed
  encoding, CPU/GPU table sizes, and whether the curve applies in `advanced`
  mode only.
- Whether a Linux userspace→EC path can exist without kernel changes
  (Option B feasibility on this device: the laptop's `msi_wmi_platform` does
  not expose the Set_Data method today).
- Thermal validation protocol: acceptable load steps and soak times to confirm
  the curve is honored without triggering firmware protection.

## 7. Suggested next steps (no code yet)

1. Read-only EC capture of the current curve tables (GhostDeck diagnostics
   workflow, or `msi-ec` debug) to confirm layout — record as provenance.
2. Open/join `msi-ec` discussion about G2 fan-curve support; sketch the driver
   feature if maintainers are receptive (Option A).
3. Revisit this document with the capture results and decide A/B/C.

## 8. Sources

- GhostDeck README / `Devices.cs` / FAQ — https://github.com/wygodad/ghostdeck
- `msi-ec` (BeardOverflow) — https://github.com/BeardOverflow/msi-ec (local
  DKMS source `/usr/src/msi_ec-0.13/msi-ec.c`, v0.13)
- MControlCenter — https://github.com/mutchiko/MControlCenter
- `msi-wmi-platform` fan-curve patch series (lkml, WMI devices)
- `MSI-Linux-Center-AGENTS.md` §23, §5.3, §35, §34
