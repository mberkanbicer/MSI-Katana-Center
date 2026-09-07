# Reverse-engineering inventory (Katana 17 B13VGK / 17L5EMS1.115)

Sources: local `msi-ec` 0.13 `CONF_G2_10`, GhostDeck `data/models.json` model
“Pulse/Katana 17 B13V/GK”, MControlCenter feature matrix, live sysfs on
2026-09-07.

| Feature | Source | This EC | Project |
|---|---|---|---|
| Battery thresholds | msi-ec / power_supply | yes | writes verified |
| Fan mode auto/silent/advanced | msi-ec `0xd4` | yes | writes verified |
| Cooler Boost | msi-ec `0x98` | yes | writes verified |
| Super Battery | msi-ec `0xeb` | yes | writes verified |
| Shift / performance mode | msi-ec `0xd2` / GhostDeck recipes | `0xc0` current, driver cannot write `0xc0`; sources disagree whether that byte is sport-default or turbo-like | **deferred** — `docs/deferred-features-research.md` §1 |
| Custom fan curve | GhostDeck / MControlCenter `ec_sys` | tables live at `0x69`/`0x72`; Silent power cap is `0xd4=0x1d` and cannot coexist with a curve | **deferred** (Phase 5 §11) |
| RGB 4-zone | USB HID / OpenRGB | yes | non-persistent writes verified |
| Webcam on/off | msi-ec `webcam` `0x2e` | live `on`, RW | writes verified |
| Webcam block | msi-ec `webcam_block` `0x2f` | live `off`, RW | writes verified |
| Fn/Win swap | msi-ec `fn_key`/`win_key` `0xe8` | Fn right / Win left, RW | writes verified |
| USB power share | MControlCenter `0xbf` | no `msi-ec` attr; `0xbf` is not fn/win on this EC | not present — research §3 |
| EC kbd backlight (`msiacpi::kbd_backlight`) | msi-ec LED class | `MSI_EC_ADDR_UNSUPP`; no LED node | RGB HID instead — research §4 |
| Mute/micmute LEDs | msi-ec LED class | present | kernel-owned; leave alone — research §5 |
| MUX | MSI Center MSHybrid; `msi-gpu-switcher` uses `0x2e` | `0x2e` is **webcam** on this firmware | Phase 10 — research §6 |

Writes use the same gates as Cooler Boost: exact firmware, Polkit, per-feature
opt-in, read-back, restore previous value on failure. No raw EC, no `ec_sys`.
