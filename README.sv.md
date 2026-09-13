<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — Linux-nativ, säkerhetsspärrad hantering av fläktar, batteri och tangentbords-RGB för MSI-laptops, verifierad på Katana 17 B13VGK">
</p>

<p align="center">
  <sub>
    <a href="README.md">English</a> ·
    <a href="README.zh.md">简体中文</a> ·
    <a href="README.tr.md">Türkçe</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.fr.md">Français</a> ·
    <b>Svenska</b> ·
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
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#beroenden)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> Den här filen är en community-översättning. Vid avvikelser gäller
> den [engelska README](README.md).

Linux-nativ, öppen källkod för hårdvaruhantering på MSI-laptops.
Utvecklad mot **MSI Katana 17 B13VGK** (kort MS-17L5, EC
`17L5EMS1.115`) som referensenhet. Rust-kärna, D-Bus-demon,
Qt/QML-skrivbordsklient.

Varje hårdvaruskrivning är spärrad mot firmware, Polkit-
auktoriserad, opt-in per funktion, verifierad genom återläsning och
aktiveras endast efter fysisk verifiering på referensenheten.
Reglerna finns i
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **Meddelande om AI-assisterad utveckling:** det här projektet är
> helt "vibecodat" — varje commit skrevs av en AI-kodningsagent som
> följde reglerna i
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md), medan
> en människa styrde omfattningen, granskade ändringarna och
> spärrade varje hårdvaruskrivning bakom ett uttryckligt godkännande
> innan den kördes på riktig hårdvara. Ingen kodrad, inget
> designdokument och ingen fysisk verifieringspost skapades utan
> den här mänskliga granskningen. Det ändrar inget i
> [ansvarsfriskrivningen](#ansvarsfriskrivning--används-på-egen-risk)
> nedan: används på egen risk, läs säkerhetsspärrarna innan du
> aktiverar något skriv-opt-in.

## Gränssnittet i praktiken

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="Systemöversikt: CPU-/GPU-temperaturer, batteriladdning, fläktläge och live-RPM på Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Sidrundtur: Kylning, Ström, Batteri, Tangentbords-RGB, Scener och Diagnostik">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Tangentbords-RGB-sidan med zonförhandsvisning för MysticLight MS-1565">
</p>

## Vad det är

En skrivbords-Center-app och ett CLI-verktyg som läser EC-läge/
fläktstatus, temperaturer, RPM och batteristatus — och, när du
aktiverar det (opt-in), tillämpar en liten uppsättning verifierade
skrivningar: laddningströsklar, fläktläge, Cooler Boost, Super
Battery, webbkamera/Fn-tangenter och MysticLight-RGB.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML-gränssnittet och CLI:t pratar via D-Bus och Polkit med msi-daemon, som i sin tur når msi-ec, hwmon, batterigränssnittet och MysticLight-RGB">
</p>

## Funktioner

- **Skrivskyddad telemetri** — EC-läge/fläktlägen, CPU-/GPU-
  temperaturer, temperatur/belastning per kärna, temperatur/
  belastning per GPU, fläktnivåer och verklig RPM, batteristatus
  och laddningströsklar, rapportering av körtidskapacitet
- **Spärrade, verifierade skrivningar** — batteriladdningströsklar,
  fläktläge, Cooler Boost, Super Battery, webbkamera/
  webbkameraspärr, Fn/Win-tangentbyte
- **Tangentbords-RGB** — MysticLight MS-1565 fast färg och effekter
  (andning, cykel, våg), ej beständigt som standard;
  flash-sparande kräver ett separat opt-in
- **Scener** — namngivna buntar av spärrade skrivningar, med
  CLI- och UI-tillämpning/import/export, startexempel (Tyst / Sval
  / Batterisparläge / Spelbelysning), valfri automatisering vid
  start/nät-batteri/batterinivå/schema (allt opt-in, allt hanterat
  av UI:t)
- **Systemfält** — live-tooltip för temperatur/RPM, snabbåtgärder,
  tangentbordsgenvägar (Ctrl+Shift+C/B/L/P)
- **Skrivbordsgränssnitt** — sju sidor (Översikt, Kylning, Ström,
  Batteri, Tangentbords-RGB, Scener, Diagnostik) med ett termiskt
  hjältekort, fastnålade primära åtgärder, en dragspelsmeny för
  scenautomatisering, anslutnings-/inaktuell-status och en banner
  för köade åtgärder
- **Community-diagnostik** — `msicenter report` utan serienummer
  för supportförfrågningar uppströms
- **Fejk-sysroot-fixture** — hårdvarufri utveckling och testning
  via `MSI_LINUX_CENTER_SYSROOT`

## Installation

Bygger release-versionen av demonen, CLI:t och Qt-gränssnittet, och
installerar sedan systemd, Polkit, D-Bus-policy, desktop-fil och
(som standard) automatisk sessionsstart. Den medföljande
systemd-enheten aktiverar som standard opt-in för batteri,
fläktläge, cooler-boost, RGB, webbkamera, webbkameraspärr och
fn-tangent; Super Battery och RGB-flash-sparande förblir
avstängda. Oavsett dessa standardvärden förblir varje skrivning
spärrad av Polkit i demonen, exakt firmware-matchad och verifierad
genom återläsning/återställning — redigera
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
före installation om du vill ha ett helt skrivskyddat standardläge.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` tar inte bort `~/.config/msi-linux-center`. Prefixet är
`/usr` som standard (`PREFIX`, `SYSCONFDIR`).

### Krav

- Rust-verktygskedja (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- Linux med kärnmodulerna `msi-ec` och `msi_wmi_platform` för
  riktig hårdvara (både läs- och skrivvägar degraderar snyggt utan
  dem)

Se [Beroenden](#beroenden) nedan för exakta systempaket och
operativsystem som stöds.

### Bygga från källkod

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Köra

Mot den medföljande fixturen (ingen hårdvara behövs):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

Skrivskyddat på den riktiga laptopen:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

Kör **inte** CLI:t med sudo. Privilegierade skrivningar utförs
enbart av demonen efter Polkit-auktorisering.

## Skrivkommandon (spärrade)

Varje kommando kräver att demonen körs med matchande opt-in
(`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) och slutför en
Polkit-fråga:

