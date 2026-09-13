<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — Linux-natives, sicherheitsgegattertes Lüfter-, Akku- und Tastatur-RGB-Management für MSI-Laptops, verifiziert auf dem Katana 17 B13VGK">
</p>

<p align="center">
  <sub>
    <a href="README.md">English</a> ·
    <a href="README.zh.md">简体中文</a> ·
    <a href="README.tr.md">Türkçe</a> ·
    <b>Deutsch</b> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.sv.md">Svenska</a> ·
    <a href="README.it.md">Italiano</a> ·
    <a href="README.pt.md">Português</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.ar.md">العربية</a> ·
    <a href="README.hi.md">हिन्दी</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#abhängigkeiten)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> Diese Datei ist eine von der Community bereitgestellte Übersetzung.
> Im Zweifelsfall gilt die [englische README](README.md).

Linux-natives, quelloffenes Hardware-Management für MSI-Laptops.
Entwickelt anhand des **MSI Katana 17 B13VGK** (Board MS-17L5, EC
`17L5EMS1.115`) als Referenzgerät. Rust-Kern, D-Bus-Daemon,
Qt/QML-Desktop-Client.

Jeder Hardware-Schreibvorgang ist firmware-gegattert,
Polkit-autorisiert, pro Funktion opt-in, wird per Rücklesen
verifiziert und erst nach physischer Verifikation auf dem
Referenzgerät aktiviert. Die Regeln stehen in
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **Hinweis zur KI-unterstützten Entwicklung:** Dieses Projekt ist
> vollständig „vibecoded“ — jeder Commit wurde von einem
> KI-Coding-Agenten geschrieben, der nach den Regeln in
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)
> arbeitete, während ein Mensch den Umfang festlegte, Änderungen
> überprüfte und jeden Hardware-Schreibvorgang vor der Ausführung
> auf echter Hardware explizit bestätigen musste. Keine Codezeile,
> kein Designdokument und kein Verifikationsprotokoll entstand ohne
> diese menschliche Kontrolle. Das ändert nichts am
> [Haftungsausschluss](#haftungsausschluss--nutzung-auf-eigenes-risiko)
> weiter unten: Nutzung auf eigenes Risiko — lesen Sie die
> Sicherheitsmechanismen, bevor Sie ein Schreib-Opt-in aktivieren.

## Live-Oberfläche

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="Systemübersicht: CPU-/GPU-Temperaturen, Akkuladung, Lüftermodus und Live-Drehzahl auf dem Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Seitenrundgang: Kühlung, Strom, Akku, Tastatur-RGB, Szenen und Diagnose">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Tastatur-RGB-Seite mit MysticLight-MS-1565-Zonenvorschau">
</p>

## Was es ist

Eine Desktop-Center-Anwendung und ein CLI-Tool, das EC-Modus-/
Lüfterstatus, Temperaturen, Drehzahlen und Akkustatus ausliest —
und, sobald aktiviert (Opt-in), einen kleinen Satz verifizierter
Schreibvorgänge anwendet: Ladeschwellen, Lüftermodus, Cooler
Boost, Super Battery, Webcam/Fn-Tasten und MysticLight-RGB.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML-Oberfläche und CLI kommunizieren über D-Bus und Polkit mit msi-daemon, der wiederum msi-ec, hwmon, die Akku-Schnittstelle und MysticLight-RGB anspricht">
</p>

## Funktionen

- **Nur-Lese-Telemetrie** — EC-Modus/Lüftermodi, CPU-/GPU-
  Temperaturen, Temperatur/Last pro Kern, Temperatur/Last pro GPU,
  Lüfterstufen und echte Drehzahl, Akkustatus und Ladeschwellen,
  Laufzeit-Fähigkeitsmeldung
- **Gegatterte, verifizierte Schreibvorgänge** — Akku-Ladeschwellen,
  Lüftermodus, Cooler Boost, Super Battery, Webcam/Webcam-Sperre,
  Fn/Win-Tastentausch
- **Tastatur-RGB** — MysticLight MS-1565 statische Farbe und
  Effekte (Atmen, Zyklus, Welle), standardmäßig nicht persistent;
  Flash-Speichern erfordert ein separates Opt-in
- **Szenen** — benannte Bündel der gegatterten Schreibvorgänge, mit
  CLI- und UI-Anwendung/Import/Export, Beispielvorlagen (Leise /
  Kühl / Akkusparen / Gaming-Beleuchtung), optionale
  Start-/Netz-Akku-/Ladestand-/Zeitplan-Automatisierung (alles
  Opt-in, alles UI-verwaltet)
- **Systemtray** — Live-Tooltip für Temperaturen/Drehzahl,
  Schnellaktionen, Tastenkürzel (Strg+Umschalt+C/B/L/P)
- **Desktop-Oberfläche** — sieben Seiten (Übersicht, Kühlung,
  Strom, Akku, Tastatur-RGB, Szenen, Diagnose) mit einer
  thermischen Hero-Karte, angehefteten Primäraktionen, einem
  Szenen-Automatisierungs-Akkordeon, Verbindungs-/Veraltet-Status
  und einem Warteschlangen-Banner für Aktionen
- **Community-Diagnose** — `msicenter report` ohne Seriennummern
  für Support-Anfragen bei den Upstream-Projekten
- **Fake-Sysroot-Fixture** — hardwarefreie Entwicklung und Tests
  über `MSI_LINUX_CENTER_SYSROOT`

## Installation

Baut Daemon, CLI und Qt-UI im Release-Modus und installiert dann
systemd, Polkit, D-Bus-Policy, Desktop-Datei und (standardmäßig)
Session-Autostart. Die mitgelieferte systemd-Unit aktiviert
standardmäßig die Opt-ins für Akku, Lüftermodus, Cooler Boost,
RGB, Webcam, Webcam-Sperre und Fn-Taste; Super Battery und
RGB-Flash-Speichern bleiben deaktiviert. Unabhängig von diesen
Standardwerten bleibt jeder Schreibvorgang im Daemon durch Polkit
gegattert, exakt firmware-abgeglichen und per Rücklesen/Rollback
verifiziert — bearbeiten Sie
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
vor der Installation, wenn Sie einen rein schreibgeschützten
Standard möchten.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` löscht `~/.config/msi-linux-center` nicht. Das Präfix
ist standardmäßig `/usr` (`PREFIX`, `SYSCONFDIR`).

### Voraussetzungen

- Rust-Toolchain (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- Linux mit den Kernelmodulen `msi-ec` und `msi_wmi_platform` für
  echte Hardware (sowohl Lese- als auch Schreibpfade degradieren
  ohne diese Module elegant)

Die genauen Systempakete und unterstützten Betriebssysteme finden
Sie unten unter [Abhängigkeiten](#abhängigkeiten).

### Aus dem Quellcode bauen

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Ausführen

Gegen die mitgelieferte Fixture (keine Hardware nötig):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

Schreibgeschützt auf dem echten Laptop:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

Führen Sie die CLI **nicht** mit sudo aus. Privilegierte
Schreibvorgänge werden ausschließlich vom Daemon nach
Polkit-Autorisierung durchgeführt.

## Schreibbefehle (gegattert)

Jeder Befehl erfordert, dass der Daemon mit dem passenden Opt-in
läuft (`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) und schließt eine
Polkit-Abfrage ab:

