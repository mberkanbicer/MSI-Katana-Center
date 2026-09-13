<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — إدارة أصلية على لينكس، بأبواب أمان، للمراوح والبطارية وإضاءة RGB للوحة المفاتيح في أجهزة MSI المحمولة، تم التحقق منها على Katana 17 B13VGK">
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
    <b>العربية</b> ·
    <a href="README.hi.md">हिन्दी</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#التبعيات)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> هذا الملف ترجمة مقدَّمة من المجتمع. في حال وجود أي تعارض، يُعتمد
> [الملف بالإنجليزية](README.md).

أداة إدارة أجهزة مفتوحة المصدر وأصلية على لينكس لأجهزة MSI
المحمولة. تم تطويرها بالاعتماد على جهاز **MSI Katana 17 B13VGK**
(اللوحة MS-17L5، ثابت وحدة التحكم المدمجة EC `17L5EMS1.115`)
كجهاز مرجعي. نواة مكتوبة بلغة Rust، وخدمة خلفية عبر D-Bus، وعميل
سطح مكتب Qt/QML.

كل عملية كتابة على العتاد محمية بمطابقة إصدار الثابت، ومُصرَّح بها
عبر Polkit، وتتطلّب تفعيلاً صريحاً (opt-in) لكل ميزة على حدة، ويتم
التحقق منها بإعادة قراءة القيمة، ولا يتم تفعيلها إلا بعد التحقق
الفعلي على الجهاز المرجعي. تجد القواعد الكاملة في
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **إشعار بشأن التطوير بمساعدة الذكاء الاصطناعي:** هذا المشروع
> مكتوب بالكامل بواسطة الذكاء الاصطناعي ("vibecoded") — تمت كتابة
> كل إيداع (commit) بواسطة عميل برمجة ذكاء اصطناعي يعمل وفق القواعد
> الواردة في
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)، بينما
> تولّى إنسان تحديد النطاق ومراجعة التغييرات، واشترط موافقة صريحة
> على كل عملية كتابة على العتاد قبل تنفيذها على جهاز حقيقي. لم يتم
> إنشاء أي سطر برمجي أو وثيقة تصميم أو سجل تحقق فعلي دون هذه
> المراجعة البشرية. هذا لا يغيّر شيئاً من
> [إخلاء المسؤولية](#إخلاء-المسؤولية--الاستخدام-على-مسؤوليتك-الخاصة)
> أدناه: الاستخدام على مسؤوليتك الخاصة، ويُرجى قراءة آليات الأمان
> قبل تفعيل أي خيار كتابة.

## واجهة المستخدم أثناء العمل

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="نظرة عامة على النظام: درجات حرارة المعالج وكرت الشاشة، شحن البطارية، وضع المروحة، وسرعة الدوران الفعلية على جهاز Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="جولة في الصفحات: التبريد، الطاقة، البطارية، إضاءة RGB للوحة المفاتيح، المشاهد، والتشخيص">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="صفحة إضاءة RGB للوحة المفاتيح مع معاينة مناطق MysticLight MS-1565">
</p>

## ما هو هذا المشروع

تطبيق سطح مكتب (Center) وأداة سطر أوامر (CLI) تقرأ حالة وضع/مروحة
وحدة التحكم المدمجة، ودرجات الحرارة، وسرعة الدوران، وحالة البطارية
— وعند تفعيل الخيار (opt-in)، تطبّق مجموعة صغيرة من عمليات الكتابة
التي تم التحقق منها: حدود الشحن، وضع المروحة، Cooler Boost،
Super Battery، الكاميرا/مفاتيح Fn، وإضاءة MysticLight RGB.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="واجهة Qt/QML وأداة سطر الأوامر تتواصلان عبر D-Bus وPolkit مع msi-daemon، الذي يصل بدوره إلى msi-ec وhwmon وواجهة البطارية وإضاءة MysticLight RGB">
</p>

## الميزات

- **قياس عن بُعد للقراءة فقط** — أوضاع وحدة التحكم المدمجة/المروحة،
  درجات حرارة المعالج/كرت الشاشة، درجة الحرارة/الحمل لكل نواة،
  درجة الحرارة/الحمل لكل كرت شاشة، مستويات المروحة والسرعة
  الفعلية، حالة البطارية وحدود الشحن، تقارير القدرات وقت التشغيل
- **عمليات كتابة محمية ومُتحقَّق منها** — حدود شحن البطارية، وضع
  المروحة، Cooler Boost، Super Battery، الكاميرا/حجب الكاميرا،
  تبديل مفتاحي Fn/Win
- **إضاءة RGB للوحة المفاتيح** — لون ثابت وتأثيرات MysticLight
  MS-1565 (التنفّس، الدوران، الموجة)، غير دائمة افتراضياً؛ الحفظ في
  الذاكرة الدائمة يتطلب تفعيلاً منفصلاً
- **المشاهد (Scenes)** — حزم مسمّاة من عمليات الكتابة المحمية، مع
  تطبيق/استيراد/تصدير عبر سطر الأوامر والواجهة، أمثلة جاهزة (هادئ /
  بارد / توفير البطارية / إضاءة الألعاب)، أتمتة اختيارية عند
  الإقلاع/التبديل بين الكهرباء والبطارية/مستوى البطارية/الجدولة
  (كلها اختيارية وتُدار بالكامل من الواجهة)
- **أيقونة شريط النظام** — تلميح مباشر لدرجات الحرارة والسرعة،
  إجراءات سريعة، اختصارات لوحة المفاتيح (Ctrl+Shift+C/B/L/P)
- **واجهة سطح المكتب** — سبع صفحات (نظرة عامة، التبريد، الطاقة،
  البطارية، إضاءة RGB للوحة المفاتيح، المشاهد، التشخيص) مع بطاقة
  حرارية رئيسية، إجراءات أساسية ثابتة، قائمة أتمتة المشاهد
  القابلة للطي، حالة الاتصال/التحديث، وشريط إشعار للإجراءات
  المنتظرة
- **تشخيص مجتمعي** — أمر `msicenter report` بدون أي أرقام تسلسلية
  لطلبات الدعم لدى المشاريع الأصلية
- **بيئة اختبار وهمية (Fake sysroot)** — تطوير واختبار بدون عتاد
  فعلي عبر `MSI_LINUX_CENTER_SYSROOT`

## التثبيت

يبني الإصدار النهائي من الخدمة الخلفية وأداة سطر الأوامر وواجهة
Qt، ثم يُثبّت systemd وPolkit وسياسة D-Bus وملف سطح المكتب،
و(افتراضياً) التشغيل التلقائي عند بدء الجلسة. تُفعّل وحدة systemd
المرفقة افتراضياً خيارات الكتابة الخاصة بالبطارية ووضع المروحة
وCooler Boost وRGB والكاميرا وحجب الكاميرا ومفتاح fn؛ بينما تبقى
Super Battery وحفظ RGB في الذاكرة الدائمة معطَّلتين. وبغض النظر عن
هذه الإعدادات الافتراضية، تظل كل عملية كتابة محمية بواسطة Polkit
داخل الخدمة الخلفية، ومطابقة تماماً لإصدار الثابت، ويتم التحقق منها
بإعادة القراءة/التراجع — عدّل ملف
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
قبل التثبيت إذا أردت إعداداً افتراضياً للقراءة فقط بالكامل.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

لا يحذف أمر `uninstall` مجلد `~/.config/msi-linux-center`. المسار
الافتراضي هو `/usr` (يمكن تغييره عبر `PREFIX` وَ `SYSCONFDIR`).

### المتطلبات

- سلسلة أدوات Rust (≥ 1.75)
- Qt 6 (Core وQML وQuick وDBus وQuickControls2 وWidgets) +
  CMake ≥ 3.21
- لينكس مع وحدتي النواة `msi-ec` وَ `msi_wmi_platform` للعمل على
  عتاد حقيقي (يتراجع كل من مسار القراءة والكتابة بأسلوب آمن في حال
  غيابهما)

راجع قسم [التبعيات](#التبعيات) أدناه لمعرفة حزم النظام الدقيقة
وأنظمة التشغيل المدعومة.

### البناء من الشيفرة المصدرية

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## التشغيل

مقابل بيئة الاختبار المرفقة (لا حاجة لعتاد فعلي):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

للقراءة فقط على الجهاز المحمول الحقيقي:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

**لا تُشغِّل** أداة سطر الأوامر باستخدام sudo. تُنفَّذ عمليات
الكتابة ذات الصلاحيات فقط من قِبل الخدمة الخلفية بعد الحصول على
تصريح Polkit.

## أوامر الكتابة (المحمية)

يتطلّب كل أمر أن تعمل الخدمة الخلفية مع خيار التفعيل المطابق
(`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) وأن يُستكمل طلب تصريح
Polkit:

```bash
msicenter battery-thresholds START END      # مثال: 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # غير دائم
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # حفظ دائم في الذاكرة (خيار تفعيل منفصل)
msicenter panic-reset                       # إيقاف Cooler Boost، إيقاف Super Battery، عودة المروحة للوضع التلقائي
msicenter scene list|examples|apply NAME
```

عند تعطيل خيار التفعيل، ترفض الخدمة الخلفية الطلب برسالة
`NotSupported`. يمكن الاطلاع على نطاق الدعم الدقيق والحمايات
وسجلات التحقق الفعلي في
[`docs/dbus-contract.md`](docs/dbus-contract.md) وملفات
`docs/phase4-*-validation.md`.

## نموذج الأمان

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="ستة أبواب حماية للكتابة: مطابقة الثابت، التفعيل الاختياري، Polkit، إعادة القراءة، التحقق الفعلي على Katana 17 B13VGK، وعدم الكتابة في سجلات غير موثقة">
</p>

1. **بوابة الثابت (Firmware)** — لا تُنفَّذ عمليات الكتابة إلا عندما
   يطابق ثابت وحدة التحكم المدمجة تماماً سلسلة ثابت تم التحقق منها
   فعلياً
2. **بوابة التفعيل الاختياري** — تعتمد كل فئة من عمليات الكتابة على
   متغيّر بيئة خاص بها في الخدمة الخلفية؛ تُفعّل وحدة systemd
   المرفقة افتراضياً البطارية ووضع المروحة وCooler Boost وRGB
   والكاميرا وحجب الكاميرا ومفتاح fn (بينما تبقى Super Battery
   وحفظ RGB في الذاكرة الدائمة معطَّلتين)
3. **بوابة Polkit** — تُطابَق كل طريقة كتابة عبر D-Bus بإجراء Polkit
4. **التحقق بإعادة القراءة** — يتم إعادة قراءة عمليات الكتابة
   الخاصة بوحدة التحكم المدمجة والبطارية والتحقق منها؛ ويتم التراجع
   عن عمليات الكتابة الفاشلة
5. **التحقق الفعلي** — لا يُطرَح أي مسار كتابة إلا بعد اختباره على
   الجهاز المرجعي وتوثيقه في `docs/`
6. **لا تخمين إطلاقاً** — لا تتم الكتابة أبداً في سجلات غير موثقة؛
   يُسجَّل مصدر كل ميزة عتاد في ملف تعريف الجهاز

## الأجهزة المدعومة

| الجهاز | الحالة |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5، الثابت `17L5EMS1.115`) | جهاز مرجعي تم التحقق منه |
| أجهزة MSI المحمولة الأخرى التي تدعم `msi-ec` | قياس عن بُعد للقراءة فقط؛ عمليات الكتابة محمية بمطابقة تامة للثابت |
| الطُّرز غير المطابقة | قراءة فقط + تقرير تشخيصي؛ دعم مجتمعي عبر `msicenter report` |

<details>
<summary>حالة المراحل</summary>

| المرحلة | النطاق | الحالة |
|---|---|---|
| 0 | استكشاف العتاد للقراءة فقط | مكتملة |
| 1–2 | النواة للقراءة فقط، قاعدة بيانات الأجهزة، قدرات وقت التشغيل، بيئة الاختبار | مكتملة |
| 3 | خدمة D-Bus الخلفية، وحدة systemd، سياسة D-Bus، إجراءات Polkit | مكتملة |
| 4 | عمليات كتابة دلالية محمية (حدود البطارية، وضع المروحة، Cooler Boost، Super Battery) | مكتملة — تم التحقق منها فعلياً في 2026-09-05 |
| 5 | منحنيات مروحة مخصصة | [دراسة تصميم](docs/phase5-fan-curve-design.md) — لا كتابة قبل إتمام تجربة §11 |
| 6 | واجهة سطح مكتب Qt/QML | مكتملة — [التصميم](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | تم التحقق فعلياً من `SetRgbColor`؛ أوضاع التأثيرات مطبَّقة؛ الحفظ في الذاكرة الدائمة مطبَّق وينتظر الاختبار الفعلي |
| 8 | المشاهد | مكتملة — تم التحقق من سطر الأوامر والواجهة |
| 9 | التشخيص المجتمعي | مكتملة — [التصميم](docs/phase9-diagnostics.md) |
| 10 | تبديل كرت الشاشة (MUX) | بحث فقط — [ملاحظات](docs/deferred-features-research.md) |

</details>

## التوثيق

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — عقد واجهة برمجة D-Bus
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — بروتوكول MysticLight
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — جرد الهندسة العكسية
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — قواعد الأمان للمساهمين والعملاء الآليين
- [ويكي المشروع](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — التثبيت ونموذج الأمان وواجهة D-Bus والأسئلة الشائعة بصيغة قابلة للتصفح

## التبعيات

**أنظمة التشغيل المدعومة** — لينكس فقط. تم التطوير والاختبار على
Arch Linux وUbuntu (يعمل CI على `ubuntu-latest`)؛ من المفترض أن
يعمل أي توزيع يحتوي على `systemd` وPolkit وD-Bus وQt 6 وسلسلة أدوات
Rust حديثة. وحدتا النواة `msi-ec` وَ `msi_wmi_platform` مطلوبتان
لقياس/كتابة العتاد الحقيقي — يظل المشروع قابلاً للبناء والعمل
للقراءة فقط عبر بيئة الاختبار حتى بدونهما.

**حزم النظام الأساسية**

| الحزمة | الغرض |
|---|---|
| سلسلة أدوات Rust ≥ 1.75 (`cargo`) | بناء جميع حزم Rust |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | واجهة سطح المكتب |
| CMake ≥ 3.21 | بناء واجهة Qt |
| `pkg-config` | تحديد موقع `libusb-1.0` أثناء البناء |
| `libusb-1.0-0-dev` (رؤوس التطوير) | خلفية RGB HID، مرتبطة ارتباطاً ثابتاً وقت البناء |
| `libudev-dev` | تعداد العتاد/الأجهزة |
| `systemd`, `polkit`, `dbus` (وقت التشغيل) | خدمة الخلفية، حماية الصلاحيات، الاتصال بين العمليات |
| `libusb-1.0-0` (وقت التشغيل) | تبعية وقت تشغيل لخلفية RGB HID |

```bash
# ‏Debian/Ubuntu (مطابق لـ CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**حزم Rust الأساسية** — `zbus` (D-Bus)، `serde`/`serde_json`
(البيانات وملفات تعريف الأجهزة)، `hidapi` (خلفية `linux-static-libusb`
المرتبطة ثابتاً لإضاءة MysticLight RGB — راجع
[الأسئلة الشائعة](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
إذا تسببت حزمة `hidapi` الخاصة بتوزيعتك في أخطاء ربط). الرسم
البياني الكامل للتبعيات موجود في `Cargo.lock` وملف `Cargo.toml`
الخاص بكل حزمة.

**وحدات النواة المستخدمة** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(الحالة الدلالية لوحدة التحكم المدمجة، أوضاع المروحة، Cooler Boost،
Super Battery، الكاميرا/مفتاح Fn)، `msi_wmi_platform`/hwmon (سرعة
دوران المروحة الفعلية)، `power_supply` الخاص بلينكس (حالة البطارية
وحدود الشحن).

**المشاريع المرجعية أثناء التطوير** — مادة بحثية/مرجعية فقط؛ لم يتم
تضمين أو ربط أي شيء منها، وتم التحقق من كل مسار كتابة بشكل مستقل
قبل إطلاقه (راجع
[نموذج الأمان](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| المشروع | استُخدم من أجل |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | معرفة طُرز/ثوابت MSI، بحث سجلات وحدة التحكم المدمجة، منحنيات المروحة، منهجية التحقق |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | دلالات EC/sysfs الخاصة بـ MSI على لينكس، الأوضاع، Cooler Boost، درجات الحرارة، مستويات المروحة والطُّرز المدعومة |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | مقارنة سلوك ميزات/تجربة المستخدم لأجهزة MSI على لينكس |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | فصل الصلاحيات، مفاهيم Polkit، التحكم بالمروحة، المحاكاة والاستعادة |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | بروتوكول USB/HID الخاص بـ Katana Mystic Light وبحث RGB بأربع مناطق |
| [نواة لينكس](https://github.com/torvalds/linux) | المرجع التنفيذي الأعلى أولوية لـ hwmon وpower_supply وWMI وACPI وHID وDRM وتعريفات المنصة |

## إخلاء المسؤولية — الاستخدام على مسؤوليتك الخاصة

يتحكم هذا البرنامج في عتاد الجهاز المحمول عبر وحدة التحكم المدمجة
(EC)، وواجهات شحن البطارية، ووحدة تحكم RGB عبر USB HID. قد تؤدي
عمليات الكتابة الخاطئة على هذه الواجهات إلى عدم استقرار، أو مشاكل
حرارية، أو تقليل عمر البطارية، أو فقدان بيانات، أو تلف في العتاد/
الثابت.

**يُقدَّم هذا المشروع "كما هو" دون أي ضمان من أي نوع، صريحاً كان أم
ضمنياً. لا يتحمّل المؤلفون والمساهمون أي مسؤولية عن أي ضرر أو فقدان
بيانات أو عطل ناتج عن استخدام هذا البرنامج — بما في ذلك الضرر الذي
يلحق بجهازك المحمول أو بطاريتك أو لوحة مفاتيحك أو أي عتاد آخر.**

تُقلّل إجراءات التخفيف المدمجة في المشروع (حماية الثابت، التفعيل
الاختياري لكل ميزة، تصريح Polkit، التحقق بإعادة القراءة، التحقق
الفعلي على الجهاز المرجعي) من المخاطر لكنها لا تلغيها. إنها إجراءات
هندسية مبذول فيها أقصى جهد، وليست ضمانات.

- تُفعَّل عمليات كتابة حدود البطارية ووضع المروحة وCooler Boost
  وRGB والكاميرا وحجب الكاميرا ومفتاح Fn **افتراضياً** في وحدة
  systemd المثبَّتة (بينما تبقى Super Battery وحفظ RGB في الذاكرة
  الدائمة معطَّلتين)؛ لا تُثبِّتها إلا إذا كنت تفهم وظيفتها، وعدّل
  ملف الوحدة قبل التثبيت إذا أردت إعداداً افتراضياً للقراءة فقط
  بالكامل
- تم التحقق من السلوك فعلياً فقط على جهاز **MSI Katana 17 B13VGK**
  (الثابت `17L5EMS1.115`)؛ أما الطُّرز الأخرى فمحمية لكن غير
  مُتحقَّق منها
- لا تستخدم هذا البرنامج على جهاز محمول لا يمكنك تحمّل تلفه، ولا
  تُفعِّل أبداً خيارات الكتابة على عتاد حسّاس
- إذا لم تكن متأكداً، اقتصر على استخدام ميزات القياس عن بُعد
  للقراءة فقط

**كن حذراً. أنت وحدك المسؤول عن أي عواقب لاستخدام هذا البرنامج.**

## المساهمة

اقرأ أولاً
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md). تتطلّب
مسارات الكتابة على العتاد توثيق المصدر، والحماية، وسجلات التحقق
الفعلي — لن يتم دمج طلبات السحب (PR) التي تتجاهل ذلك.

## الترخيص

مرخَّص بترخيص مزدوج بموجب [MIT](LICENSE-MIT) أو
[Apache-2.0](LICENSE-APACHE)، حسب اختيارك.
