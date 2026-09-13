<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — MSI लैपटॉप के लिए फैन, बैटरी और कीबोर्ड RGB हेतु सेफ्टी-गेटेड, नेटिव Linux डिवाइस मैनेजमेंट, Katana 17 B13VGK पर सत्यापित">
</p>

<p align="center">
  <sub>
    <a href="README.md">English</a> ·
    <a href="README.zh.md">简体中文</a> ·
    <a href="README.tr.md">Türkçe</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.sv.md">Svenska</a> ·
    <a href="README.it.md">Italiano</a> ·
    <a href="README.pt.md">Português</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.ar.md">العربية</a> ·
    <b>हिन्दी</b> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#निर्भरताएँ)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> यह फ़ाइल एक समुदाय-योगदान अनुवाद है। किसी भी विसंगति की स्थिति में,
> [अंग्रेज़ी फ़ाइल](README.md) को अंतिम माना जाएगा।

MSI लैपटॉप के लिए एक ओपन-सोर्स, नेटिव Linux डिवाइस मैनेजमेंट टूल।
यह **MSI Katana 17 B13VGK** (बोर्ड MS-17L5, EC फर्मवेयर
`17L5EMS1.115`) को संदर्भ डिवाइस मानकर विकसित किया गया है। एक Rust
कोर, एक D-Bus डेमन, और एक Qt/QML डेस्कटॉप क्लाइंट।

हर हार्डवेयर राइट फर्मवेयर मिलान द्वारा सुरक्षित, Polkit द्वारा
अधिकृत, प्रति-फीचर opt-in के पीछे रखा हुआ, रीड-बैक द्वारा सत्यापित,
और वास्तविक हार्डवेयर पर सत्यापित होने के बाद ही सक्षम किया जाता
है। पूरे नियम [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)
में देखें।