```bash
msicenter battery-thresholds START END      # z. B. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # nicht persistent
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # persistentes Flash-Speichern (separates Opt-in)
msicenter panic-reset                       # Cooler Boost aus, Super Battery aus, Lüfter auto
msicenter scene list|examples|apply NAME
```

Ist das Opt-in deaktiviert, verweigert der Daemon mit
`NotSupported`. Der genaue Unterstützungsumfang, die Gatter und
die physischen Verifikationsprotokolle stehen in
[`docs/dbus-contract.md`](docs/dbus-contract.md) und den
`docs/phase4-*-validation.md`-Dateien.

## Sicherheitsmodell

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Sechs Schreibgatter: Firmware-Abgleich, Opt-in, Polkit, Rücklesen, physische Verifikation auf dem Katana 17 B13VGK und keine undokumentierten Register">
</p>

1. **Firmware-Gatter** — Schreibvorgänge laufen nur, wenn die
   EC-Firmware des Geräts exakt mit einer physisch verifizierten
   Firmware-Zeichenkette übereinstimmt
2. **Opt-in-Gatter** — jede Schreibfamilie hängt an ihrer eigenen
   Daemon-Umgebungsvariable; die mitgelieferte systemd-Unit
   aktiviert standardmäßig Akku, Lüftermodus, Cooler Boost, RGB,
   Webcam, Webcam-Sperre und Fn-Taste (Super Battery und
   RGB-Flash-Speichern bleiben deaktiviert)
3. **Polkit-Gatter** — jede D-Bus-Schreibmethode ist einer
   Polkit-Aktion zugeordnet