```bash
msicenter battery-thresholds START END      # t.ex. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # ej beständigt
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # beständigt flash-sparande (separat opt-in)
msicenter panic-reset                       # Cooler Boost av, Super Battery av, fläkt auto
msicenter scene list|examples|apply NAME
```

Med opt-in avstängt vägrar demonen med `NotSupported`. Exakt
supportomfattning, spärrar och fysiska verifieringsposter finns i
[`docs/dbus-contract.md`](docs/dbus-contract.md) och filerna
`docs/phase4-*-validation.md`.

## Säkerhetsmodell

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Sex skrivspärrar: firmware-matchning, opt-in, Polkit, återläsning, fysisk verifiering på Katana 17 B13VGK, och inga odokumenterade register">
</p>

1. **Firmware-spärr** — skrivningar körs endast när enhetens
   EC-firmware exakt matchar en fysiskt verifierad
   firmware-sträng
2. **Opt-in-spärr** — varje skrivfamilj ligger bakom sin egen
   demon-miljövariabel; den medföljande systemd-enheten aktiverar
   som standard batteri, fläktläge, cooler-boost, RGB, webbkamera,
   webbkameraspärr och fn-tangent (Super Battery och
   RGB-flash-sparande förblir avstängda)
3. **Polkit-spärr** — varje D-Bus-skrivmetod mappas till en
   Polkit-åtgärd
4. **Återläsningsverifiering** — EC- och batteriskrivningar läses
   tillbaka och verifieras; misslyckade skrivningar återställs
5. **Fysisk verifiering** — en skrivväg skickas ut först efter att
   den har testats på referenslaptopen och dokumenterats i
   `docs/`
6. **Inga gissningar** — odokumenterade register skrivs aldrig;
   ursprunget för varje hårdvarufunktion är dokumenterat i
   enhetsprofilen

## Enheter som stöds

| Enhet | Status |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | verifierad referensenhet |
| Andra MSI-laptops med `msi-ec` | endast skrivskyddad telemetri; skrivningar spärrade av exakt firmware-matchning |
| Ej matchade modeller | endast skrivskyddat + diagnostikrapport; community-support via `msicenter report` |

<details>
<summary>Fasstatus</summary>

