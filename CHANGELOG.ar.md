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
    <b>العربية</b> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *هذه ترجمة مقدمة من المجتمع. عند وجود أي تعارض، تُعد النسخة الإنجليزية `CHANGELOG.md` هي المرجع المعتمد.*

# سجل التغييرات

تُوثَّق جميع التغييرات الملحوظة في هذا المشروع في هذا الملف. ويتبع التنسيق [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) بشكل مرن، مع التجميع بحسب مرحلة التطوير بدلًا من زيادات الإصدار الدلالية الصارمة، لأن هذا المشروع يُشحن كلقطة متجددة جرى التحقق منها على جهاز مرجعي واحد (MSI Katana 17 B13VGK، والبرمجية الثابتة `17L5EMS1.115`).

## [Unreleased]

### تمت الإضافة
- ترجمات مجتمعية لملف `README.md` إلى 12 لغة (الصينية، والتركية، والألمانية، والفرنسية، والسويدية، والإيطالية، والبرتغالية، والإسبانية، والعربية، والهندية، واليابانية، والكورية) مع مبدّل للغات.
- صفحات مترجمة من ويكي GitHub وهذا السجل نفسه باللغات الاثنتي عشرة ذاتها.
- قسم `Dependencies` في `README.md` يوثّق حزم النظام المطلوبة، وأنظمة التشغيل المدعومة، ووحدات النواة، ومشروعات المرجع upstream.
- إشعار إفصاح عن التطوير بمساعدة الذكاء الاصطناعي ("vibecoded") في `README.md`.
- شارات Rust/Platform/Wiki وإعادة تنظيم تخطيط README.

### تم التغيير
- أصبحت كتابات حد البطارية، ووضع المروحة، وCooler Boost، وRGB، وwebcam، وwebcam block، ومفتاح Fn مفعّلة الآن **افتراضيًا** في وحدة systemd المثبتة (بينما يظل Super Battery والحفظ غير المتطاير لـ RGB في وضع opt-out).

### تم الإصلاح
- ربط `hidapi` ربطًا ثابتًا (`linux-static-libusb` backend) لإصلاح إخفاقات CI وأخطاء الرابط المرتبطة بإصدار التوزيعة عندما تكون حزمة النظام `hidapi` غير متوافقة.
- يقوم مسار CI بتثبيت `libhidapi-dev` لكي يُبنى crate `hidapi` بنجاح.
- جرى تصحيح رسالة رفض Polkit وإضافة تغطية لمسار فشل التراجع.

## [0.2.0] — 2026-09-06

### تمت الإضافة
- **Phase 9 — Community diagnostics**: الأمر `msicenter report` الذي ينتج حزمة تشخيص قابلة للمشاركة من دون أرقام تسلسلية.
- **Phase 8 — Scenes**: حزم مسماة من عمليات الكتابة المحمية، وأوامر CLI ‏`scene list|examples|apply`، ومشاهد مثال (quiet / cool / battery saver / gaming rgb)، وصفحة Scenes في UI سطح المكتب مع مشغلات أتمتة اختيارية (الإقلاع، والتبديل بين AC والبطارية، ومستوى البطارية، والجدولة).
- **Phase 7 — RGB (MysticLight MS-1565)**: فحص لوحدة تحكم HID للقراءة فقط، ومنشئ حزم للبروتوكول مع اختبارات وحدات، وعمليات كتابة محمية وغير مستمرة لـ `SetRgbColor` والتأثيرات (breathing وrainbow وwave)، و`rgb-save` غير متطاير ومحمي، وصفحة RGB للوحة المفاتيح في UI سطح المكتب.
- **Phase 6 — Qt/QML desktop UI**: عميل سطح مكتب كامل من سبع صفحات (Overview وCooling وPower وBattery وKeyboard RGB وScenes وDiagnostics) مع إعادة تصميم بأسلوب Material، وتنقل بالشريط الجانبي، وبطاقة حرارية بارزة، وعروض تفصيلية لكل نواة CPU ولكل GPU، وإجراءات سريعة ثابتة، وقوائم أتمتة قابلة للطي، وحالة اتصال/تحديث، وشريط toast للإجراءات المعلقة.
- تقارير درجات الحرارة/الأحمال لكل نواة CPU وتفاصيل كل GPU من الطرف إلى الطرف (core → daemon → UI).
- أيقونة علبة النظام مع تلميح مباشر لدرجات الحرارة/RPM، وإجراءات سريعة، واختصارات لوحة مفاتيح (Ctrl+Shift+C/B/L/P).

### تم التغيير
- جرى توحيد فحوصات حواجز الكتابة عبر معالجات الكتابة في daemon وإضافة اختبارات للتوافر.
- جرى تخفيف تثبيت إصدار `zbus`.

## [0.1.0] — 2026-09-05

### تمت الإضافة
- **Phase 0–2 — Read-only foundation**: اكتشاف العتاد، وأساس Rust للقراءة فقط، وقاعدة بيانات الأجهزة (`msi-device-db`)، والإبلاغ عن القدرات وقت التشغيل، وfixture بجذر نظام وهمي للتطوير والاختبار من دون عتاد (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: خدمة systemd ‏`msi-daemon`، وسياسة D-Bus، وإجراءات Polkit التي تحمي كل طريقة ذات امتيازات.
- **Phase 4 — Safe, gated writes**: مسارات كتابة لحد شحن البطارية، ووضع المروحة (auto/silent/advanced)، وCooler Boost، وSuper Battery، وكل منها محمي بمطابقة البرمجية الثابتة، ومتغير بيئة opt-in لكل ميزة، وتفويض Polkit، والتحقق عبر القراءة الرجعية مع التراجع عند الفشل. وقد جرى التحقق من مسارات الكتابة الأربعة فيزيائيًا على الجهاز المرجعي MSI Katana 17 B13VGK بتاريخ 2026-09-05.
- عميل سطر أوامر `msicenter-cli` ‏(`status` و`capabilities` والأوامر الفرعية المحمية الخاصة بالكتابة).
- قواعد السلامة في `MSI-Linux-Center-AGENTS.md` للمساهمين ووكلاء البرمجة بالذكاء الاصطناعي.
- دراسات تصميم للميزات المؤجلة: منحنيات مروحة مخصصة (Phase 5، تصميم فقط بانتظار اختبار تراجع جدول EC قائم على الموافقة) وتبديل GPU MUX ‏(بحث فقط).

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