4. **Rücklese-Verifikation** — EC- und Akku-Schreibvorgänge werden
   zurückgelesen und verifiziert; fehlgeschlagene Schreibvorgänge
   werden zurückgerollt
5. **Physische Verifikation** — ein Schreibpfad wird erst
   ausgeliefert, nachdem er auf dem Referenzlaptop getestet und in
   `docs/` dokumentiert wurde
6. **Kein Raten** — undokumentierte Register werden nie
   beschrieben; die Herkunft jeder Hardwarefunktion ist im
   Geräteprofil dokumentiert

## Unterstützte Geräte

| Gerät | Status |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | verifiziertes Referenzgerät |
| Andere MSI-Laptops mit `msi-ec` | nur Lese-Telemetrie; Schreibvorgänge durch exakten Firmware-Abgleich gegattert |
| Nicht übereinstimmende Modelle | nur Lesezugriff + Diagnosebericht; Community-Support über `msicenter report` |

<details>
<summary>Phasenstatus</summary>

| Phase | Umfang | Status |
|---|---|---|
| 0 | schreibgeschützte Hardware-Erkundung | abgeschlossen |
| 1–2 | schreibgeschützter Kern, Gerätedatenbank, Laufzeit-Fähigkeiten, Fixture | abgeschlossen |
| 3 | D-Bus-Daemon, systemd-Unit, D-Bus-Policy, Polkit-Aktionen | abgeschlossen |
| 4 | gegatterte semantische Schreibvorgänge (Akkuschwellen, Lüftermodus, Cooler Boost, Super Battery) | abgeschlossen — physisch verifiziert am 05.09.2026 |
| 5 | benutzerdefinierte Lüfterkurven | [Designstudie](docs/phase5-fan-curve-design.md) — keine Schreibvorgänge vor dem §11-Experiment |
| 6 | Qt/QML-Desktop-Oberfläche | abgeschlossen — [Design](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` physisch verifiziert; Effektmodi implementiert; Flash-Speichern implementiert, physischer Test steht aus |
| 8 | Szenen | abgeschlossen — CLI + UI validiert |
| 9 | Community-Diagnose | abgeschlossen — [Design](docs/phase9-diagnostics.md) |
| 10 | MUX | nur Forschung — [Notizen](docs/deferred-features-research.md) |

</details>

## Dokumentation

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — D-Bus-API-Vertrag
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — MysticLight-Protokoll
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — Reverse-Engineering-Inventar
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — Sicherheitsregeln für Mitwirkende und Agenten
- [Projekt-Wiki](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — Installation, Sicherheitsmodell, D-Bus-API und FAQ zum Durchklicken

## Abhängigkeiten

**Unterstützte Betriebssysteme** — Nur Linux. Entwickelt und
getestet auf Arch Linux und Ubuntu (CI läuft auf `ubuntu-latest`);
jede Distribution mit `systemd`, Polkit, D-Bus, Qt 6 und einer
aktuellen Rust-Toolchain sollte funktionieren. Die Kernelmodule
`msi-ec` und `msi_wmi_platform` sind für echte
Hardware-Telemetrie/-Schreibvorgänge erforderlich — das Projekt
baut und läuft aber auch ohne sie schreibgeschützt über die
Fixture.

**Erforderliche Systempakete**

| Paket | Zweck |
|---|---|
| Rust-Toolchain ≥ 1.75 (`cargo`) | baut alle Rust-Crates |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | Desktop-Oberfläche |
| CMake ≥ 3.21 | Build der Qt-Oberfläche |
| `pkg-config` | findet `libusb-1.0` zur Build-Zeit |
| `libusb-1.0-0-dev` (Dev-Header) | RGB-HID-Backend, statisch zur Build-Zeit gelinkt |
| `libudev-dev` | Hardware-/Geräteerkennung |
| `systemd`, `polkit`, `dbus` (Laufzeit) | Daemon-Dienst, Privilegien-Gatter, IPC |
| `libusb-1.0-0` (Laufzeit) | Laufzeitabhängigkeit des RGB-HID-Backends |

```bash
# Debian/Ubuntu (wie in der CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**Wichtige Rust-Crates** — `zbus` (D-Bus), `serde`/`serde_json`
(Daten + Geräteprofile), `hidapi` (statisch gelinktes
`linux-static-libusb`-Backend für MysticLight-RGB — siehe
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi),
falls ein distributionseigenes `hidapi`-Paket Linkerfehler
verursacht). Vollständiger Abhängigkeitsgraph in `Cargo.lock` und
den `Cargo.toml`-Dateien der einzelnen Crates.

