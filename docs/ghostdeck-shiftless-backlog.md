# GhostDeck-inspired backlog (no shift writes)

Date: 2026-09-07. Planning only.

GhostDeck is a mature Windows tray app. This list is the subset of its
product surface that can be taken on Linux **without** `SetShiftMode`,
without fan-curve writes, and without MUX. Every item reuses existing
gated D-Bus methods (fan mode, Cooler Boost, Super Battery, battery
thresholds, RGB, webcam/Fn) or is client-only.

## Goal

A short, ordered backlog of product gaps versus GhostDeck that are
legal under `MSI-Linux-Center-AGENTS.md` today.

## Non-goals

- `SetShiftMode` / MSI Center Silent·Balanced·Extreme recipes that
  write `0xd2` (`0xc0` has no sysfs rollback).
- Labelling a scene "Silent" or "Extreme" as if it were a GhostDeck
  scenario. Silent vs Balanced on this EC differ in `0xd4` **and**
  shift; without shift they are not the same product.
- Fan-curve editor, fan sweep, curve presets (Phase 5; blocked on §11).
- MUX / MSHybrid (Phase 10). USB power share. EC keyboard backlight.
- Gaming HUD / FPS / PresentMon clones (use MangoHud).
- Multi-model signed database, in-app updater, Windows-only APIs
  (HDR, Win-key lock as a software hook).
- New daemon write methods.

## Already covered (do not re-implement)

| GhostDeck | Here |
|---|---|
| Fan Boost | `SetCoolerBoost` verified |
| Super Battery bit | `SetSuperBattery` verified |
| Fan auto/silent/advanced | `SetFanMode` verified |
| Charge limit | `SetBatteryThresholds` start **and** end |
| 4-zone RGB | HID effects (GhostDeck does not do this on this laptop) |
| Webcam + hard block | writes verified 2026-09-07 |
| Fn/Win swap | writes verified 2026-09-07 |
| Scenes | `scenes.json` + CLI/UI apply (narrower field set) |
| Tray + OSD toast | tray menu, `OSD.qml` on write completion |
| Diagnostics | redacted `DiagnosticReport` JSON |
| Firmware gate | exact `17L5EMS1.115` already blocks writes |

## User-side (no code)

These unblock features we already shipped:

1. Webcam on/off, webcam block, and Fn/Win physically verified 2026-09-07 (`docs/phase4-peripherals-validation.md`).
2. RGB flash-save physical test (`SaveRgbState`, separate opt-in).
3. Desktop UI tour: RGB effects, tray apply-scene, Diagnostics copy.
4. Phase 5 §11 one-byte curve experiment — **only** when the user runs
   it in their own terminal. No curve code until then.

---

## P1 — thin client, existing writes

Smallest diffs. Daemon unchanged.

### 1. Cooler Boost auto-off timer — implemented 2026-09-07

GhostDeck: Fan Boost auto-off 30 s–15 min.

- UI: after a successful `SetCoolerBoost(true)` (page, tray, shortcut,
  or scene), start a user-space timer and call `SetCoolerBoost(false)`.
- Cancel if the user turns Boost off, or if EC reports off after it
  was seen on. Duration 0 / Off = no timer.
- Persist in `~/.config/msi-linux-center/ui.json`
  (`cooler_boost_auto_off_seconds`). Daemon never reads it.
- No CLI `--for` (one-shot process); no daemon timeout.
- Timer dies if the UI quits; hide-to-tray keeps it.

### 2. Panic reset (stock-without-shift) — implemented 2026-09-07

GhostDeck: `Ctrl+Alt+F10` → Fan Boost off, Balanced, auto curve.

Without shift, "stock" means Cooler Boost off, Super Battery off, fan
`auto`. RGB is left alone. Does **not** claim Balanced or restore
`0xc0`; the live `shift_mode` is shown verbatim on the Power page.

- UI button, tray entry, `Ctrl+Shift+P`, CLI `msicenter panic-reset`.
- Same three gated D-Bus methods as the individual controls; per-step
  results like scene apply. Daemon unchanged.

### 3. Charge-limit presets + travel mode — implemented 2026-09-07

GhostDeck: 60/80/100 plus a trip-to-100% that reverts after N days.

- Battery page presets `50–60` / `70–80` / `90–100` call
  `SetBatteryThresholds` (start **and** end; not a single-end slider).
- Travel: saves the current pair in `ui.json`, writes end=100 (start
  kept), restores after 3/7/14/30 days while the UI is running, or on
  the next launch after the deadline. Restore now cancels early.
- Restore still needs the battery opt-in and Polkit. No systemd user
  timer (would prompt at an unexpected hour). No EC travel register.

### 4. Example scenes (honest names) — implemented 2026-09-07

Bundled in `data/scenes.example.json`. Not MSI Silent / Balanced / Extreme.