> **AI-सहायता प्राप्त विकास संबंधी सूचना:** यह प्रोजेक्ट पूरी तरह
> AI द्वारा लिखा गया है ("vibecoded") — हर कमिट एक AI कोडिंग एजेंट
> द्वारा लिखा गया है, जो
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) में
> दिए गए नियमों के तहत काम करता है, जबकि एक इंसान ने स्कोप तय किया,
> परिवर्तनों की समीक्षा की, और किसी भी वास्तविक हार्डवेयर पर लागू
> करने से पहले हर हार्डवेयर राइट के लिए स्पष्ट अनुमोदन आवश्यक किया।
> इस मानवीय समीक्षा के बिना कोई कोड, डिज़ाइन दस्तावेज़, या वास्तविक
> सत्यापन रिकॉर्ड मौजूद नहीं है। यह नीचे दिए गए
> [अस्वीकरण](#अस्वीकरण--अपने-जोखिम-पर-उपयोग-करें) को किसी भी तरह
> से नहीं बदलता है: अपने जोखिम पर उपयोग करें, कोई भी राइट फीचर सक्षम
> करने से पहले सुरक्षा मॉडल पढ़ें।

## लाइव UI

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="सिस्टम ओवरव्यू: CPU/GPU तापमान, बैटरी चार्ज, फैन मोड, और Katana 17 पर वास्तविक फैन RPM">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="पेज टूर: कूलिंग, पावर, बैटरी, कीबोर्ड RGB, सीन, और डायग्नोस्टिक्स">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="MysticLight MS-1565 ज़ोन प्रीव्यू के साथ कीबोर्ड RGB पेज">
</p>

## यह क्या है

एक डेस्कटॉप ऐप (Center) और CLI जो EC मोड/फैन स्टेटस, तापमान, फैन
RPM, और बैटरी स्थिति पढ़ता है — और opt-in पर, सत्यापित राइट्स का एक
छोटा सा समूह लागू करता है: चार्ज थ्रेशोल्ड, फैन मोड, Cooler Boost,
Super Battery, वेबकैम/Fn कीज़, और MysticLight RGB।

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML UI और CLI D-Bus + Polkit के माध्यम से msi-daemon से बात करते हैं, जो आगे msi-ec, hwmon, बैटरी इंटरफ़ेस, और MysticLight RGB तक पहुँचता है">
</p>

## विशेषताएँ

- **रीड-ओनली टेलीमेट्री** — EC/फैन मोड, CPU/GPU तापमान, प्रति-कोर
  तापमान/लोड, प्रति-GPU तापमान/लोड, फैन लेवल और वास्तविक RPM,
  बैटरी स्थिति और चार्ज थ्रेशोल्ड, रनटाइम क्षमता रिपोर्टिंग
- **सुरक्षित, सत्यापित राइट्स** — बैटरी चार्ज थ्रेशोल्ड, फैन मोड,
  Cooler Boost, Super Battery, वेबकैम/वेबकैम ब्लॉक, Fn/Win की स्वैप
- **कीबोर्ड RGB** — स्थिर रंग और MysticLight MS-1565 प्रभाव
  (breathing, rainbow, wave), डिफ़ॉल्ट रूप से गैर-स्थायी;
  नॉन-वोलेटाइल सेव के लिए अलग opt-in चाहिए
- **सीन (Scenes)** — सुरक्षित राइट्स के नामित बंडल, CLI + UI में
  अप्लाई/इम्पोर्ट/एक्सपोर्ट, तैयार उदाहरण (quiet / cool / battery
  saver / gaming rgb), वैकल्पिक ऑटोमेशन ट्रिगर्स बूट/AC-बैटरी
  स्विच/बैटरी लेवल/शेड्यूल पर (सभी opt-in और UI से पूरी तरह
  प्रबंधित)
- **ट्रे आइकन** — लाइव टूलटिप तापमान और RPM के साथ, क्विक एक्शन,
  कीबोर्ड शॉर्टकट (Ctrl+Shift+C/B/L/P)
- **डेस्कटॉप UI** — सात पेज (ओवरव्यू, कूलिंग, पावर, बैटरी, कीबोर्ड
  RGB, सीन, डायग्नोस्टिक्स) एक हीरो थर्मल कार्ड, स्थायी क्विक
  एक्शन्स, कोलैप्सिबल सीन ऑटोमेशन मेनू, कनेक्शन/रीफ्रेश स्टेटस, और
  लंबित क्रियाओं के लिए एक टोस्ट बार के साथ
- **सामुदायिक डायग्नोस्टिक्स** — अपस्ट्रीम सपोर्ट अनुरोधों के लिए
  बिना किसी सीरियल नंबर वाला `msicenter report`
- **फ़ेक sysroot** — असली हार्डवेयर के बिना
  `MSI_LINUX_CENTER_SYSROOT` के माध्यम से विकास/परीक्षण

## इंस्टॉलेशन

रिलीज़ डेमन, CLI, और Qt UI बनाता है, फिर systemd, Polkit, D-Bus
पॉलिसी, डेस्कटॉप एंट्री, और (डिफ़ॉल्ट रूप से) सेशन ऑटोस्टार्ट
इंस्टॉल करता है। शामिल systemd यूनिट **डिफ़ॉल्ट रूप से** बैटरी,
फैन मोड, Cooler Boost, RGB, वेबकैम, वेबकैम ब्लॉक, और fn-key राइट्स
को सक्षम करती है; Super Battery और नॉन-वोलेटाइल RGB सेव अक्षम रहते
हैं। इन डिफ़ॉल्ट्स के बावजूद, हर राइट अभी भी डेमन के अंदर Polkit से
सुरक्षित है, फर्मवेयर-सटीक है, और रीड-बैक/रोलबैक द्वारा सत्यापित
है — यदि आप पूरी तरह रीड-ओनली डिफ़ॉल्ट चाहते हैं तो इंस्टॉल करने से
पहले
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
संपादित करें।

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` `~/.config/msi-linux-center` को नहीं हटाता। डिफ़ॉल्ट
प्रीफ़िक्स `/usr` है (`PREFIX` और `SYSCONFDIR` से कॉन्फ़िगर करने
योग्य)।

### आवश्यकताएँ

- Rust टूलचेन (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) + CMake ≥
  3.21
- असली हार्डवेयर पर काम करने के लिए `msi-ec` और
  `msi_wmi_platform` कर्नेल मॉड्यूल के साथ Linux (दोनों अनुपस्थित
  होने पर रीड और राइट पथ सुरक्षित रूप से डिग्रेड हो जाते हैं)

सटीक सिस्टम पैकेज और समर्थित OS के लिए नीचे
[निर्भरताएँ](#निर्भरताएँ) अनुभाग देखें।

### सोर्स से बिल्ड करें

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## चलाना

शामिल फ़िक्सचर के विरुद्ध (कोई असली हार्डवेयर आवश्यक नहीं):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

असली लैपटॉप पर, रीड-ओनली:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

CLI को sudo के साथ **न चलाएँ**। विशेषाधिकार प्राप्त राइट्स केवल
Polkit प्राधिकरण के बाद डेमन द्वारा निष्पादित की जाती हैं।

## राइट कमांड (सुरक्षित)

हर कमांड के लिए डेमन को संबंधित opt-in
(`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) के साथ चलना चाहिए और Polkit
प्राधिकरण प्रॉम्प्ट पूरा किया जाना चाहिए:

```bash
msicenter battery-thresholds START END      # जैसे 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # गैर-स्थायी
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # नॉन-वोलेटाइल सेव (अलग opt-in)
msicenter panic-reset                       # Cooler Boost बंद, Super Battery बंद, फैन auto पर वापस
msicenter scene list|examples|apply NAME
```

अगर opt-in अक्षम है, तो डेमन `NotSupported` के साथ इनकार करता है।
सटीक सपोर्ट मैट्रिक्स, गार्ड्स, और वास्तविक सत्यापन लॉग के लिए
[`docs/dbus-contract.md`](docs/dbus-contract.md) और
`docs/phase4-*-validation.md` देखें।

## सुरक्षा मॉडल

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="राइट्स के लिए छह सुरक्षा गेट: फर्मवेयर मिलान, opt-in, Polkit, रीड-बैक, Katana 17 B13VGK पर वास्तविक सत्यापन, और अनडॉक्यूमेंटेड रजिस्टरों में कोई अनुमान नहीं">
</p>

1. **फर्मवेयर गेट** — राइट्स तभी चलती हैं जब EC फर्मवेयर स्ट्रिंग
   बिल्कुल एक वास्तविक-सत्यापित फर्मवेयर से मेल खाती हो
2. **Opt-in गेट** — हर राइट श्रेणी डेमन में अपने स्वयं के environment
   variable के पीछे है; शामिल systemd यूनिट डिफ़ॉल्ट रूप से बैटरी,
   फैन मोड, Cooler Boost, RGB, वेबकैम, वेबकैम ब्लॉक, और fn-key को
   सक्षम करती है (Super Battery और नॉन-वोलेटाइल RGB सेव अक्षम रहते
   हैं)
3. **Polkit गेट** — हर D-Bus राइट मेथड एक Polkit एक्शन से मैप होता
   है
4. **रीड-बैक सत्यापन** — EC/बैटरी राइट्स को रीड-बैक और सत्यापित
   किया जाता है; विफल राइट्स को रोलबैक किया जाता है
5. **वास्तविक सत्यापन** — कोई भी राइट पथ तब तक शिप नहीं किया जाता
   जब तक इसे संदर्भ हार्डवेयर पर परीक्षण और `docs/` में दस्तावेज़
   नहीं किया गया हो
6. **कोई अनुमान नहीं** — अनडॉक्यूमेंटेड रजिस्टरों में कभी नहीं
   लिखा जाता; हर हार्डवेयर फीचर का स्रोत डिवाइस प्रोफ़ाइल में
   रिकॉर्ड किया जाता है

## समर्थित डिवाइस

| डिवाइस | स्थिति |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, फर्मवेयर `17L5EMS1.115`) | वास्तविक-सत्यापित संदर्भ डिवाइस |
| अन्य `msi-ec`-समर्थित MSI लैपटॉप | रीड-ओनली टेलीमेट्री; राइट्स सटीक फर्मवेयर मिलान द्वारा सुरक्षित |
| गैर-मिलान मॉडल | रीड-ओनली + डायग्नोस्टिक रिपोर्ट; `msicenter report` के माध्यम से सामुदायिक समर्थन |

<details>
<summary>चरण स्थिति</summary>

