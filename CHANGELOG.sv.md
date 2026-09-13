<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <b>Svenska</b> ·
    <a href="CHANGELOG.it.md">Italiano</a> ·
    <a href="CHANGELOG.pt.md">Português</a> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *Denna översättning tillhandahålls av communityn. Vid avvikelser är den engelska `CHANGELOG.md` den auktoritativa versionen.*

# Ändringslogg

Alla viktiga ändringar i det här projektet dokumenteras i denna fil.
Formatet följer löst [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
grupperat efter utvecklingsfas i stället för strikta semantiska
versionshöjningar, eftersom projektet levereras som en rullande snapshot
validerad mot en enda referensenhet (MSI Katana 17 B13VGK,
firmware `17L5EMS1.115`).

## [Ej släppt]

### Tillagt
- Community-översättningar av `README.md` till 12 språk (kinesiska,
  turkiska, tyska, franska, svenska, italienska, portugisiska,
  spanska, arabiska, hindi, japanska, koreanska) med språkväxlare.
- Översatta GitHub-wikisidor och denna ändringslogg till samma 12 språk.
- Avsnittet `Dependencies` i `README.md` som dokumenterar nödvändiga
  systempaket, stödda operativsystem, kärnmoduler och uppströms
  referensprojekt.
- Information i `README.md` om AI-assisterad utveckling ("vibecoded").
- Rust/Platform/Wiki-badges och omstrukturerad README-layout.

### Ändrat
- Skrivningar för battery threshold, fan-mode, Cooler Boost, RGB,
  webcam, webcam block och fn-key är nu aktiverade **som standard** i
  den installerade systemd-enheten (Super Battery och icke-flyktigt RGB-
  sparande förblir opt-out).

### Fixat
- Statiskt länkad `hidapi` (backend `linux-static-libusb`) för att
  åtgärda CI-fel och länkfel mellan distributionsversioner när systemets
  `hidapi`-paket är inkompatibelt.
- CI-workflow:n installerar `libhidapi-dev` så att crate:n `hidapi`
  byggs korrekt.
- Polkit-avslagsmeddelandet har korrigerats och täckning för rollbackens
  felväg har lagts till.

## [0.2.0] — 2026-09-06

### Tillagt
- **Phase 9 — Community-diagnostik**: kommandot `msicenter report` som
  skapar en delbar diagnostikbundle utan serienummer.
- **Phase 8 — Scener**: namngivna buntar av gateade skrivningar,
  CLI-kommandon `scene list|examples|apply`, exempelscener (quiet /
  cool / battery saver / gaming rgb) och en Scenes-sida i skrivbords-
  UI:t med valfria automationstriggers (boot, växling mellan nät/
  batteri, batterinivå, schema).
- **Phase 7 — RGB (MysticLight MS-1565)**: skrivskyddad HID-probe för
  kontrollern, protokollpaketbyggare med enhetstester, gateade icke
  beständiga `SetRgbColor`- och effekt-skrivningar (breathing, rainbow,
  wave), gatead icke-flyktig `rgb-save`, samt en tangentbords-RGB-sida i
  skrivbords-UI:t.
- **Phase 6 — Qt/QML-skrivbords-UI**: fullständig skrivbordsklient med
  sju sidor (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes,
  Diagnostics) med Material-inspirerad redesign, sidofältsnavigering,
  hero-termalkort, detaljvyer per CPU-kärna och per GPU, fasta
  snabbåtgärder, hopfällbara automationsmenyer, anslutnings-/uppdaterings-
  status och en toast-rad för väntande åtgärder.
- End-to-end-rapportering av CPU-temperatur/belastning per kärna och
  GPU-detaljer (core → daemon → UI).
- Ikon i system tray med verktygstips för live-temperatur/RPM,
  snabbåtgärder och tangentbordsgenvägar (Ctrl+Shift+C/B/L/P).

### Ändrat
- Enhetliga kontroller av skriv-gates i daemonens skrivhanterare och
  tillägg av tillgänglighetstester.
- Mjukare versionslåsning för `zbus`.

## [0.1.0] — 2026-09-05

### Tillagt
- **Phase 0–2 — Skrivskyddad grund**: hårdvaruupptäckt, en
  skrivskyddad Rust-kärna, enhetsdatabas (`msi-device-db`), rapportering
  av runtime capabilities och en fake-sysroot-fixture för utveckling och
  testning utan hårdvara (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus-demon**: `msi-daemon`-tjänst för systemd,
  D-Bus-policy och Polkit-åtgärder som gatear varje privilegierad metod.
- **Phase 4 — Säkra, gateade skrivningar**: laddningströskel för
  batteri, fläktläge (auto/silent/advanced), Cooler Boost och
  skrivvägar för Super Battery, var och en skyddad av exakt firmware-
  matchning, miljövariabel för opt-in per funktion, Polkit-
  auktorisering och verifiering genom återläsning med rollback vid fel.
  Alla fyra skrivvägar verifierades fysiskt på referensenheten MSI
  Katana 17 B13VGK den 2026-09-05.
- Kommandoradsklienten `msicenter-cli` (`status`, `capabilities` och de
  gateade underkommandona för skrivning).
- Säkerhetsreglerna i `MSI-Linux-Center-AGENTS.md` för bidragsgivare och
  AI-kodagenter.
- Designstudier för uppskjutna funktioner: anpassade fläktkurvor
  (Phase 5, endast design i väntan på ett samtyckesgateat experiment för
  rollback av EC-tabell) och växling av GPU MUX (endast forskning).

[Ej släppt]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
