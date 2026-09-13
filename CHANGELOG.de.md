<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <b>Deutsch</b> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <a href="CHANGELOG.sv.md">Svenska</a> ·
    <a href="CHANGELOG.it.md">Italiano</a> ·
    <a href="CHANGELOG.pt.md">Português</a> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *Diese Datei ist eine von der Community bereitgestellte Übersetzung. Bei Abweichungen oder Widersprüchen ist die englische `CHANGELOG.md` maßgeblich.*

# Änderungsprotokoll

Diese Datei dokumentiert alle wesentlichen Änderungen an diesem Projekt. Das Format orientiert sich lose an [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), ist jedoch nach Entwicklungsphasen statt nach strikt semantischen Versionssprüngen gruppiert, da dieses Projekt als fortlaufender Snapshot ausgeliefert und gegen ein einzelnes Referenzgerät (MSI Katana 17 B13VGK, Firmware `17L5EMS1.115`) validiert wird.

## [Unreleased]

### Hinzugefügt
- Community-Übersetzungen von `README.md` in 12 Sprachen (Chinesisch, Türkisch, Deutsch, Französisch, Schwedisch, Italienisch, Portugiesisch, Spanisch, Arabisch, Hindi, Japanisch, Koreanisch) mit Sprachumschalter.
- Übersetzte GitHub-Wiki-Seiten und dieses Änderungsprotokoll in denselben 12 Sprachen.
- Abschnitt `Dependencies` in `README.md`, der benötigte Systempakete, unterstützte Betriebssysteme, Kernel-Module und Upstream-Referenzprojekte dokumentiert.
- Hinweis zur Offenlegung von AI-assisted development („vibecoded“) in `README.md`.
- Rust-/Platform-/Wiki-Badges und eine umstrukturierte README-Anordnung.

### Geändert
- Schreibvorgänge für battery threshold, fan-mode, Cooler Boost, RGB, webcam, webcam block und fn-key sind in der installierten systemd unit jetzt standardmäßig **aktiviert** (Super Battery und nichtflüchtiges RGB save bleiben opt-out).

### Behoben
- `hidapi` statisch gelinkt (`linux-static-libusb` backend), um CI-Fehlschläge und distributionsversionsabhängige Linker-Fehler zu beheben, wenn das Systempaket `hidapi` inkompatibel ist.
- Der CI-Workflow installiert `libhidapi-dev`, damit das `hidapi`-Crate sauber baut.
- Die Polkit-Ablehnungsmeldung wurde korrigiert und die Abdeckung für den Rollback-Fehlerpfad ergänzt.

## [0.2.0] — 2026-09-06

### Hinzugefügt
- **Phase 9 — Community-Diagnostik**: Befehl `msicenter report`, der ein teilbares Diagnosepaket ohne Seriennummern erzeugt.
- **Phase 8 — Szenen**: benannte Bündel abgesicherter Schreibvorgänge, `scene list|examples|apply`-CLI-Befehle, Beispiel-Szenen (quiet / cool / battery saver / gaming rgb) und eine Scenes-Seite in der Desktop-UI mit optionalen Automatisierungs-Triggern (Boot, AC/Batterie-Wechsel, Batteriestand, Zeitplan).
- **Phase 7 — RGB (MysticLight MS-1565)**: Nur-Lese-HID-Controller-Probe, Protokollpaket-Builder mit Unit-Tests, abgesicherte nicht persistente `SetRgbColor`- und Effekt-Schreibvorgänge (breathing, rainbow, wave), abgesichertes nichtflüchtiges `rgb-save` sowie eine Keyboard-RGB-Seite in der Desktop-UI.
- **Phase 6 — Qt/QML desktop UI**: vollständiger sieben Seiten umfassender Desktop-Client (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes, Diagnostics) mit Material-Stil-Neugestaltung, Seitenleisten-Navigation, hervorgehobener Thermalkarte, Detailansichten pro CPU-Kern und pro GPU, angehefteten Schnellaktionen, einklappbaren Automatisierungsmenüs, Verbindungs-/Aktualisierungsstatus und einer Toast-Leiste für ausstehende Aktionen.
- Durchgängige Berichterstattung zu Temperatur/Last pro CPU-Kern und GPU-Details (core → daemon → UI).
- System-Tray-Symbol mit Live-Temperatur-/RPM-Tooltip, Schnellaktionen und Tastenkürzeln (Ctrl+Shift+C/B/L/P).

### Geändert
- Die Prüfungen der Schreibsperren über die Schreib-Handler des Daemons hinweg vereinheitlicht und Verfügbarkeitstests ergänzt.
- Die feste Versionsbindung von `zbus` gelockert.

## [0.1.0] — 2026-09-05

### Hinzugefügt
- **Phase 0–2 — Nur-Lese-Grundlage**: Hardware-Erkennung, ein Nur-Lese-Rust-Kern, Gerätedatenbank (`msi-device-db`), Laufzeit-Fähigkeitsberichte und eine fake-sysroot fixture für Entwicklung und Tests ohne Hardware (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: `msi-daemon`-systemd-Dienst, D-Bus policy und Polkit actions, die jede privilegierte Methode absichern.
- **Phase 4 — Sichere, abgesicherte Schreibvorgänge**: Batterie-Ladegrenze, Lüftermodus (auto/silent/advanced), Cooler Boost und Super-Battery-Schreibpfade; jeder davon geschützt durch Firmware-Match-Sperre, funktionsspezifische Opt-in-Umgebungsvariable, Polkit-Autorisierung sowie Read-back-Verifikation mit Rollback bei Fehlern. Alle vier Schreibpfade wurden am 2026-09-05 auf dem Referenzgerät MSI Katana 17 B13VGK physisch verifiziert.
- `msicenter-cli`-Kommandozeilenclient (`status`, `capabilities` und die abgesicherten Schreib-Subcommands).
- `MSI-Linux-Center-AGENTS.md`-Sicherheitsregeln für Mitwirkende und KI-Coding-Agents.
- Design-Studien für aufgeschobene Features: custom fan curves (Phase 5, nur Design bis zu einem zustimmungsgesteuerten EC-table-Rollback-Experiment) und GPU-MUX-switching (nur Forschung).

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
