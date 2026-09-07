# Deferred features — research (Katana 17 B13VGK / EC `17L5EMS1.115`)

Date: 2026-09-07. Read-only. No new write paths.

This note is the evidence behind the “not taken” rows in
`docs/reverse-engineering-inventory.md`. It does not change the gates in
`MSI-Linux-Center-AGENTS.md`.

Live on this machine today:

| sysfs | value |
|---|---|
| `shift_mode` | `unknown (192)` = `0xc0` |
| `available_shift_modes` | `eco`, `comfort`, `turbo` |
| `fan_mode` | `auto` |
| `super_battery` | `off` |

`msi-ec` 0.13 `CONF_G2_10` (this firmware) maps `0xd2` as
`eco=0xc2`, `comfort=0xc1`, `turbo=0xc4` with the source comment
“turbo is sometimes `0xc0`”. `shift_mode_show` prints `unknown (N)` when the
byte is not in that table (`msi-ec.c`). `shift_mode_store` can only write
table names — it cannot write `0xc0`.

---

## 1. Shift / performance (`0xd2`)

A “User Scenario” in MSI Center is **not** one register. GhostDeck
(`docs/TECHNICAL.md` §17, tested on the same G2 family this board uses)
and MControlCenter (`src/operate.cpp` `setUserMode`) both compose:

| MSI Center label | `0xd2` shift | `0xd4` fan | `0xeb` super-batt |
|---|---|---|---|
| Silent | `0xc1` comfort | `0x1d` silent | `0x00` |
| Balanced | `0xc1` comfort | `0x0d` auto | `0x00` |
| Extreme | `0xc4` turbo | `0x0d` auto | `0x00` |
| Super Battery | `0xc2` eco | `0x0d` auto | `0x0f` |

