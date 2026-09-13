<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <b>Türkçe</b> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
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

> *Bu dosya topluluk tarafından sağlanan bir çeviridir. Herhangi bir çelişki durumunda yetkili kaynak İngilizce `CHANGELOG.md` dosyasıdır.*

# Değişiklik Günlüğü

Bu dosya, projedeki tüm önemli değişiklikleri belgelendirir. Biçim, [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) yapısını gevşek biçimde izler; ancak bu proje tek bir referans cihaza (MSI Katana 17 B13VGK, ürün yazılımı `17L5EMS1.115`) karşı doğrulanan hareketli bir anlık görüntü olarak yayımlandığı için, gruplama katı semantik sürüm artışları yerine geliştirme fazlarına göredir.

## [Unreleased]

### Eklendi
- `README.md` için 12 dilde topluluk çevirileri (Çince, Türkçe, Almanca, Fransızca, İsveççe, İtalyanca, Portekizce, İspanyolca, Arapça, Hintçe, Japonca, Korece) ve bir dil değiştirici.
- GitHub wiki sayfalarının ve bu değişiklik günlüğünün aynı 12 dilde çevirileri.
- `README.md` içinde gerekli sistem paketlerini, desteklenen işletim sistemlerini, çekirdek modüllerini ve yukarı akış referans projelerini belgeleyen `Dependencies` bölümü.
- `README.md` içinde AI-assisted development ("vibecoded") açıklama bildirimi.
- Rust/Platform/Wiki rozetleri ve yeniden yapılandırılmış README düzeni.

### Değiştirildi
- Kurulu systemd unit içinde battery threshold, fan-mode, Cooler Boost, RGB, webcam, webcam block ve fn-key yazmaları artık varsayılan olarak **etkin** (Super Battery ve kalıcı olmayan RGB save opt-out olarak kalır).

### Düzeltildi
- Sistem `hidapi` paketinin uyumsuz olduğu durumlarda görülen CI başarısızlıklarını ve dağıtım sürümüne bağlı bağlayıcı hatalarını gidermek için `hidapi` statik bağlandı (`linux-static-libusb` backend).
- `hidapi` crate'inin temiz biçimde derlenmesi için CI iş akışı `libhidapi-dev` kurar.
- Polkit reddetme mesajı düzeltildi ve rollback başarısızlığı yolu için kapsam eklendi.

## [0.2.0] — 2026-09-06

### Eklendi
- **Phase 9 — Topluluk tanılaması**: seri numarası içermeyen, paylaşılabilir bir tanılama paketi üreten `msicenter report` komutu.
- **Phase 8 — Sahneler**: kapılı yazmaların adlandırılmış paketleri, `scene list|examples|apply` CLI komutları, örnek sahneler (quiet / cool / battery saver / gaming rgb) ve masaüstü UI içinde isteğe bağlı otomasyon tetikleyicileri (önyükleme, AC/batarya geçişi, batarya seviyesi, zamanlama) bulunan bir Scenes sayfası.
- **Phase 7 — RGB (MysticLight MS-1565)**: salt okunur HID denetleyici yoklaması, birim testli protokol paket oluşturucu, kapılı kalıcı olmayan `SetRgbColor` ve efekt yazmaları (breathing, rainbow, wave), kapılı kalıcı `rgb-save` ve masaüstü UI içinde bir klavye RGB sayfası.
- **Phase 6 — Qt/QML desktop UI**: Material tarzı yeniden tasarım, kenar çubuğu gezinmesi, öne çıkan termal kart, çekirdek başına CPU/GPU ayrıntı görünümleri, sabit hızlı işlemler, daraltılabilir otomasyon menüleri, bağlantı/yenileme durumu ve bekleyen işlemler için toast çubuğu içeren tam yedi sayfalı masaüstü istemcisi (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes, Diagnostics).
- Çekirdek başına CPU sıcaklık/yük ve GPU ayrıntı raporlamasının uçtan uca sunulması (core → daemon → UI).
- Canlı sıcaklık/RPM araç ipucu, hızlı işlemler ve klavye kısayolları (Ctrl+Shift+C/B/L/P) içeren sistem tepsisi simgesi.

### Değiştirildi
- Daemon yazma işleyicileri arasında yazma kapısı kontrolleri birleştirildi ve kullanılabilirlik testleri eklendi.
- `zbus` sürüm sabitlemesi gevşetildi.

## [0.1.0] — 2026-09-05

### Eklendi
- **Phase 0–2 — Salt okunur temel**: donanım keşfi, salt okunur Rust çekirdeği, cihaz veritabanı (`msi-device-db`), çalışma zamanı yetenek raporlaması ve donanımsız geliştirme/test için bir fake-sysroot fixture (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: `msi-daemon` systemd hizmeti, D-Bus policy ve her ayrıcalıklı yöntemi kapılayan Polkit actions.
- **Phase 4 — Güvenli, kapılı yazmalar**: pil şarj eşiği, fan modu (auto/silent/advanced), Cooler Boost ve Super Battery yazma yolları; her biri ürün yazılımı eşleşme kapısı, özellik bazlı opt-in ortam değişkeni, Polkit yetkilendirmesi ve başarısızlıkta rollback ile geri okuma doğrulamasıyla korunur. Dört yazma yolunun tamamı 2026-09-05 tarihinde MSI Katana 17 B13VGK referans cihazında fiziksel olarak doğrulandı.
- `msicenter-cli` komut satırı istemcisi (`status`, `capabilities` ve kapılı yazma alt komutları).
- Katkıcılar ve AI kodlama ajanları için `MSI-Linux-Center-AGENTS.md` güvenlik kuralları.
- Ertelenmiş özellikler için tasarım çalışmaları: custom fan curves (Phase 5, onay kapılı EC-table rollback deneyi tamamlanana kadar yalnızca tasarım) ve GPU MUX switching (yalnızca araştırma).

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
