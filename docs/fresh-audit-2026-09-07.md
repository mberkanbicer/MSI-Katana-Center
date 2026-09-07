# Fresh audit — 2026-09-07

Denetlenen commit: `723d70b62b0b84b815fda25527c162639622782e`. Başlangıç çalışma ağacı temizdi. Bulgular güncel kaynak kod ve bu oturumda çalıştırılan kontrollerden çıkarıldı.

**Sonuç: 7 bulgu — 1 P1, 5 P2, 1 P3.** Rust testleri ve Qt derlemesi geçiyor; arayüzde eşzamanlı işlem yanıtlarının sahipliği ve sahne doğrulaması sorunlu. Clippy kabul kontrolü başarısız.

## Kapsam ve sınırlar

- Amaç: Rust çekirdek, cihaz veritabanı, donanım katmanı, D-Bus daemon, CLI, Qt istemci, QML çağrı noktaları ve kurulum dosyalarını doğruluk/güvenlik açısından incelemek.
- Kabul ölçütü: somut tetikleyici, kaynak konumu, etkisi ve doğrulama düzeyi bulunan öncelikli rapor.
- Kapsam dışı: hata düzeltme, refaktör, yeni özellik, bağımlılık yükseltme, kurulum/kaldırma ve gerçek donanıma yazma.
- Kaynak kod, mevcut testler, cihaz profili ve sistem yapılandırması değiştirilmedi. Depoya yalnızca bu rapor eklendi. Geçici doğrulama programı ve temiz Qt derlemesi `/tmp` altında.
- Gerçek Polkit etkileşimi, fiziksel RGB/EC davranışı, masaüstü görsel etkileşimleri ve bağımlılıkların güncel CVE durumu bu denetimde doğrulanmadı. Güvenlik açığı bulunmadığı garantisi verilmez.

## Bulgular

### 1. P1 — Yazma yanıtları istekleriyle eşleştirilmiyor; sahne ve Travel durumu bozulabiliyor