GhostDeck’s signed entry for **this** laptop (Pulse/Katana 17 B13V/GK,
prefix `17L5EMS1`, tier Tested, issue #38) is exactly that recipe. It
never writes `0xc0`. Silent vs Balanced differ only in `0xd4`.

MControlCenter maps the same way, with two extra notes in code:

- `sport_mode` → UI **balanced** (comment `// ?`)
- `turbo_mode` → UI **performance** (comment `// sport on some devices?`)
- Silent = comfort + silent fan, not a distinct shift value

So the Linux `shift_mode` file is only the **power nibble**. The product
“scenario” also needs fan mode and Super Battery, which this project
already writes as separate, verified methods.

### 1.1 What is `0xc0` (192)?

Independent sources disagree. That disagreement is the reason writes stay
deferred.

| Claim | Source | Implication |
|---|---|---|
| Low 3 bits of `0xcx` are the level; `0xc0` (000) is legacy **sport / factory balanced** | msi-ec issues #288 / #291 / #24 encoding; GhostDeck does not use `0xc0` on this model | Boot value is an old “balanced” that MSI Center 2.x no longer writes |
| `0xc0` is the Windows/Linux **boot default** when MSI Center is not running; MSI Center cannot select it | msi-ec issue #198 (GF63 family, same `0xcx` space) | It is a real EC state, not a Linux bug |
| `unknown (192)` is **unconfigured**; `192=0xc0` is **similar to `0xc4` (highest power)**; “just pick another high-performance shift, not a bug” | msi-ec maintainer glpnk on #352 (2026-03-19) | Writing `comfort` (`0xc1`) from `0xc0` may **lower** power, not restore “balanced” |
| Older MSI Center “best performance” wrote **`0xd2=0xc0`**; turbo boost was Cooler Boost on top | msi-ec #24 (Summit E14, `0xd2` table includes sport `0xc0`) | On some firmware `0xc0` **is** the high-power named mode |
| `CONF_G2_10` comment “turbo is sometimes `0xc0`”; PR #446 “some configs declared C0 as sport and not turbo, probably copy/paste” | local `msi-ec.c`; #446 | Upstream itself has mixed sport vs turbo labelling for the same byte |

Encoding (bit 6 set, low bits = level) is consistent across the family:

`0xc0`=000, `0xc1`=001 comfort, `0xc2`=010 eco, `0xc4`=100 turbo.

Whether “level 0” means sport-default or “same as turbo” is **firmware-
specific**. This firmware’s driver table omitted `0xc0` entirely.

### 1.2 Rollback problem (unchanged)

Any `echo comfort > shift_mode` writes `0xc1`. The previous byte is
`0xc0`. `msi-ec` cannot write `0xc0` back. A failed or unwanted shift
write has no sysfs restore; reboot is the only guaranteed rollback
(volatile EC RAM).

That is still a hard block for `SetShiftMode` in this project
(AGENTS §6.1, §35 read-back/rollback).

### 1.3 What would unblock it

One of:

1. **Local DKMS / upstream:** add `{ "sport", 0xc0 }` (or a dedicated
   name) to `CONF_G2_10` so every live value is writable and restorable.
2. **Consent-gated experiment** after (1): from `unknown (192)`, write
   `comfort`, read `0xd2`, restore `sport`, confirm PL1/GPU TGP vs
   `turbo` — that answers whether `0xc0` is “old balanced” or “turbo-
   like” **on this firmware**.
3. Do **not** treat GhostDeck recipes as `SetShiftMode`. If we ever
   expose scenarios, they must set `fan_mode` + `super_battery` + shift
   as three existing methods, and only after (1)+(2).

Until then: keep showing `unknown (192)` verbatim. Do not alias it to
`sport`, `balanced`, or `turbo` in the UI.

---

## 2. Custom fan curve

Already captured in `docs/phase5-fan-curve-design.md`. Extra from this
pass:

- GhostDeck §17.4: on G2, Silent’s **power cap lives in `0xd4=0x1d`**.
  A curve needs `0xd4=0x8d`. One byte cannot be both — applying a curve
  in Silent **drops the Silent power policy**. That is a product rule,
  not a bug.
- MControlCenter writes the same G2 tables via `ec_sys` (`0x72`/`0x8a`
  speeds, `0x6a`/`0x82` temps) and hard-codes max 150 %.
- This project’s remaining gate is still the §11 single-point write
  (CPU speed `0x77` 75 %→100 %) to learn whether `0x9e` is a checksum.

No curve code until that experiment runs.

---

## 3. USB power share

MControlCenter (`operate.cpp`): address **`0xbf`**, off `0x08`, on
`0x28`. Detection = “current byte is exactly one of those two”.
Support is sparse (MCC tested-device table: many Katana/Summit greyed
out). Writes go through `ec_sys`, not `msi-ec`.

`msi-ec` 0.13 has **no** `usb_power` attribute in any `CONF_*` block
(grep of `/usr/src/msi_ec-0.13/msi-ec.c`: no `usb` strings). This
machine has no `usb_power_share` sysfs node.

On this EC, `0xbf` is **not** the fn/win register (`CONF_G2_10` uses
`0xe8`). Reading `0xbf` blindly to “detect” share would still be a raw
EC guess. Out of scope until `msi-ec` grows a semantic attr or a
read-only capture shows `0xbf` actually toggling with a hardware USB-
share switch (this chassis may not have the feature).

---

## 4. EC keyboard backlight (`msiacpi::kbd_backlight`)

`CONF_G2_10.kbd_bl` addresses are `MSI_EC_ADDR_UNSUPP`. There is no
`/sys/class/leds/msiacpi::kbd_backlight` on this laptop.

MControlCenter’s 0–3 brightness path is `0xd3` or `0xf3`
(`0x80` off … `0x83` full) — single-colour EC backlight. This Katana
uses **USB HID MysticLight MS-1565** (already in Phase 7). Driving
`0xd3` here would fight the RGB controller.

Keep RGB as the lighting backend. Do not add an EC brightness slider.

---

## 5. Mute / mic-mute LEDs

Live: `/sys/class/leds/platform::mute` and `platform::micmute`, from
`CONF_G2_10.leds` (`0x2d` / `0x2c`, bit 1). The kernel LED class owns
them; desktop audio stacks already bind mute keys to these LEDs.

Hijacking them from the daemon would desync the hardware LED from the
actual mixer state. Leave them to the kernel.

---

## 6. MUX / MSHybrid vs discrete

Katana 17 B13VGK owners report MSI Center **MSHybrid vs Discrete**
(Reddit). That is a hardware MUX / Advanced Optimus path, not PRIME
offload (AGENTS §6.5).

Linux:

- No `msi-ec` MUX sysfs.
- `nvidia-smi` “Display Mode” is deprecated on this driver.
- Third-party `msi-gpu-switcher` writes UEFI `MsiDCVarData` plus EC
  `0xd1` and **`0x2e` mask `0x40`**. On **this** firmware `0x2e` is the
  **webcam** register (`CONF_G2_10.webcam.address`). Copying that
  switcher’s EC poke would corrupt webcam state.

MUX stays Phase 10: needs a locally verified method that is **not**
webcam `0x2e`, plus an explicit user intent to reboot into discrete.
PRIME/offload is a separate, already-available NVIDIA/Intel path and
must not be labelled as MUX.

---

## 7. Unblock summary

| Feature | Unblock condition | Owner |
|---|---|---|
| Shift writes | `sport 0xc0` (or equivalent) in `msi-ec` `CONF_G2_10`, then consent-gated write+restore+power measurement | driver + user experiment |
| Fan curve | Phase 5 §11 one-byte experiment answers `0x9e` | user, own terminal |
| USB power share | semantic `msi-ec` attr, or proven `0xbf` toggle on this chassis | not this firmware today |
| EC kbd backlight | never on this RGB HID device | — |
| Mute LEDs | do not take | — |
| MUX | verified non-`0x2e` method + reboot contract | Phase 10 |

Sources: local `msi-ec` 0.13 `CONF_G2_10` + `shift_mode_{show,store}`;
msi-ec issues #24, #198, #288, #352, PR #446; GhostDeck
`docs/TECHNICAL.md` §17–§19 and `models.json` `17L5EMS1`;
MControlCenter `src/operate.cpp`; live sysfs 2026-09-07.
