<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <a href="CHANGELOG.sv.md">Svenska</a> ·
    <b>Italiano</b> ·
    <a href="CHANGELOG.pt.md">Português</a> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *Questa traduzione è fornita dalla comunità. In caso di discrepanze, fa fede la versione inglese `CHANGELOG.md`.*

# Registro delle modifiche

Tutte le modifiche rilevanti di questo progetto sono documentate in
questo file. Il formato segue in modo libero
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), raggruppato
per fase di sviluppo invece che per rigorosi incrementi di versione
semantica, perché questo progetto viene distribuito come snapshot
continuo validato su un unico dispositivo di riferimento (MSI Katana 17
B13VGK, firmware `17L5EMS1.115`).

## [Non pubblicato]

### Aggiunte
- Traduzioni della community di `README.md` in 12 lingue (cinese,
  turco, tedesco, francese, svedese, italiano, portoghese, spagnolo,
  arabo, hindi, giapponese, coreano) con language switcher.
- Traduzione delle pagine del wiki GitHub e di questo changelog nelle
  stesse 12 lingue.
- Sezione `Dependencies` in `README.md` che documenta pacchetti di
  sistema richiesti, sistemi operativi supportati, moduli kernel e
  progetti di riferimento upstream.
- Avviso di divulgazione dello sviluppo assistito da IA ("vibecoded") in
  `README.md`.
- Badge Rust/Platform/Wiki e ristrutturazione del layout del README.

### Modifiche
- Le scritture di battery threshold, fan-mode, Cooler Boost, RGB,
  webcam, webcam block e fn-key ora sono abilitate **per impostazione
  predefinita** nell'unità systemd installata (Super Battery e il
  salvataggio RGB non volatile restano opt-out).

### Correzioni
- Collegamento statico di `hidapi` (backend `linux-static-libusb`) per
  correggere errori CI e problemi di linking tra versioni di
  distribuzione quando il pacchetto di sistema `hidapi` è incompatibile.
- Il workflow CI installa `libhidapi-dev` così che la crate `hidapi` si
  compili correttamente.
- Corretto il messaggio di rifiuto Polkit e aggiunta copertura per il
  percorso di errore del rollback.

## [0.2.0] — 2026-09-06

### Aggiunte
- **Phase 9 — Diagnostica della community**: comando `msicenter report`
  che produce un bundle diagnostico condivisibile senza numeri di serie.
- **Phase 8 — Scene**: bundle nominati di scritture gateate, comandi CLI
  `scene list|examples|apply`, scene di esempio (quiet / cool / battery
  saver / gaming rgb) e una pagina Scenes nella UI desktop con trigger
  di automazione opzionali (boot, passaggio AC/batteria, livello
  batteria, pianificazione).
- **Phase 7 — RGB (MysticLight MS-1565)**: probe in sola lettura del
  controller HID, costruttore di pacchetti del protocollo con test
  unitari, scritture gateate non persistenti `SetRgbColor` e degli
  effetti (breathing, rainbow, wave), `rgb-save` non volatile gateato e
  pagina RGB tastiera nella UI desktop.
- **Phase 6 — UI desktop Qt/QML**: client desktop completo a sette
  pagine (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes,
  Diagnostics) con redesign in stile Material, navigazione laterale,
  hero card termica, viste di dettaglio per core CPU e per GPU,
  quick action persistenti, menu di automazione comprimibili, stato di
  connessione/refresh e barra toast per azioni in sospeso.
- Report end-to-end di temperatura/carico CPU per core e dettagli GPU
  (core → daemon → UI).
- Icona nella system tray con tooltip in tempo reale di temperatura/RPM,
  quick action e scorciatoie da tastiera (Ctrl+Shift+C/B/L/P).

### Modifiche
- Controlli dei gate di scrittura unificati nei gestori di scrittura del
  daemon e aggiunti test di disponibilità.
- Allentato il pin della versione `zbus`.

## [0.1.0] — 2026-09-05

### Aggiunte
- **Phase 0–2 — Fondamenta in sola lettura**: rilevamento hardware,
  core Rust in sola lettura, database dispositivi (`msi-device-db`),
  report delle capacità a runtime e fixture fake-sysroot per sviluppo e
  test senza hardware (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — Daemon D-Bus**: servizio systemd `msi-daemon`, policy
  D-Bus e azioni Polkit che gateano ogni metodo privilegiato.
- **Phase 4 — Scritture sicure e gateate**: soglia di carica della
  batteria, modalità ventola (auto/silent/advanced), Cooler Boost e
  percorsi di scrittura Super Battery, ciascuno protetto da
  corrispondenza esatta del firmware, variabile d'ambiente di opt-in per
  funzionalità, autorizzazione Polkit e verifica tramite read-back con
  rollback in caso di errore. Tutti e quattro i percorsi di scrittura
  sono stati verificati fisicamente sul dispositivo di riferimento MSI
  Katana 17 B13VGK il 2026-09-05.
- Client a riga di comando `msicenter-cli` (`status`, `capabilities` e i
  sottocomandi di scrittura gateati).
- Regole di sicurezza `MSI-Linux-Center-AGENTS.md` per contributori e
  agenti AI di coding.
- Studi di progettazione per funzionalità rinviate: custom fan curves
  (Phase 5, solo progettazione in attesa di un esperimento con consenso
  esplicito per il rollback della tabella EC) e GPU MUX switching (solo
  ricerca).

[Non pubblicato]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