**Konum:** [centerclient.cpp:1270](../crates/msicenter-ui/src/centerclient.cpp#L1270), [1591](../crates/msicenter-ui/src/centerclient.cpp#L1591), [1248](../crates/msicenter-ui/src/centerclient.cpp#L1248).

`runNextSceneStep()` tek bir `m_actionCallback` atıyor. `handleAction()` herhangi bir yazma yanıtı geldiğinde bu callback'i tüketiyor; yanıtın beklenen sahne isteğine ait olduğunu kontrol etmiyor. Sahne sürerken otomatik Cooler Boost kapatma, tray komutu veya başka bir ayar isteği yanıt verirse onun sonucu sahne adımına yazılabiliyor. Sahne sırası ve başarı/başarısızlık raporu güvenilirliğini kaybediyor.

Aynı istek sahipliği eksikliği Travel için de var: `m_travelArming` ve `m_travelRestoreInFlight` tüm `SetBatteryThresholds` yanıtlarına uygulanıyor. Örneğin 60/80 geri yüklemesi beklenirken önceki 80/100 isteğinin başarılı yanıtı gelirse `clearTravel()` geri alma kaydını siliyor; gerçek geri yükleme daha sonra başarısız olabilir. Batarya sayfasındaki düğmeler bekleyen Travel isteğine göre kilitlenmiyor; otomasyon da bağımsız istek üretebiliyor.

**Kanıt:** Güncel C++ kaynak kodunu kullanan donanımsız programda `unrelated_reply_consumed_scene_callback=1` ve `unrelated_battery_reply_cleared_travel=1`. Bunlar doğrudan yanıt işleyiciye sentetik yanıt verilerek doğrulandı; gerçek D-Bus zamanlaması çalıştırılmadı.

**En küçük düzeltme:** Tamamlama callback'ini ilgili `QDBusPendingCallWatcher` ile taşı; Travel durum geçişlerini de onları başlatan isteğin tamamlanmasına bağla. Yalnızca metot adı yeterli değil: aynı metottan birden fazla istek bekleyebilir.

### 2. P2 — CLI toplu komutları tüm adımlar başarısız olsa bile başarılı çıkıyor

**Konum:** [main.rs:295](../crates/msicenter-cli/src/main.rs#L295), [298](../crates/msicenter-cli/src/main.rs#L298), [307](../crates/msicenter-cli/src/main.rs#L307).

`report_step()` hatayı yazdırıp yutuyor; `scene_apply()` ve `panic_reset()` koşulsuz `Ok(())` döndürüyor. Shell betiği veya otomasyon, hiçbir ayar uygulanmamışken çıkış kodu `0` alıyor. Özellikle `panic-reset` kullanan bir kurtarma betiği başarısızlığı algılayamıyor.

**Kanıt:** `DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/msicenter-audit-nonexistent-bus` ile `msicenter panic-reset` çalıştırıldı. Üç adım da `FAIL ... No such file or directory` yazdı, süreç `0` döndü. Bu adres gerçek sistem bus'ına bağlanmadığından donanıma yazılmadı. Sahne komutu aynı hata yutan yardımcıyı kullanıyor.

**En küçük düzeltme:** Adımların sonucunu topla; diğer adımları denemeye devam et, en az bir hata varsa komut sonunda `Err` döndür.

### 3. P2 — Qt sahne doğrulaması CLI sözleşmesinden sapmış

**Konum:** [centerclient.cpp:1747](../crates/msicenter-ui/src/centerclient.cpp#L1747), [1756](../crates/msicenter-ui/src/centerclient.cpp#L1756), [1777](../crates/msicenter-ui/src/centerclient.cpp#L1777), [1506](../crates/msicenter-ui/src/centerclient.cpp#L1506). CLI karşılığı: [scene.rs:32](../crates/msicenter-cli/src/scene.rs#L32), [139](../crates/msicenter-cli/src/scene.rs#L139).

Qt içe aktarımındaki izinli anahtar listesinde `webcam`, `webcam_block` ve `fn_key` yok. CLI ve Qt sahne yürütücüsü bunları desteklediği halde bu alanları içeren geçerli sahneler GUI'den içe aktarılamıyor. Dışa aktarılmış mevcut bir sahne de aynı nedenle geri alınamayabilir.

Ters yönde, yalnızca `battery_start: 80` içeren eksik çift Qt doğrulamasından geçiyor. Yürütücü bu ayarı sessizce atlıyor; tek ayarlı sahne `0 ok, 0 failed` ile başarılı sayılıyor. CLI aynı girdiyi reddediyor. RGB mod/hız/yön doğrulaması da Qt import yolunda eksik; yüklenen dosyalar `reloadScenes()` içinde ayrıca doğrulanmıyor.

**Kanıt:** C++ doğrulayıcı geçerli çevre birimi sahnesine `scene 1: unknown settings key 'fn_key'` döndürdü. Eksik batarya çifti için `incomplete_battery_accepted=1 generated_steps=0` üretildi.

**En küçük düzeltme:** Mevcut Qt doğrulayıcıyı CLI'nin anahtar, tür ve değer kurallarıyla eşleştir; sahneyi yürütmeden önce doğrula ve geçersiz ayarı sessizce atlama. Yeni bir şema altyapısı gerekmiyor.

### 4. P2 — Gece yarısını aşan zamanlama yanlış günle eşleşiyor

**Konum:** [centerclient.cpp:234](../crates/msicenter-ui/src/centerclient.cpp#L234), [824](../crates/msicenter-ui/src/centerclient.cpp#L824).

Saat aralığı gece yarısını destekliyor, fakat gün maskesi daima mevcut takvim gününden seçiliyor. Yalnızca pazartesi için 22:00–06:00 tanımlanınca pazartesi 01:00 eşleşiyor, pazartesi gecesinin devamı olan salı 01:00 eşleşmiyor. Uygulama o saatte açılırsa gece sahnesi uygulanmıyor; yanlış erken saatlerde açılırsa uygulanıyor. README geceyi aşan aralıkları desteklenen özellik olarak tanımlıyor.

**Kanıt:** Gerçek `matchingScheduleRule()` çağrıları: `overnight_mon_01=0 mon_23=0 tue_01=-1` (`0`: eşleşen kural; `-1`: eşleşme yok).

**En küçük düzeltme:** Geceyi aşan aralıkta bitiş saatinden önceki bölümü önceki günün maskesiyle değerlendir.

### 5. P2 — Geçici daemon hatası arayüzde kalıcı kalıyor

**Konum:** [centerclient.cpp:108](../crates/msicenter-ui/src/centerclient.cpp#L108), [130](../crates/msicenter-ui/src/centerclient.cpp#L130), [Main.qml:72](../crates/msicenter-ui/qml/Main.qml#L72).

`m_error` bağlantı, D-Bus veya JSON hatasında atanıyor; başarılı yenileme sonrasında temizlenmiyor. Daemon yeniden başlatıldıktan sonra veriler güncellense bile üstteki durum göstergesi hatalı kalıyor. Kullanıcı gerçek bağlantı durumunu ayırt edemiyor.

**Kanıt:** Başarılı `handleJson("SupportTier", "\"verified\"")` sonrasında `successful_read_retains_error=1`. Dosyadaki tüm `m_error` atamalarında temizleme yolu bulunmuyor.

**En küçük düzeltme:** Hatasız tamamlanan yenileme turunda eski hatayı temizle; tek bir başarılı property yanıtının aynı turdaki başka bir hatayı gizlemesine izin verme.

### 6. P2 — Fixture/sysroot modu RGB tarafında gerçek host'a erişiyor

**Konum:** [lib.rs:253](../crates/msi-dbus/src/lib.rs#L253), [272](../crates/msi-dbus/src/lib.rs#L272), [rgb.rs:277](../crates/msi-hardware/src/rgb.rs#L277).

`collect_status_from(hw)` DMI/EC/batarya/USB varlığını verilen sysroot'tan okuyor, ardından sysroot bilgisini taşımayan `rgb_status(&matched_profile)` çağrısını yapıyor. Bu fonksiyon `HidApi::new()` üzerinden host HID aygıtlarını tarıyor ve eşleşen gerçek kontrolcüyü açıyor. Dolayısıyla eşleşen cihaz profiline sahip fixture çalıştırması donanımdan bağımsız değil; host donanımı ve erişim izinleri RGB sonucunu etkileyebiliyor. Fixture'da `backends.rgb_hid=false` iken host'tan kontrolcü adı/seri bilgisi gelmesi de mümkün.

**Kanıt düzeyi:** Güncel çağrı zincirinden statik olarak doğrulandı. İzinli fiziksel USB aygıtıyla sonuç farkı ayrıca denenmedi. Buradaki işlem prob/okuma; bu bulgu fixture komutunun RGB yazdığı iddiası değildir.

**En küçük düzeltme:** Sysroot gerçek `/` olmadığında canlı HID probunu çalıştırma; fixture RGB sonucunu fixture verisi veya boş durumla sınırla.

### 7. P3 — Zorunlu Clippy kontrolü başarısız

**Konum:** [lib.rs:633](../crates/msi-hardware/src/lib.rs#L633).

`allowed.iter().any(|candidate| *candidate == value)` ifadesi mevcut toolchain'de `clippy::manual_contains` uyarısı üretiyor. `-D warnings` nedeniyle workspace Clippy kontrolü çıkış kodu `101` ile duruyor. Bu bir çalışma zamanı hatası değil; proje kabul kontrolünü engelliyor.

**En küçük düzeltme:** `allowed.contains(&value)` kullan.

## Çalıştırılan kontroller

Ortam: Rust/Cargo `1.98.1`, Qt `6.11.2`.

| Kontrol | Sonuç |
|---|---|
| `cargo fmt --all -- --check` | Geçti |
| `cargo check --workspace --offline` | Geçti |
| `cargo test --workspace --offline` | 24 test geçti; 0 başarısız |
| `cargo clippy --workspace --all-targets --offline -- -D warnings` | Başarısız; bulgu 7 |
| `./scripts/run-fixture.sh` | Geçti |
| `./scripts/run-fixture.sh --json` | Geçti; JSON parse edildi |
| Yeni `/tmp` build dizininde CMake Release configure + build | Geçti |
| Üç shell betiğinde `bash -n` | Geçti |
| C++ kaynak koduyla sentetik yanıt/validasyon/zamanlama kontrolleri | Yukarıdaki kusurlar yeniden üretildi |
| Var olmayan bus adresiyle CLI `panic-reset` | Üç hata, yanlış çıkış kodu `0` |

Geçici C++ kaynak: `/tmp/msicenter-fresh-audit-20260907.cpp`; çalıştırılabilir dosya: `/tmp/msicenter-fresh-audit-20260907`. Gerçek `centerclient.cpp` doğrudan derlemeye dahil edildi; özel üyeler yalnızca bu geçici programda erişime açıldı. D-Bus adresi var olmayan bir sokete, kullanıcı ayar dizini `/tmp` altına yönlendirildi. Qt event loop başlatılmadı; yanıtlar sentetik verildi. Bu program kalıcı bir test altyapısı değildir; `/tmp` temizlenince kaybolabilir.

İncelenen daemon yazma yollarında Polkit çağrısı ve opt-in kapıları mevcut; EC/batarya yollarında tam firmware eşleşmesi aranıyor. Bunlar kaynak incelemesi ve mevcut gate testleriyle kontrol edildi. Fiziksel yazma/geri alma veya canlı Polkit başarı testi yapılmadı.

Önerilen düzeltme sırası: önce istek/yanıt sahipliği, sonra CLI hata aktarımı ve sahne doğrulaması; ardından zamanlama, bağlantı durumu ve fixture izolasyonu. Clippy düzeltmesi tek satır.