| Fas | Omfattning | Status |
|---|---|---|
| 0 | skrivskyddad hårdvaruspaning | klar |
| 1–2 | skrivskyddad kärna, enhetsdatabas, körtidskapacitet, fixture | klar |
| 3 | D-Bus-demon, systemd-enhet, D-Bus-policy, Polkit-åtgärder | klar |
| 4 | spärrade semantiska skrivningar (batteritrösklar, fläktläge, Cooler Boost, Super Battery) | klar — fysiskt verifierad 2026-09-05 |
| 5 | anpassade fläktkurvor | [designstudie](docs/phase5-fan-curve-design.md) — inga skrivningar förrän §11-experimentet är klart |
| 6 | Qt/QML-skrivbordsgränssnitt | klar — [design](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` fysiskt verifierad; effektlägen implementerade; flash-sparande implementerat, fysiskt test återstår |
| 8 | scener | klar — CLI + UI validerade |
| 9 | community-diagnostik | klar — [design](docs/phase9-diagnostics.md) |
| 10 | MUX | endast forskning — [anteckningar](docs/deferred-features-research.md) |

</details>

## Dokumentation

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — D-Bus API-kontrakt
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — MysticLight-protokoll
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — inventering av reverse engineering
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — säkerhetsregler för bidragsgivare och agenter
- [Projektets wiki](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — installation, säkerhetsmodell, D-Bus API och FAQ i bläddringsbar form

## Beroenden

**Operativsystem som stöds** — Endast Linux. Utvecklad och testad
på Arch Linux och Ubuntu (CI körs på `ubuntu-latest`); vilken
distribution som helst med `systemd`, Polkit, D-Bus, Qt 6 och en
aktuell Rust-verktygskedja bör fungera. Kärnmodulerna `msi-ec` och
`msi_wmi_platform` krävs för telemetri/skrivning på riktig
hårdvara — projektet bygger och körs ändå skrivskyddat via
fixturen utan dem.

**Systempaket som krävs**

| Paket | Syfte |
|---|---|
| Rust-verktygskedja ≥ 1.75 (`cargo`) | bygger alla Rust-crates |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | skrivbordsgränssnitt |
| CMake ≥ 3.21 | bygge av Qt-gränssnittet |
| `pkg-config` | hittar `libusb-1.0` vid byggtid |
| `libusb-1.0-0-dev` (utvecklingsheaders) | RGB HID-backend, statiskt länkad vid byggtid |
| `libudev-dev` | hårdvaru-/enhetsräkning |
| `systemd`, `polkit`, `dbus` (körtid) | demontjänst, behörighetsspärr, IPC |
| `libusb-1.0-0` (körtid) | körtidsberoende för RGB HID-backend |

```bash
# Debian/Ubuntu (samma som CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**Viktiga Rust-crates** — `zbus` (D-Bus), `serde`/`serde_json`
(data + enhetsprofiler), `hidapi` (statiskt länkad
`linux-static-libusb`-backend för MysticLight-RGB — se
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
om distributionens eget `hidapi`-paket någonsin orsakar
länkfel). Fullständig beroendegraf i `Cargo.lock` och varje
crates `Cargo.toml`.

**Kärnmoduler som används** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(EC-semantiskt tillstånd, fläktlägen, Cooler Boost, Super Battery,
webbkamera/Fn-tangent), `msi_wmi_platform`/hwmon (verklig
fläkt-RPM), Linux `power_supply` (batteristatus och
laddningströsklar).

**Projekt som använts som referens under utvecklingen** — endast
forsknings-/referensmaterial; inget av detta är inbäddat eller
länkat, och varje skrivväg verifierades oberoende innan den
lanserades (se
[säkerhetsmodellen](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| Projekt | Använt för |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSI-modell-/firmwarekunskap, EC-/registerforskning, fläktkurvor, verifieringsmetodik |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux MSI EC-/sysfs-semantik, lägen, Cooler Boost, temperaturer, fläktnivåer och modeller som stöds |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | jämförande MSI-funktions-/UX-beteende under Linux |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | behörighetsseparation, Polkit-koncept, fläktstyrning, simulering och återställning |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana Mystic Light USB/HID-protokoll och forskning om 4-zons RGB |
| [Linux-kärnan](https://github.com/torvalds/linux) | högst prioriterade implementeringsreferens för hwmon, power_supply, WMI, ACPI, HID, DRM och plattformsdrivrutiner |

## Ansvarsfriskrivning — används på egen risk

Den här programvaran styr laptop-hårdvara via den inbyggda
styrenheten (EC), batteriladdningsgränssnitt och en USB HID
RGB-styrenhet. Felaktiga skrivningar till dessa gränssnitt kan
orsaka instabilitet, termiska problem, minskad batteritid,
dataförlust eller hårdvaru-/firmwareskador.

**Det här projektet tillhandahålls "i befintligt skick", utan
någon som helst uttrycklig eller underförstådd garanti. Författarna
och bidragsgivarna tar inget som helst ansvar för skador,
dataförlust eller felfunktion som uppstår från användningen av den
här programvaran — inklusive skador på din laptop, batteri,
tangentbord eller annan hårdvara.**

De inbyggda skyddsåtgärderna i projektet (firmware-spärr, opt-in
per funktion, Polkit-auktorisering, återläsningsverifiering, fysisk
verifiering på referensenheten) minskar risken men eliminerar den
inte. De är tekniska åtgärder gjorda efter bästa förmåga, inte
garantier.

- Skrivningar av batterinivåer, fläktläge, Cooler Boost, RGB,
  webbkamera, webbkameraspärr och Fn-tangent är **aktiverade som
  standard** i den installerade systemd-enheten (Super Battery och
  RGB-flash-sparande förblir avstängda); installera dem endast om
  du förstår vad de gör, och redigera enhetsfilen före
  installation om du vill ha ett helt skrivskyddat standardläge
- Beteendet är fysiskt verifierat endast på **MSI Katana 17
  B13VGK** (EC `17L5EMS1.115`); andra modeller är spärrade men
  overifierade
- Använd inte den här programvaran på en laptop du inte har råd
  att skada, och aktivera aldrig skriv-opt-ins på kritisk hårdvara
- Om du är osäker, använd endast de skrivskyddade
  telemetrifunktionerna

**Var försiktig. Du är ensam ansvarig för alla konsekvenser av att
använda den här programvaran.**

## Bidra

Läs
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) först.
Hårdvaruskrivvägar kräver ursprungsdokumentation, spärrar och
fysiska verifieringsposter — PR:ar som hoppar över detta kommer
inte att slås ihop.

## Licens

Dubbellicensierad under [MIT](LICENSE-MIT) eller
[Apache-2.0](LICENSE-APACHE), efter eget val.
