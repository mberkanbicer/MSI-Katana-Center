<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <a href="CHANGELOG.sv.md">Svenska</a> ·
    <a href="CHANGELOG.it.md">Italiano</a> ·
    <a href="CHANGELOG.pt.md">Português</a> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <b>हिन्दी</b> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *यह फ़ाइल समुदाय द्वारा प्रदान किया गया अनुवाद है। किसी भी विसंगति की स्थिति में अंग्रेज़ी `CHANGELOG.md` को प्रामाणिक माना जाएगा।*

# परिवर्तन लॉग

इस प्रोजेक्ट में किए गए सभी उल्लेखनीय बदलाव इस फ़ाइल में दर्ज किए गए हैं।
इसका प्रारूप मोटे तौर पर [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
का अनुसरण करता है, लेकिन strict semantic version bumps के बजाय
development phase के आधार पर समूहित है, क्योंकि यह प्रोजेक्ट एक rolling
snapshot के रूप में ship होता है जिसे एक ही reference device (MSI Katana
17 B13VGK, firmware `17L5EMS1.115`) के विरुद्ध validated किया जाता है।

## [अप्रकाशित]

### जोड़ा गया
- `README.md` के 12 भाषाओं (चीनी, तुर्की, जर्मन, फ़्रेंच, स्वीडिश,
  इतालवी, पुर्तगाली, स्पेनिश, अरबी, हिंदी, जापानी, कोरियाई) में
  language switcher के साथ community translations।
- उन्हीं 12 भाषाओं में अनुवादित GitHub wiki pages और यह changelog।
- `README.md` में `Dependencies` अनुभाग, जिसमें आवश्यक system
  packages, supported OSes, kernel modules, और upstream reference
  projects दस्तावेजीकृत हैं।
- `README.md` में AI-assisted development ("vibecoded") disclosure
  notice।
- Rust/Platform/Wiki badges और पुनर्संरचित README layout।

### बदला गया
- Installed systemd unit में battery threshold, fan-mode, Cooler
  Boost, RGB, webcam, webcam block, और fn-key writes अब **डिफ़ॉल्ट
  रूप से** सक्षम हैं (Super Battery और non-volatile RGB save अभी भी
  opt-out रहते हैं)।

### सुधारा गया
- जब system `hidapi` package असंगत हो, तब CI failures और distro-
  version linker errors ठीक करने के लिए `hidapi` (`linux-static-libusb`
  backend) को statically link किया गया।
- CI workflow अब `libhidapi-dev` इंस्टॉल करता है ताकि `hidapi` crate
  साफ़-सुथरे ढंग से build हो।
- Polkit denial message को ठीक किया गया और rollback failure path के
  लिए coverage जोड़ी गई।

## [0.2.0] — 2026-09-06

### जोड़ा गया
- **Phase 9 — Community diagnostics**: `msicenter report` command,
  जो serial numbers के बिना साझा करने योग्य diagnostic bundle तैयार
  करता है।
- **Phase 8 — Scenes**: gated writes के named bundles, `scene
  list|examples|apply` CLI commands, example scenes (quiet / cool /
  battery saver / gaming rgb), और desktop UI में Scenes page, जिसमें
  optional automation triggers (boot, AC/battery switch, battery
  level, schedule) हैं।
- **Phase 7 — RGB (MysticLight MS-1565)**: read-only HID controller
  probe, unit tests के साथ protocol packet builder, gated
  non-persistent `SetRgbColor` और effect writes (breathing, rainbow,
  wave), gated non-volatile `rgb-save`, और desktop UI में keyboard RGB
  page।
- **Phase 6 — Qt/QML desktop UI**: पूरा seven-page desktop client
  (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes,
  Diagnostics), Material-style redesign, sidebar navigation, hero
  thermal card, per-core CPU/per-GPU detail views, sticky quick
  actions, collapsible automation menus, connection/refresh status,
  और pending actions के लिए toast bar के साथ।
- End-to-end per-core CPU temperature/load और per-GPU detail
  reporting (core → daemon → UI)।
- Live temperature/RPM tooltip, quick actions, और keyboard shortcuts
  (Ctrl+Shift+C/B/L/P) के साथ system tray icon।

### बदला गया
- Daemon write handlers में write-gate checks को एकीकृत किया गया और
  availability tests जोड़े गए।
- `zbus` version pin को शिथिल किया गया।

## [0.1.0] — 2026-09-05

### जोड़ा गया
- **Phase 0–2 — Read-only foundation**: hardware discovery, read-only
  Rust core, device database (`msi-device-db`), runtime capability
  reporting, और hardware-free development/testing के लिए fake-sysroot
  fixture (`MSI_LINUX_CENTER_SYSROOT`)।
- **Phase 3 — D-Bus daemon**: `msi-daemon` systemd service, D-Bus
  policy, और हर privileged method को gate करने वाली Polkit actions।
- **Phase 4 — Safe, gated writes**: battery charge threshold, fan
  mode (auto/silent/advanced), Cooler Boost, और Super Battery write
  paths, जिनमें प्रत्येक firmware-match gating, per-feature opt-in
  environment variable, Polkit authorization, और failure पर rollback
  के साथ read-back verification द्वारा सुरक्षित है। सभी चार write
  paths को MSI Katana 17 B13VGK reference device पर 2026-09-05 को
  physically verified किया गया।
- `msicenter-cli` command-line client (`status`, `capabilities`,
  और gated write subcommands)।
- Contributors और AI coding agents के लिए `MSI-Linux-Center-AGENTS.md`
  safety rules।
- Deferred features के लिए design studies: custom fan curves (Phase
  5, design-only pending a consent-gated EC table rollback
  experiment) और GPU MUX switching (research-only)।

[अप्रकाशित]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