**Verwendete Kernelmodule** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(EC-Semantikstatus, Lüftermodi, Cooler Boost, Super Battery,
Webcam/Fn-Taste), `msi_wmi_platform`/hwmon (echte Lüfterdrehzahl),
Linux `power_supply` (Akkustatus und Ladeschwellen).

**Während der Entwicklung referenzierte Projekte** — nur als
Recherche-/Referenzmaterial; nichts davon wird eingebunden oder
verlinkt, und jeder Schreibpfad wurde vor der Auslieferung
unabhängig verifiziert (siehe
[Sicherheitsmodell](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| Projekt | Verwendet für |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSI-Modell-/Firmware-Wissen, EC-/Register-Recherche, Lüfterkurven, Verifikationsmethodik |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux-MSI-EC-/sysfs-Semantik, Modi, Cooler Boost, Temperaturen, Lüfterstufen und unterstützte Modelle |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | Vergleichendes Linux-MSI-Feature-/UX-Verhalten |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | Privilegientrennung, Polkit-Konzepte, Lüftersteuerung, Simulation und Wiederherstellung |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana-Mystic-Light-USB/HID-Protokoll und 4-Zonen-RGB-Recherche |
| [Linux-Kernel](https://github.com/torvalds/linux) | wichtigste Implementierungsreferenz für hwmon, power_supply, WMI, ACPI, HID, DRM und Plattformtreiber |

## Haftungsausschluss — Nutzung auf eigenes Risiko

Diese Software steuert Laptop-Hardware über den eingebetteten
Controller (EC), Akku-Ladeschnittstellen und einen USB-HID-RGB-
Controller. Fehlerhafte Schreibvorgänge auf diese Schnittstellen
können Instabilität, thermische Probleme, verringerte Akkulaufzeit,
Datenverlust oder Hardware-/Firmwareschäden verursachen.

**Dieses Projekt wird „wie besehen“ ohne jegliche ausdrückliche
oder stillschweigende Garantie bereitgestellt. Die Autoren und
Mitwirkenden übernehmen keinerlei Haftung für Schäden, Datenverlust
oder Fehlfunktionen, die aus der Nutzung dieser Software
entstehen — einschließlich Schäden an Ihrem Laptop, Akku, Ihrer
Tastatur oder anderer Hardware.**

Die im Projekt eingebauten Schutzmaßnahmen (Firmware-Gatter,
funktionsbezogene Opt-ins, Polkit-Autorisierung, Rücklese-
Verifikation, physische Verifikation am Referenzgerät) verringern
das Risiko, beseitigen es aber nicht. Es handelt sich um technische
Maßnahmen nach bestem Wissen und Gewissen, nicht um Garantien.

- Akku-Schwellen-, Lüftermodus-, Cooler-Boost-, RGB-, Webcam-,
  Webcam-Sperr- und Fn-Tasten-Schreibvorgänge sind in der
  installierten systemd-Unit **standardmäßig aktiviert** (Super
  Battery und RGB-Flash-Speichern bleiben deaktiviert); installieren
  Sie sie nur, wenn Sie verstehen, was sie tun, und bearbeiten Sie
  die Unit-Datei vor der Installation, wenn Sie einen rein
  schreibgeschützten Standard möchten
- Das Verhalten ist ausschließlich auf dem **MSI Katana 17 B13VGK**
  (EC `17L5EMS1.115`) physisch verifiziert; andere Modelle sind
  gegattert, aber nicht verifiziert
- Verwenden Sie diese Software nicht auf einem Laptop, dessen
  Beschädigung Sie sich nicht leisten können, und aktivieren Sie
  niemals Schreib-Opt-ins auf kritischer Hardware
- Wenn Sie unsicher sind, verwenden Sie ausschließlich die
  schreibgeschützten Telemetriefunktionen

**Seien Sie vorsichtig. Sie sind allein verantwortlich für alle
Folgen der Nutzung dieser Software.**

## Mitwirken

Lesen Sie zuerst
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).
Hardware-Schreibpfade erfordern Herkunftsnachweis, Gatter und
physische Verifikationsprotokolle — Pull Requests, die dies
auslassen, werden nicht gemerged.

## Lizenz

Doppelt lizenziert unter [MIT](LICENSE-MIT) oder
[Apache-2.0](LICENSE-APACHE), nach Ihrer Wahl.
