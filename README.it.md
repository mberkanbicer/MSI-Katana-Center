<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — gestione nativa Linux, con protezioni di sicurezza, di ventole, batteria e RGB della tastiera per portatili MSI, verificata sul Katana 17 B13VGK">
</p>

<p align="center">
  <sub>
    <a href="README.md">English</a> ·
    <a href="README.zh.md">简体中文</a> ·
    <a href="README.tr.md">Türkçe</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.sv.md">Svenska</a> ·
    <b>Italiano</b> ·
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
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#dipendenze)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> Questo file è una traduzione fornita dalla community. In caso di
> discrepanze, fa fede il [README in inglese](README.md).

Gestione hardware nativa Linux e open source per portatili MSI.
Sviluppato sul **MSI Katana 17 B13VGK** (scheda MS-17L5, EC
`17L5EMS1.115`) come dispositivo di riferimento. Core in Rust,
demone D-Bus, client desktop Qt/QML.

Ogni scrittura hardware è vincolata al firmware, autorizzata da
Polkit, opt-in per funzionalità, verificata tramite rilettura e
viene abilitata solo dopo la verifica fisica sul portatile di
riferimento. Le regole sono descritte in
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **Avviso di sviluppo assistito da IA:** questo progetto è
> interamente "vibecoded" — ogni commit è stato scritto da un agente
> di codifica IA che seguiva le regole in
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md), con un
> essere umano che ne definiva l'ambito, revisionava le modifiche e
> subordinava ogni scrittura hardware a una conferma esplicita prima
> che venisse eseguita su hardware reale. Nessuna riga di codice,
> documento di progettazione o registrazione di verifica fisica è
> stata generata senza questa revisione umana. Ciò non modifica il
> [disclaimer](#disclaimer--utilizzo-a-proprio-rischio) qui sotto:
> utilizzo a proprio rischio, leggere i meccanismi di sicurezza
> prima di attivare qualsiasi opt-in di scrittura.

## Interfaccia dal vivo

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="Panoramica del sistema: temperature CPU/GPU, carica della batteria, modalità ventola e RPM in tempo reale sul Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Tour delle pagine: Raffreddamento, Alimentazione, Batteria, RGB tastiera, Scene e Diagnostica">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Pagina RGB tastiera con anteprima delle zone MysticLight MS-1565">
</p>

## Cos'è

Un'applicazione desktop Center e uno strumento CLI che leggono lo
stato EC/ventola, le temperature, gli RPM e lo stato della
batteria — e, quando lo si abilita (opt-in), applicano un piccolo
insieme di scritture verificate: soglie di carica, modalità
ventola, Cooler Boost, Super Battery, webcam/tasti Fn e RGB
MysticLight.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="L'interfaccia Qt/QML e la CLI comunicano tramite D-Bus e Polkit con msi-daemon, che a sua volta raggiunge msi-ec, hwmon, l'interfaccia batteria e l'RGB MysticLight">
</p>

## Funzionalità

- **Telemetria in sola lettura** — modalità EC/ventola,
  temperature CPU/GPU, temperatura/carico per core, temperatura/
  carico per GPU, livelli ventola e RPM reale, stato batteria e
  soglie di carica, segnalazione delle capacità in runtime
- **Scritture vincolate e verificate** — soglie di carica della
  batteria, modalità ventola, Cooler Boost, Super Battery, webcam/
  blocco webcam, scambio tasti Fn/Win
- **RGB tastiera** — colore fisso ed effetti MysticLight MS-1565
  (respiro, ciclo, onda), non persistente per impostazione
  predefinita; il salvataggio su flash richiede un opt-in separato
- **Scene** — pacchetti denominati delle scritture vincolate, con
  applicazione/importazione/esportazione via CLI e UI, esempi
  iniziali (Silenzioso / Fresco / Risparmio batteria / Luci gaming),
  automazione opzionale all'avvio/rete-batteria/livello batteria/
  pianificazione (tutto opt-in, tutto gestito dalla UI)
- **Icona nella barra di sistema** — tooltip in tempo reale di
  temperature/RPM, azioni rapide, scorciatoie da tastiera
  (Ctrl+Shift+C/B/L/P)
- **Interfaccia desktop** — sette pagine (Panoramica,
  Raffreddamento, Alimentazione, Batteria, RGB tastiera, Scene,
  Diagnostica) con una scheda termica principale, azioni primarie
  fisse, un accordion per l'automazione delle scene, stato di
  connessione/obsolescenza e un banner per le azioni in coda
- **Diagnostica della community** — `msicenter report` senza
  numeri di serie per le richieste di supporto a monte
- **Ambiente di test con sysroot fittizio** — sviluppo e test
  senza hardware tramite `MSI_LINUX_CENTER_SYSROOT`

## Installazione

Compila il demone, la CLI e l'interfaccia Qt in versione release,
quindi installa systemd, Polkit, la policy D-Bus, il file desktop
e (per impostazione predefinita) l'avvio automatico della sessione.
L'unità systemd fornita abilita per impostazione predefinita gli
opt-in di scrittura per batteria, modalità ventola, cooler-boost,
RGB, webcam, blocco webcam e tasto fn; Super Battery e il
salvataggio flash RGB restano disattivati. Indipendentemente da
queste impostazioni predefinite, ogni scrittura resta vincolata da
Polkit nel demone, corrisponde esattamente al firmware ed è
verificata tramite rilettura/rollback — modificare
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
prima dell'installazione se si desidera un comportamento
predefinito completamente di sola lettura.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` non elimina `~/.config/msi-linux-center`. Il prefisso
predefinito è `/usr` (`PREFIX`, `SYSCONFDIR`).

### Requisiti

- Toolchain Rust (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- Linux con i moduli del kernel `msi-ec` e `msi_wmi_platform` per
  l'hardware reale (sia i percorsi di lettura che di scrittura si
  degradano in modo elegante in loro assenza)

Vedere [Dipendenze](#dipendenze) qui sotto per i pacchetti di
sistema esatti e i sistemi operativi supportati.

### Compilare dal sorgente

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Esecuzione

Contro l'ambiente di test incluso (nessun hardware necessario):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

In sola lettura sul portatile reale:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

**Non** eseguire la CLI con sudo. Le scritture privilegiate vengono
eseguite solo dal demone dopo l'autorizzazione Polkit.

## Comandi di scrittura (vincolati)

Ogni comando richiede che il demone sia in esecuzione con l'opt-in
corrispondente (`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) e completa
una richiesta Polkit:

```bash
msicenter battery-thresholds START END      # es. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # non persistente
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # salvataggio flash persistente (opt-in separato)
msicenter panic-reset                       # Cooler Boost disattivato, Super Battery disattivata, ventola automatica
msicenter scene list|examples|apply NAME
```

Con l'opt-in disattivato, il demone rifiuta con `NotSupported`.
L'ambito esatto del supporto, i vincoli e le registrazioni di
verifica fisica si trovano in
[`docs/dbus-contract.md`](docs/dbus-contract.md) e nei file
`docs/phase4-*-validation.md`.

## Modello di sicurezza

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Sei vincoli di scrittura: corrispondenza del firmware, opt-in, Polkit, rilettura, verifica fisica sul Katana 17 B13VGK e nessun registro non documentato">
</p>

1. **Vincolo del firmware** — le scritture vengono eseguite solo
   quando il firmware EC del dispositivo corrisponde esattamente a
   una stringa di firmware verificata fisicamente
2. **Vincolo opt-in** — ogni famiglia di scritture dipende dalla
   propria variabile d'ambiente del demone; l'unità systemd
   fornita abilita per impostazione predefinita batteria, modalità
   ventola, cooler-boost, RGB, webcam, blocco webcam e tasto fn
   (Super Battery e salvataggio flash RGB restano disattivati)