| Name | Settings |
|---|---|
| Quiet | `fan_mode: silent`, Cooler Boost off, Super Battery off |
| Cool | Cooler Boost on, fan `auto` |
| Battery saver | Super Battery on, fan `auto` (does **not** write eco `0xc2`) |
| Gaming lights | RGB wave/red; no power claims |

- First UI start seeds `scenes.json` only if the file is missing.
- `msicenter scene examples` and Scenes → Add examples merge by name;
  an existing scene of the same name is left untouched.
- UI copy states Quiet is fan silent only, not a shift write.

### 5. Session-start restore (opt-in) — implemented 2026-09-07

EC RAM is volatile. GhostDeck re-asserts profile + curve after boot.

- Scenes page switch, default **off**. Combo: last applied, or a named
  scene. Stored in `ui.json`.
- After the first D-Bus fetch, calls existing `applyScene`. Per-setting
  opt-in failures are reported, not fatal.
- Autostart already launches the UI; this opt-in is what re-applies
  hardware. Polkit may prompt at login.

---

## P2 — automation (still client-only)

Needs a small always-running user helper (the UI already trays) or
systemd user units. Still no new hardware writes.

### 6. AC / battery scene switch — implemented 2026-09-07

Opt-in, default off. Client-only: infers AC vs battery from
`power_supply` `status` already in the battery JSON (`Charging` /
`Full` / `Not charging` = AC, `Discharging` = battery). First sample
is recorded, not applied. A later plug/unplug applies the matching
scene via existing `applyScene`. A manual scene in between is kept
until the next edge. `(none)` skips that side. No daemon change.

### 7. Battery-level rules — implemented 2026-09-07

Opt-in, default off. Crossing below X% **while discharging** applies
the low scene; crossing above Y% **while charging** applies the high
scene. First capacity sample is recorded, not applied. Once per
crossing (must recross the threshold to fire again). `(none)` skips
that side. Client-only, existing `applyScene`.

### 8. Scene schedule — implemented 2026-09-07

Opt-in, default off. Weekday bits + start/end (overnight allowed).
First matching rule wins. Applies when a window is entered, and at
app start if already inside a window (startup-scene restore yields
in that case). Manual apply inside a window is kept until the next
window. In-process in the UI (autostart) — **no systemd user timer**,
so a background unit cannot Polkit-prompt at 07:00. Needs the app
running. Max 8 rules in `ui.json` `scene_schedule`.

---

## P3 — telemetry UX (no writes)

### 9. Temperature alert — implemented 2026-09-07

Opt-in, default off. CPU (`EcState`) stays at or above 70–100 °C for
5–60 s → red OSD. Cooldown 30–600 s between alerts. No hardware write.
Needs the UI running.

### 10. Tray tooltip / optional tray temp — implemented 2026-09-07

Tooltip is `CPU °C · RPM · CB · fan mode · bat %`. Menu status line
includes the same plus Super Battery / webcam / GPU. No second tray
icon (most Linux trays collapse extras; the single icon stays).

### 11. In-memory history (last 15–60 min) — implemented 2026-09-07

Overview sparklines of CPU °C and max-channel fan RPM. Samples ~2 s
in RAM, trimmed to 60 min. Window 15/30/60 min. Copy CSV to clipboard.
No daemon ring buffer; gone when the UI quits.

### 12. Client write log — implemented 2026-09-07

Each D-Bus write (ok or FAIL) appends one line to
`~/.config/msi-linux-center/writes.log` (last 200). Diagnostics
shows the log and Copy log. Time + title + detail; no EC addresses
or serials.

---

## Explicitly not this backlog

| GhostDeck feature | Why not |
|---|---|
| Silent/Balanced/Extreme as product modes | Needs `0xd2`; `0xc0` unrestorable |
| Custom fan curve + sweep + 150% | Phase 5 §11 |
| Power test (7 min load) | Useful later; needs a consent-gated script, not a product feature now |
| Refresh rate / HDR / brightness / touchpad / Win-lock in scenes | Not MSI EC; compositor/logind scope |
| Gaming overlay / FPS / session report | MangoHud |
| Keyboard EC brightness 0–3 | `kbd_bl` unsupported; RGB HID is the backlight |
| 149-model signed DB | One verified firmware is the contract |
| Global rebindable hotkeys | Linux is compositor-owned; keep documenting `msicenter` CLI bindings |

---

## Suggested order if we implement later

1. Cooler Boost auto-off  
2. Panic reset  
3. Example scenes + copy  
4. Charge presets / travel  
5. Session-start restore  
6. Temp alert  
7. AC/battery scene switch  

Stop after each item. Do not batch P2 automation with P1.

## Acceptance for this document

- Shift, curves, and MUX stay out.
- Each P1 item names the existing D-Bus method it calls.
- GhostDeck scenario names are not reused for shift-less recipes.
