# Fresh audit — 2026-09-07 (ikinci tur)

Denetlenen ağaç: `main` @ `723d70b` üstündeki işlenmemiş çalışma ağacı
(17 dosya değişikliği + 5 yeni QML bileşeni + önceki denetim raporu).
Önceki rapor: [`fresh-audit-2026-09-07.md`](fresh-audit-2026-09-07.md).

**Sonuç: 0 yeni bulgu. Önceki 7 bulgunun tamamı düzeltilmiş ve doğrulandı.**

## Kapsam ve sınırlar

- Amaç: birinci turdaki bulguların mevcut ağaçta durup durmadığını
  doğrulamak ve işlenmemiş değişiklikleri (yeni QML bileşenleri,
  CenterClient sahiplik düzeltmeleri, CLI hata aktarımı) yeniden incelemek.
- Kapsam dışı: gerçek donanıma yazma, canlı Polkit etkileşimi, görsel
  masaüstü testi, bağımlılık CVE taraması.

## Önceki bulguların durumu

| # | Bulgu | Durum | Kanıt |
|---|---|---|---|
| 1 | P1 — yazma yanıtlarının sahipliği | **Düzeltildi** | `handleAction` artık `requestId` + `ActionContext` (Scene/TravelArming/TravelRestore) ile yanıt sahipliğini doğruluyor; `m_sceneRequestId`, `m_travelRequestId` mevcut (centerclient.cpp ~1253-1326) |
| 2 | P2 — CLI toplu komut başarı çıkışı | **Düzeltildi** | Var olmayan bus adresiyle `panic-reset`: 3 FAIL + `EXIT=1` |
| 3 | P2 — Qt sahne doğrulaması CLI'den sapmış | **Düzeltildi** | `validateSceneEntry` izinli anahtar listesinde `webcam`, `webcam_block`, `fn_key` var; `battery_start`/`battery_end` birlikte-olum zorunlu ve sıralama kontrolü mevcut (centerclient.cpp 1795-1857) |
| 4 | P2 — geceyi aşan zamanlama yanlış gün | **Düzeltildi** | `matchingScheduleRule` geceyi aşan aralıkta `ruleBit = (bit + 6) % 7` ile önceki günün maskesini değerlendiriyor (centerclient.cpp 844-863) |
| 5 | P2 — geçici daemon hatası kalıcı | **Düzeltildi** | `fetchAll()` başında `m_error.clear()`; yanıt sahipliği `refreshGeneration` ile tur bazlı |
| 6 | P2 — fixture modunda canlı HID probu | **Düzeltildi** | `rgb_status` sysroot `/` değilse boş durum döndürüyor (msi-dbus/src/lib.rs 272-276) |
| 7 | P3 — Clippy `manual_contains` | **Düzeltildi** | `allowed.contains(&value)` (msi-hardware/src/lib.rs 633) |

## Çalıştırılan kontroller

Ortam: Rust `1.98.1`, Qt `6.11.2`.

| Kontrol | Sonuç |
|---|---|
| `cargo test --workspace` | Geçti |
| `cargo clippy --workspace --all-targets -- -D warnings` | Geçti |
| `./scripts/run-fixture.sh` | Geçti |
| CLI `panic-reset` var olmayan bus adresiyle | `EXIT=1` (doğru) |
| Temiz CMake Release build (`/tmp` altında) | Geçti |

## Notlar

- Daemon yazma yolları hâlâ katmanlı: per-feature env opt-in
  (`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) + tam firmware eşleşmesi +
  Polkit. Kaynak incelemesinde geri alma/kaplama bozulması görülmedi.
- İşlenmemiş değişiklik seti büyük (~975 satır, çoğunlukla UI); bu
  turdaki kontroller derleme + statik inceleme + CLI davranış
  doğrulamasıyla sınırlı. QML görsel etkileşimleri derleme dışında
  test edilmedi.
- Değişiklikler henüz commit edilmedi; kabul edilmesi durumunda tek
  bir "audit fixes" commit'i olarak işlemek makul.