3. **Vincolo Polkit** — ogni metodo di scrittura D-Bus è associato
   a un'azione Polkit
4. **Verifica tramite rilettura** — le scritture EC e batteria
   vengono rilette e verificate; le scritture fallite vengono
   annullate
5. **Verifica fisica** — un percorso di scrittura viene rilasciato
   solo dopo essere stato testato sul portatile di riferimento e
   registrato in `docs/`
6. **Nessuna supposizione** — i registri non documentati non
   vengono mai scritti; la provenienza di ogni funzionalità
   hardware è registrata nel profilo del dispositivo

## Dispositivi supportati

| Dispositivo | Stato |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | dispositivo di riferimento verificato |
| Altri portatili MSI con `msi-ec` | solo telemetria in sola lettura; scritture vincolate dalla corrispondenza esatta del firmware |
| Modelli non corrispondenti | solo lettura + rapporto diagnostico; supporto della community tramite `msicenter report` |

<details>
<summary>Stato delle fasi</summary>

| Fase | Ambito | Stato |
|---|---|---|
| 0 | ricognizione hardware in sola lettura | completata |
| 1–2 | core in sola lettura, database dispositivi, capacità in runtime, ambiente di test | completata |
| 3 | demone D-Bus, unità systemd, policy D-Bus, azioni Polkit | completata |
| 4 | scritture semantiche vincolate (soglie batteria, modalità ventola, Cooler Boost, Super Battery) | completata — verificata fisicamente il 05/09/2026 |
| 5 | curve ventola personalizzate | [studio di progettazione](docs/phase5-fan-curve-design.md) — nessuna scrittura fino al completamento dell'esperimento §11 |
| 6 | interfaccia desktop Qt/QML | completata — [progettazione](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` verificata fisicamente; modalità effetti implementate; salvataggio flash implementato, test fisico in sospeso |
| 8 | scene | completata — CLI + UI validate |
| 9 | diagnostica della community | completata — [progettazione](docs/phase9-diagnostics.md) |
| 10 | MUX | solo ricerca — [note](docs/deferred-features-research.md) |

</details>

## Documentazione

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — contratto API D-Bus
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — protocollo MysticLight
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — inventario di reverse engineering
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — regole di sicurezza per contributori e agenti
- [Wiki del progetto](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — installazione, modello di sicurezza, API D-Bus e FAQ in forma consultabile

## Dipendenze

**Sistemi operativi supportati** — Solo Linux. Sviluppato e
testato su Arch Linux e Ubuntu (la CI viene eseguita su
`ubuntu-latest`); qualsiasi distribuzione con `systemd`, Polkit,
D-Bus, Qt 6 e una toolchain Rust recente dovrebbe funzionare. I
moduli del kernel `msi-ec` e `msi_wmi_platform` sono richiesti per
la telemetria/scrittura su hardware reale — il progetto comunque
si compila e viene eseguito in sola lettura tramite l'ambiente di
test anche senza di essi.

**Pacchetti di sistema indispensabili**

| Pacchetto | Scopo |
|---|---|
| Toolchain Rust ≥ 1.75 (`cargo`) | compila tutte le crate Rust |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | interfaccia desktop |
| CMake ≥ 3.21 | compilazione dell'interfaccia Qt |
| `pkg-config` | individua `libusb-1.0` in fase di compilazione |
| `libusb-1.0-0-dev` (header di sviluppo) | backend HID RGB, collegato staticamente in fase di compilazione |
| `libudev-dev` | enumerazione hardware/dispositivi |
| `systemd`, `polkit`, `dbus` (runtime) | servizio del demone, vincolo dei privilegi, IPC |
| `libusb-1.0-0` (runtime) | dipendenza runtime del backend HID RGB |

```bash
# Debian/Ubuntu (come nella CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**Crate Rust principali** — `zbus` (D-Bus), `serde`/`serde_json`
(dati + profili dispositivo), `hidapi` (backend
`linux-static-libusb` collegato staticamente per l'RGB MysticLight
— vedere le
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
se il pacchetto `hidapi` della distribuzione causa errori di
collegamento). Grafo completo delle dipendenze in `Cargo.lock` e
nel `Cargo.toml` di ciascuna crate.

**Moduli del kernel utilizzati** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(stato semantico EC, modalità ventola, Cooler Boost, Super
Battery, webcam/tasto Fn), `msi_wmi_platform`/hwmon (RPM reale
della ventola), `power_supply` di Linux (stato della batteria e
soglie di carica).

**Progetti consultati durante lo sviluppo** — solo materiale di
ricerca/riferimento; nulla di questo è incorporato o collegato, e
ogni percorso di scrittura è stato verificato in modo indipendente
prima del rilascio (vedere il
[modello di sicurezza](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| Progetto | Utilizzato per |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | conoscenza di modelli/firmware MSI, ricerca su EC/registri, curve ventola, metodologia di verifica |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | semantica Linux MSI EC/sysfs, modalità, Cooler Boost, temperature, livelli ventola e modelli supportati |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | comportamento comparativo di funzionalità/UX MSI su Linux |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | separazione dei privilegi, concetti Polkit, controllo ventola, simulazione e ripristino |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | protocollo USB/HID Katana Mystic Light e ricerca RGB a 4 zone |
| [Kernel Linux](https://github.com/torvalds/linux) | riferimento di implementazione a massima priorità per hwmon, power_supply, WMI, ACPI, HID, DRM e driver di piattaforma |

## Disclaimer — utilizzo a proprio rischio

Questo software controlla l'hardware del portatile tramite il
controller embedded (EC), le interfacce di carica della batteria e
un controller RGB USB HID. Scritture errate su queste interfacce
possono causare instabilità, problemi termici, riduzione della
durata della batteria, perdita di dati o danni all'hardware/
firmware.

**Questo progetto viene fornito "così com'è", senza alcuna garanzia
di alcun tipo, esplicita o implicita. Gli autori e i contributori
non si assumono alcuna responsabilità per eventuali danni, perdite
di dati o malfunzionamenti derivanti dall'uso di questo software —
compresi i danni al portatile, alla batteria, alla tastiera o a
qualsiasi altro hardware.**

Le misure di mitigazione integrate nel progetto (vincolo del
firmware, opt-in per funzionalità, autorizzazione Polkit, verifica
tramite rilettura, verifica fisica sul dispositivo di riferimento)
riducono il rischio ma non lo eliminano. Sono misure ingegneristiche
fatte con la massima diligenza, non garanzie.

- Le scritture di soglie batteria, modalità ventola, Cooler Boost,
  RGB, webcam, blocco webcam e tasto Fn sono **abilitate per
  impostazione predefinita** nell'unità systemd installata (Super
  Battery e salvataggio flash RGB restano disattivati); installarle
  solo se si comprende cosa fanno, e modificare il file dell'unità
  prima dell'installazione se si desidera un comportamento
  predefinito completamente di sola lettura
- Il comportamento è verificato fisicamente solo sul **MSI Katana
  17 B13VGK** (EC `17L5EMS1.115`); altri modelli sono vincolati ma
  non verificati
- Non utilizzare questo software su un portatile che non ci si può
  permettere di danneggiare, e non abilitare mai gli opt-in di
  scrittura su hardware critico
- In caso di dubbio, utilizzare solo le funzionalità di telemetria
  in sola lettura

**Fare attenzione. Si è gli unici responsabili di qualsiasi
conseguenza derivante dall'uso di questo software.**

## Contribuire

Leggere prima
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md). I
percorsi di scrittura hardware richiedono provenienza, vincoli e
registrazioni di verifica fisica — le PR che li omettono non
verranno unite.

## Licenza

Doppia licenza [MIT](LICENSE-MIT) o [Apache-2.0](LICENSE-APACHE),
a propria scelta.
