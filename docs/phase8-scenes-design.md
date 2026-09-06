# Phase 8 — Scenes/profiles: design study

Status: CLI `scene list`/`scene apply` implemented and physically validated
on 2026-09-06; UI scene section implemented in `crates/msicenter-ui`
(`ScenesPage.qml`: scene list, reload, sequential apply with per-step
result panel) — desktop visual test pending with the rest of the UI. A
"scene" is a named set of hardware settings applied in one action. Every
individual setting already exists as a gated, physically verified write
(Phase 4 + Phase 7); Phase 8 composes them. Follows
`MSI-Linux-Center-AGENTS.md` §22 (scene concepts stay separate from Linux
power policy) and §34.

## Validation record (2026-09-06)

- `msicenter scene list` on the reference laptop: `Gaming ok`.
- With all four opt-ins enabled, `msicenter scene apply Gaming` applied
  every setting: `ok fan_mode`, `ok cooler_boost`, `ok battery_thresholds`,
  `ok rgb`; `msicenter status` confirmed fan mode `auto`, Cooler Boost
  `off`, charge start `80%`; keyboard turned red (rgb).
- After removing the opt-in override, the same apply reported all four
  settings `FAIL ... NotSupported` (gates closed).
- Battery thresholds were restored to the original 90/100 afterwards.
- Scene file location used for the test:
  `~/.config/msi-linux-center/scenes.json`.

Acceptance criteria for this document: scene model defined; storage and
application flow specified; security model (per-write gates preserved)
described; UI/CLI surface sketched; open decisions explicit.

## 1. Why scenes

Users switch whole laptop personalities ("gaming", "silent", "battery
saver"). Today that means running several `msicenter` commands; a scene
applies a named set in one action and reports per-setting results.

## 2. Scene model (draft)

```json
{
  "name": "Gaming",
  "settings": {
    "fan_mode": "auto",              // optional; values from available_fan_modes
    "cooler_boost": false,           // optional boolean
    "super_battery": false,          // optional boolean
    "battery_start": 80,             // optional, 0..99 (pair with battery_end)
    "battery_end": 100,              // optional, 1..100, > battery_start
    "rgb": { "zones": 15, "color": "ff0000" }   // optional steady color
  }
}
```

Constraints:

- All settings optional; a scene applies only what it lists (no hidden
  state).
- Values are validated against the same rules as the individual writes
  (zones bits 0-3, color RRGGBB, thresholds start<end, fan mode from the
  driver list at apply time).
- **RGB is never persisted by a scene** (no flash-save); scenes are
  non-persistent by design — a reboot returns to the flashed state.
- Scenes do not touch performance mode (deferred, §6.1), MUX, or fan
  curves.

## 3. Storage and ownership

- Scenes live in a **user-owned** file:
  `~/.config/msi-linux-center/scenes.json` (single file, list of scenes).
- The daemon never reads scene files: it only ever receives the same
  gated per-setting D-Bus calls the CLI/UI already make. Scene logic is a
  client concern; all safety remains daemon-side.
- File validation on load: schema + bounds; malformed entries are skipped
  with a warning, never guessed.

## 4. Application flow

1. Client loads and validates `scenes.json`, finds the named scene.
2. Client applies settings **sequentially** over D-Bus (same methods the
   CLI uses). Each call passes the daemon's own gates (opt-in, firmware,
   Polkit).
3. Polkit: `auth_admin_keep` caches the authorization for the session, so
   the sequence normally prompts once.
4. Result report: per-setting `applied` / `rejected (reason)`; the client
   shows refusals verbatim (e.g. an opt-in that is currently off) and
   **continues** with the next setting (no partial rollback — each write
   is independent and verified by the daemon).

## 5. Linux power policy (AGENTS §22)

A scene *may later* coordinate an MSI EC setting with a Linux power
profile (e.g. power-profiles-daemon), but the two stay separate
layers/keys (`"power_profile": "balanced"` would be a distinct optional
key, applied through the system power service, not merged into the EC
enum). Not implemented in the first scene milestone.

## 6. UI/CLI surface (sketch)

CLI:

    msicenter scene list
    msicenter scene apply NAME          # sequential gated writes + report

UI: scene section listing saved scenes with an Apply button and a small
editor (name + toggles matching the existing Controls section). The RGB
palette and zone picker from Phase 6 reuse for the scene's rgb key.

## 7. Open decisions

- Default scenes shipped with the app vs. user-created only (suggest:
  user-created; ship examples in the docs only).
- Whether `scene apply` should require a single new Polkit action
  (`org.msilinux.Center.apply-scene`) vs. reuse the per-setting actions
  (suggest: reuse — no new privilege surface; the daemon stays unchanged).
- Validation source of truth for fan-mode lists at apply time (driver
  list, per write) — resolved in favor of the daemon.

## 8. Sources

- AGENTS §22 (scene/EC/power separation), §34 (phase sequence)
- Phase 4 gate pattern and Phase 7 RGB path (docs/dbus-contract.md)