| चरण | स्कोप | स्थिति |
|---|---|---|
| 0 | रीड-ओनली हार्डवेयर खोज | पूर्ण |
| 1–2 | रीड-ओनली कोर, डिवाइस DB, रनटाइम क्षमताएँ, फ़िक्सचर | पूर्ण |
| 3 | D-Bus डेमन, systemd यूनिट, D-Bus पॉलिसी, Polkit एक्शन | पूर्ण |
| 4 | सुरक्षित सिमेंटिक राइट्स (बैटरी थ्रेशोल्ड, फैन मोड, Cooler Boost, Super Battery) | पूर्ण — 2026-09-05 को वास्तविक-सत्यापित |
| 5 | कस्टम फैन कर्व्स | [डिज़ाइन-ओनली](docs/phase5-fan-curve-design.md) — §11 प्रयोग पूरा होने तक कोई कोड नहीं |
| 6 | Qt/QML डेस्कटॉप UI | पूर्ण — [डिज़ाइन](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` वास्तविक-सत्यापित; प्रभाव मोड लागू; नॉन-वोलेटाइल सेव लागू, वास्तविक परीक्षण बाकी |
| 8 | सीन | पूर्ण — CLI + UI सत्यापित |
| 9 | सामुदायिक डायग्नोस्टिक्स | पूर्ण — [डिज़ाइन](docs/phase9-diagnostics.md) |
| 10 | GPU MUX स्विचिंग | केवल शोध — [नोट्स](docs/deferred-features-research.md) |

</details>

## दस्तावेज़ीकरण

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — D-Bus API अनुबंध
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — MysticLight प्रोटोकॉल
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — रिवर्स-इंजीनियरिंग इन्वेंट्री
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — योगदानकर्ताओं और AI एजेंट के लिए सुरक्षा नियम
- [प्रोजेक्ट विकी](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — ब्राउज़ करने योग्य फॉर्म में इंस्टॉलेशन, सुरक्षा मॉडल, D-Bus API, और FAQ

## निर्भरताएँ

**समर्थित OS** — केवल Linux। Arch Linux और Ubuntu पर विकसित और
परीक्षण किया गया (CI `ubuntu-latest` पर चलता है); `systemd`,
Polkit, D-Bus, Qt 6, और एक आधुनिक Rust टूलचेन वाला कोई भी वितरण
काम करना चाहिए। असली हार्डवेयर टेलीमेट्री/राइट्स के लिए `msi-ec`
और `msi_wmi_platform` कर्नेल मॉड्यूल आवश्यक हैं — इनके बिना भी
प्रोजेक्ट फ़िक्सचर के माध्यम से रीड-ओनली रूप से बिल्ड और चलता है।

**मूल सिस्टम पैकेज**

| पैकेज | उद्देश्य |
|---|---|
| Rust टूलचेन ≥ 1.75 (`cargo`) | सभी Rust क्रेट्स बिल्ड करता है |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | डेस्कटॉप UI |
| CMake ≥ 3.21 | Qt UI बिल्ड करता है |
| `pkg-config` | बिल्ड के समय `libusb-1.0` का पता लगाता है |
| `libusb-1.0-0-dev` (dev हेडर) | RGB HID बैकएंड, बिल्ड टाइम पर स्थिर रूप से लिंक |
| `libudev-dev` | हार्डवेयर/डिवाइस एन्युमरेशन |
| `systemd`, `polkit`, `dbus` (रनटाइम) | डेमन सेवा, विशेषाधिकार पृथक्करण, IPC |
| `libusb-1.0-0` (रनटाइम) | RGB HID बैकएंड के लिए रनटाइम निर्भरता |

```bash
# Debian/Ubuntu (CI से मेल खाता है)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**मुख्य Rust क्रेट्स** — `zbus` (D-Bus), `serde`/`serde_json` (डेटा
और डिवाइस प्रोफ़ाइल), `hidapi` (MysticLight RGB के लिए स्थिर रूप से
लिंक किया गया `linux-static-libusb` बैकएंड — यदि आपके डिस्ट्रो का
`hidapi` पैकेज लिंकर एरर देता है तो
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
देखें)। पूरा डिपेंडेंसी ग्राफ़ `Cargo.lock` और हर क्रेट के
`Cargo.toml` में है।

**उपयोग किए गए कर्नेल मॉड्यूल** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(EC सिमेंटिक स्थिति, फैन मोड, Cooler Boost, Super Battery, वेबकैम/
Fn key), `msi_wmi_platform`/hwmon (वास्तविक फैन RPM), Linux का
`power_supply` (बैटरी स्थिति और चार्ज थ्रेशोल्ड)।

