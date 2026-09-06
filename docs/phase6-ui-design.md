# Phase 6 — Qt/QML desktop UI: design study

Status: implemented in `crates/msicenter-ui` (C++17 + QtDBus client, QML
views). Milestone 1 (read-only dashboard) and milestone 2 (write controls
for the four Phase-4 features) run against the live daemon, verified
2026-09-05; write replies/refusals are shown verbatim. UI polish pass
completed: forced Material style (`QQuickStyle::setStyle` — Qt 6.8+ no
longer auto-selects from imports), warm Material Design palette
(amber `#E2A35B` on warm dark surfaces), sidebar + StackLayout
navigation (Overview/Power & Fans/Battery/Keyboard RGB/Scenes/
Diagnostics), RGB color picker (HSL sliders + hex + live preview) and RGB
effect picker (steady/breathing/cycle/wave via daemon
`SetRgbPresetEffect`), system tray with hide-to-close, autostart
descriptor. Desktop visual test of write controls pending (user session).

Acceptance criteria for this document: (1) environment facts are recorded;
(2) the D-Bus surface is mapped to concrete UI screens and actions;
(3) the "UI never requires root" rule is designed in; (4) data-update and
write-authorization flows are specified; (5) open decisions are explicit.

## 1. Environment facts (2026-09-05)

- Qt 6.11.2 with `Qt6Core` and `Qt6Quick` installed; `qmake6` and `cmake` available.
- System D-Bus service `org.msilinux.Center` runs as root with the daemon; the
  user session has a working user bus.
- Current client surface (all unprivileged): CLI talks to the system bus
  (`Connection::system()`), Polkit `auth_admin_keep` prompts on writes.

## 2. Architectural principle

The UI is a **pure D-Bus client**. Every hardware read and write stays in the
daemon (root, capability-dropped, Polkit-gated). The GUI:

- must never require root (§5.6);
- must not read `/sys` directly (all values come through the service);
- triggers writes through the same gated methods as the CLI, so Polkit,
  firmware, and opt-in gates are enforced exactly once, in the daemon.

## 3. UI technology decision

AGENTS §1 fixes Qt 6 / Qt Quick / QML as the UI stack. The open question is the
application language:

| Option | Fit | Trade-offs |
|---|---|---|
| A. C++17 + QtDBus, QML front-end | most mature Qt path; QtDBus is built-in, typed, async | two languages in repo (Rust service + C++ UI); C++ build files |
| B. Rust UI (qmetaobject / cxx-qt) + QML | keeps one language | immature binding layers, harder D-Bus/QML integration, slower iteration |
| C. QML-only via QML's `QtDBus` (org.freedesktop.DBus JS) | prototype speed | weak typing, error handling; fine for a mock, not the real client |

**Recommended: A** (C++17 client, QML views, QtDBus). The daemon owns all
safety logic; the UI client stays thin, so C++ complexity is bounded. A tiny
`msicenter-gui` binary connects to the system bus with a typed QDBusInterface
wrapper per interface (`Device`, `Sensors`), exposing Qt signals/properties to
QML via a small QObject controller layer.

## 4. Mapping the existing service to screens

| Screen / control | D-Bus surface | Notes |
|---|---|---|
| Device identity + support tier | `Device.Identity`, `.MatchedProfile`, `.SupportTier` (JSON) | read-only; no serial/UUID (privacy, §31) |
| Telemetry: temps, fan levels, RPM | `Sensors.EcState`, `.FanRpm` (JSON) | poll `Refresh()` ~2 s or on `StateChanged` |
| Battery: capacity, thresholds, Super Battery | `Sensors.Battery`, `Device.SetBatteryThresholds`, `SetSuperBattery` | thresholds need start<end validation in UI too, as UX pre-check |
| Fan: mode + Cooler Boost | `Sensors.EcState`, `Device.SetFanMode`, `SetCoolerBoost` | modes from `available_fan_modes` |
| Performance profile | — | **hidden/disabled**: deferred (§6.1 note; no safe rollback) |
| RGB lighting | — | Phase 7; placeholder page state "not yet supported" |
| Scenes/profiles | — | Phase 8; placeholder |

Every write control is disabled unless: the daemon reports the feature as
readable, the support tier is `verified`, and the user has not disabled the
feature. The UI must surface the daemon's `NotSupported` reason verbatim when a
write is refused (e.g. opt-in disabled, firmware mismatch).

## 5. Typed D-Bus vs JSON properties

Today the daemon exposes JSON-encoded `s` properties (a deliberate Phase 3/4
size trade-off, see the `ponytail` comment in `msi-dbus`). For a QML client,
typed D-Bus values are preferable but not blocking:

- Phase 6a (first UI): keep JSON properties; parse in the C++ client
  (QJsonDocument) — zero service changes, fastest path.
- Phase 6b: add typed property/method variants under the same
  `org.msilinux.Center1` interfaces (compatible additions are allowed by the
  contract) and switch the UI to them; drop JSON once no client needs it.

## 6. Data update flow

- `Device.Refresh()` returns nothing; `StateChanged` signals fresh data.
- The client keeps a small state cache: after each `Refresh` it re-reads the
  properties it displays (batch read via `org.freedesktop.DBus.Properties.GetAll`).
- Telemetry pages poll on a QTimer (1–2 s) and additionally refresh on demand;
  a daemon-side push loop is out of scope (the daemon stays passive).

## 7. Write authorization UX

- Client calls e.g. `SetFanMode("silent")`; the daemon runs Polkit
  `CheckAuthorization` and the desktop environment shows its standard
  `auth_admin_keep` prompt (works because the UI runs in the active session).
- The UI must handle `org.freedesktop.DBus.Error.AccessDenied` /
  `NotSupported` / `InvalidArgs` distinctly and show the daemon's message.
- No password handling, no root escalation, no `pkexec` in the UI.

## 8. Runtime layout (skeleton scope)

```
crates/msicenter-ui/            # C++/QML client (own build: cmake + qmake6)
  qml/                          # views: Main, Status, Fans, Battery, Settings
  src/                          # QDBus wrapper + controller (C++17)
data/                           # later: .desktop file, icon, autostart
```

First milestone = **read-only dashboard** (identity, telemetry, battery, fan
state) against the live daemon, no write controls yet. Second milestone adds
the four verified write controls with the gate-aware enable/disable logic.

## 9. Open decisions

- C++ vs Rust UI shell (recommendation above: C++17; confirm before scaffolding).
- Tray icon + autostart in milestone 1 or 2.
- Whether Phase 6b (typed D-Bus) happens before or after RGB/Phase 7 work.
- Localization language baseline (project README/AGENTS are English; UI strings
  to be confirmed with the owner).

## 10. Sources

- `MSI-Linux-Center-AGENTS.md` §1 (mission/UI), §5.6 (no-root GUI), §31
  (privacy), §34 (Phase 6)
- `docs/dbus-contract.md` (Center1 surface, versioning, write gating)
- Local environment check: Qt 6.11.2, qmake6, cmake, active user bus