**विकास के दौरान संदर्भित प्रोजेक्ट** — केवल शोध/संदर्भ सामग्री;
इनमें से कुछ भी शामिल या लिंक नहीं किया गया है, और हर राइट पथ को
शिप करने से पहले स्वतंत्र रूप से सत्यापित किया गया है (देखें
[सुरक्षा मॉडल](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| प्रोजेक्ट | उपयोग किया गया |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSI मॉडल/फर्मवेयर ज्ञान, EC रजिस्टर शोध, फैन कर्व्स, सत्यापन पद्धति |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux पर MSI-विशिष्ट EC/sysfs सिमेंटिक्स, मोड, Cooler Boost, तापमान, फैन लेवल और समर्थित मॉडल |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | Linux पर MSI लैपटॉप फीचर/UX व्यवहार तुलना |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | विशेषाधिकार पृथक्करण, Polkit दृष्टिकोण, फैन नियंत्रण, फ़िक्सचर/रोलबैक |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana Mystic Light USB/HID प्रोटोकॉल और 4-ज़ोन RGB शोध |
| [Linux कर्नेल](https://github.com/torvalds/linux) | hwmon, power_supply, WMI, ACPI, HID, DRM, और प्लेटफ़ॉर्म ड्राइवर सिमेंटिक्स के लिए सर्वोच्च-प्राथमिकता व्यवहारिक संदर्भ |

## अस्वीकरण — अपने जोखिम पर उपयोग करें

यह सॉफ़्टवेयर एम्बेडेड कंट्रोलर (EC), बैटरी चार्जिंग इंटरफ़ेस, और
USB HID के माध्यम से RGB कंट्रोलर सहित लैपटॉप हार्डवेयर को नियंत्रित
करता है। इन इंटरफ़ेस पर गलत राइट्स के परिणामस्वरूप अस्थिरता, थर्मल
समस्याएँ, बैटरी जीवन में कमी, डेटा हानि, या हार्डवेयर/फर्मवेयर की
क्षति हो सकती है।

**यह प्रोजेक्ट "जैसा है वैसा" प्रदान किया जाता है, बिना किसी प्रकार
की वारंटी के, चाहे वह स्पष्ट हो या निहित। लेखक और योगदानकर्ता इस
सॉफ़्टवेयर के उपयोग से होने वाली किसी भी क्षति, डेटा हानि, या
खराबी के लिए ज़िम्मेदार नहीं हैं — जिसमें आपके लैपटॉप, बैटरी,
कीबोर्ड, या किसी अन्य हार्डवेयर को होने वाली क्षति शामिल है।**

प्रोजेक्ट में निर्मित शमन उपाय (फर्मवेयर सुरक्षा, प्रति-फीचर opt-in,
Polkit प्राधिकरण, रीड-बैक सत्यापन, संदर्भ हार्डवेयर पर वास्तविक
सत्यापन) जोखिम को कम करते हैं लेकिन समाप्त नहीं करते। ये सर्वोत्तम-
प्रयास इंजीनियरिंग उपाय हैं, गारंटी नहीं।

- बैटरी थ्रेशोल्ड, फैन मोड, Cooler Boost, RGB, वेबकैम, वेबकैम
  ब्लॉक, और fn-key राइट्स इंस्टॉल किए गए systemd यूनिट में
  **डिफ़ॉल्ट रूप से** सक्षम हैं (Super Battery और नॉन-वोलेटाइल RGB
  सेव अक्षम रहते हैं); इन्हें तभी इंस्टॉल करें जब आप समझते हों कि वे
  क्या करते हैं, और यदि आप पूरी तरह रीड-ओनली डिफ़ॉल्ट चाहते हैं तो
  इंस्टॉल करने से पहले यूनिट फ़ाइल संपादित करें
- व्यवहार केवल **MSI Katana 17 B13VGK** (फर्मवेयर `17L5EMS1.115`)
  पर वास्तविक-सत्यापित है; अन्य मॉडल सुरक्षित हैं लेकिन असत्यापित
  हैं
- इस सॉफ़्टवेयर का उपयोग ऐसे लैपटॉप पर न करें जिसकी क्षति आप वहन
  नहीं कर सकते, और संवेदनशील हार्डवेयर पर कभी भी राइट फीचर्स सक्षम
  न करें
- यदि अनिश्चित हों, तो केवल रीड-ओनली टेलीमेट्री फीचर्स तक सीमित
  रहें

**सावधान रहें। इस सॉफ़्टवेयर के उपयोग के किसी भी परिणाम के लिए आप
अकेले ज़िम्मेदार हैं।**

## योगदान

पहले [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) पढ़ें।
हार्डवेयर राइट पथों के लिए स्रोत दस्तावेज़ीकरण, गार्ड्स, और वास्तविक
सत्यापन लॉग आवश्यक हैं — इन्हें छोड़ने वाले PR मर्ज नहीं किए जाएँगे।

## लाइसेंस

आपकी पसंद पर, [MIT](LICENSE-MIT) या
[Apache-2.0](LICENSE-APACHE) के तहत दोहरे-लाइसेंस प्राप्त।
