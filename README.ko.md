<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — MSI 노트북의 팬, 배터리, 키보드 RGB를 위한 안전 게이트 기반 네이티브 Linux 장치 관리 도구, Katana 17 B13VGK에서 검증됨">
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
    <a href="README.hi.md">हिन्दी</a> ·
    <a href="README.ja.md">日本語</a> ·
    <b>한국어</b>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#종속성)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> 이 파일은 커뮤니티가 제공한 번역본입니다. 내용이 상충할 경우
> [영어 README](README.md)가 우선합니다.

MSI 노트북을 위한 오픈소스 네이티브 Linux 장치 관리 도구입니다.
**MSI Katana 17 B13VGK**(보드 MS-17L5, EC 펌웨어
`17L5EMS1.115`)를 레퍼런스 기기로 삼아 개발되었습니다. Rust로 작성된
코어, D-Bus 데몬, Qt/QML 데스크톱 클라이언트로 구성됩니다.

모든 하드웨어 쓰기 작업은 펌웨어 완전 일치 확인으로 게이트되고,
Polkit으로 인가되며, 기능별 옵트인 뒤에 놓이고, 읽기 검증을 거치며,
실제 기기에서 검증된 이후에만 활성화됩니다. 전체 규칙은
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)에서
확인할 수 있습니다.

> **AI 지원 개발 관련 고지:** 이 프로젝트는 전적으로 AI에 의해
> 작성되었습니다("vibecoded"). 모든 커밋은
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)에
> 명시된 규칙 아래 작동하는 AI 코딩 에이전트가 작성했으며, 사람이
> 범위를 정의하고 변경 사항을 검토했고, 실제 기기에 적용하기 전
> 모든 하드웨어 쓰기 작업에 명시적 승인을 요구했습니다. 이러한
> 사람의 검토 없이 존재하는 코드, 설계 문서, 실제 검증 기록은
> 없습니다. 이는 아래의
> [면책 조항](#면책-조항--사용자-본인의-책임-하에-사용)을 전혀
> 변경하지 않습니다. 본인의 책임 하에 사용하시고, 쓰기 기능을
> 활성화하기 전에 안전 모델을 읽어보시기 바랍니다.

## 라이브 UI

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="시스템 개요: CPU/GPU 온도, 배터리 충전량, 팬 모드, Katana 17의 실측 팬 RPM">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="페이지 투어: 냉각, 전원, 배터리, 키보드 RGB, 씬, 진단">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="MysticLight MS-1565 존 미리보기가 있는 키보드 RGB 페이지">
</p>

## 이 프로젝트는 무엇인가

EC 모드/팬 상태, 온도, 팬 RPM, 배터리 상태를 읽는 데스크톱 앱
(Center)과 CLI이며, 옵트인 시 검증된 소규모 쓰기 작업 세트(충전
임계값, 팬 모드, Cooler Boost, Super Battery, 웹캠/Fn 키,
MysticLight RGB)를 적용합니다.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML UI와 CLI는 D-Bus와 Polkit을 통해 msi-daemon과 통신하며, msi-daemon은 msi-ec, hwmon, 배터리 인터페이스, MysticLight RGB에 접근한다">
</p>

## 기능

- **읽기 전용 텔레메트리** — EC/팬 모드, CPU/GPU 온도, 코어별
  온도/부하, GPU별 온도/부하, 팬 레벨과 실측 RPM, 배터리 상태와
  충전 임계값, 런타임 기능 지원 보고
- **안전하고 검증된 쓰기** — 배터리 충전 임계값, 팬 모드, Cooler
  Boost, Super Battery, 웹캠/웹캠 차단, Fn/Win 키 교체
- **키보드 RGB** — 단색 및 MysticLight MS-1565 효과(브리딩,
  레인보우, 웨이브), 기본적으로 비영구적이며, 비휘발성 저장에는
  별도 옵트인 필요
- **씬(Scenes)** — 안전한 쓰기 작업의 명명된 묶음, CLI/UI에서
  적용/가져오기/내보내기, 즉시 사용 가능한 예제(quiet / cool /
  battery saver / gaming rgb), 부팅/AC-배터리 전환/배터리 잔량/
  일정에 따른 선택적 자동화 트리거(모두 옵트인이며 UI에서 완전히
  관리 가능)
- **트레이 아이콘** — 실시간 온도 및 RPM 툴팁, 빠른 작업, 키보드
  단축키(Ctrl+Shift+C/B/L/P)
- **데스크톱 UI** — 7개 페이지(개요, 냉각, 전원, 배터리, 키보드
  RGB, 씬, 진단) 구성, 히어로 열 상태 카드, 상시 빠른 작업, 접이식
  씬 자동화 메뉴, 연결/새로고침 상태, 대기 중인 작업을 위한 토스트
  바
- **커뮤니티 진단** — 업스트림 지원 요청을 위한 시리얼 번호 없는
  `msicenter report`
- **가짜 sysroot** — 실제 하드웨어 없이
  `MSI_LINUX_CENTER_SYSROOT`를 통한 개발/테스트

## 설치

릴리스 빌드는 데몬, CLI, Qt UI를 빌드한 다음 systemd, Polkit,
D-Bus 정책, 데스크톱 항목, (기본적으로) 세션 자동 시작을
설치합니다. 포함된 systemd 유닛은 **기본적으로** 배터리, 팬 모드,
Cooler Boost, RGB, 웹캠, 웹캠 차단, fn-key 쓰기를 활성화합니다.
Super Battery와 비휘발성 RGB 저장은 비활성 상태로 유지됩니다. 이러한
기본값과 무관하게, 모든 쓰기 작업은 데몬 내에서 Polkit으로 보호되고,
펌웨어와 정확히 일치하며, 읽기 검증/롤백을 거칩니다. 완전히 읽기
전용 기본값을 원하시면 설치 전에
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
파일을 수정하세요.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall`은 `~/.config/msi-linux-center`를 삭제하지 않습니다.
기본 접두사는 `/usr`입니다(`PREFIX`와 `SYSCONFDIR`로 설정 가능).

### 요구 사항

- Rust 툴체인(≥ 1.75)
- Qt 6(Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- 실제 하드웨어에서 동작하려면 `msi-ec`와 `msi_wmi_platform` 커널
  모듈이 있는 Linux(둘 다 없어도 읽기 및 쓰기 경로는 안전하게
  저하됨)

정확한 시스템 패키지와 지원 OS는 아래
[종속성](#종속성) 섹션을 참고하세요.

### 소스에서 빌드

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## 실행

포함된 픽스처를 대상으로 실행(실제 하드웨어 불필요):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

실제 노트북에서 읽기 전용으로 실행:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

CLI를 sudo로 실행하지 **마십시오**. 권한이 필요한 쓰기 작업은
Polkit 인가 후 데몬에 의해서만 실행됩니다.

## 쓰기 명령(안전 게이트 적용)

각 명령은 해당하는 옵트인
(`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`)으로 데몬이 실행 중이어야
하고, Polkit 인가 프롬프트를 완료해야 합니다.

```bash
msicenter battery-thresholds START END      # 예: 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # 비영구적
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # 비휘발성 저장(별도 옵트인)
msicenter panic-reset                       # Cooler Boost 해제, Super Battery 해제, 팬을 auto로 복귀
msicenter scene list|examples|apply NAME
```

옵트인이 비활성화된 경우 데몬은 `NotSupported`로 거부합니다. 정확한
지원 매트릭스, 가드, 실제 검증 로그는
[`docs/dbus-contract.md`](docs/dbus-contract.md)와
`docs/phase4-*-validation.md`를 참고하세요.

## 안전 모델

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="쓰기 작업을 위한 6가지 안전 게이트: 펌웨어 일치, 옵트인, Polkit, 읽기 검증, Katana 17 B13VGK에서의 실제 검증, 문서화되지 않은 레지스터에 대한 추측 쓰기 없음">
</p>

1. **펌웨어 게이트** — EC 펌웨어 문자열이 실제로 검증된 펌웨어와
   정확히 일치할 때만 쓰기 작업이 실행됩니다
2. **옵트인 게이트** — 각 쓰기 카테고리는 데몬 내에서 자체 환경
   변수 뒤에 있습니다. 포함된 systemd 유닛은 기본적으로 배터리,
   팬 모드, Cooler Boost, RGB, 웹캠, 웹캠 차단, fn-key를
   활성화합니다(Super Battery와 비휘발성 RGB 저장은 비활성 상태로
   유지)
3. **Polkit 게이트** — 모든 D-Bus 쓰기 메서드는 Polkit 작업에
   매핑됩니다
4. **읽기 검증** — EC/배터리 쓰기는 읽기 검증되며, 실패한 쓰기는
   롤백됩니다
5. **실제 검증** — 레퍼런스 하드웨어에서 테스트되고 `docs/`에
   문서화되기 전까지는 어떤 쓰기 경로도 출시되지 않습니다
6. **추측 없음** — 문서화되지 않은 레지스터에는 절대 쓰지 않으며,
   각 하드웨어 기능의 출처는 장치 프로필에 기록됩니다

## 지원 장치

| 장치 | 상태 |
|---|---|
| MSI Katana 17 B13VGK(MS-17L5, 펌웨어 `17L5EMS1.115`) | 실제 검증된 레퍼런스 기기 |
| `msi-ec`를 지원하는 다른 MSI 노트북 | 읽기 전용 텔레메트리; 쓰기는 정확한 펌웨어 일치로 보호됨 |
| 일치하지 않는 모델 | 읽기 전용 + 진단 보고서; `msicenter report`를 통한 커뮤니티 지원 |

<details>
<summary>단계별 상태</summary>

| 단계 | 범위 | 상태 |
|---|---|---|
| 0 | 읽기 전용 하드웨어 탐색 | 완료 |
| 1–2 | 읽기 전용 코어, 장치 DB, 런타임 기능, 픽스처 | 완료 |
| 3 | D-Bus 데몬, systemd 유닛, D-Bus 정책, Polkit 작업 | 완료 |
| 4 | 안전한 시맨틱 쓰기(배터리 임계값, 팬 모드, Cooler Boost, Super Battery) | 완료 — 2026-09-05에 실제 검증됨 |
| 5 | 사용자 지정 팬 커브 | [설계 전용](docs/phase5-fan-curve-design.md) — §11 실험 완료 전까지 코드 없음 |
| 6 | Qt/QML 데스크톱 UI | 완료 — [설계](docs/phase6-ui-design.md) |
| 7 | RGB(MysticLight MS-1565) | `SetRgbColor` 실제 검증됨; 효과 모드 구현됨; 비휘발성 저장 구현 완료, 실제 테스트 대기 중 |
| 8 | 씬 | 완료 — CLI + UI 검증됨 |
| 9 | 커뮤니티 진단 | 완료 — [설계](docs/phase9-diagnostics.md) |
| 10 | GPU MUX 전환 | 조사만 진행됨 — [노트](docs/deferred-features-research.md) |

</details>

## 문서

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — D-Bus API 계약
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — MysticLight 프로토콜
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — 리버스 엔지니어링 목록
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — 기여자 및 AI 에이전트를 위한 안전 규칙
- [프로젝트 위키](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — 탐색 가능한 형태의 설치, 안전 모델, D-Bus API, FAQ

## 종속성

**지원 OS** — Linux만 지원합니다. Arch Linux와 Ubuntu에서 개발 및
테스트되었습니다(CI는 `ubuntu-latest`에서 실행). `systemd`, Polkit,
D-Bus, Qt 6, 최신 Rust 툴체인을 갖춘 배포판이라면 동작해야 합니다.
실제 하드웨어 텔레메트리/쓰기에는 `msi-ec`와
`msi_wmi_platform` 커널 모듈이 필요합니다. 이들이 없어도 프로젝트는
픽스처를 통해 읽기 전용으로 빌드 및 실행됩니다.

**핵심 시스템 패키지**

| 패키지 | 용도 |
|---|---|
| Rust 툴체인 ≥ 1.75(`cargo`) | 모든 Rust 크레이트 빌드 |
| Qt 6 ≥ 6.4(Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | 데스크톱 UI |
| CMake ≥ 3.21 | Qt UI 빌드 |
| `pkg-config` | 빌드 시 `libusb-1.0` 탐지 |
| `libusb-1.0-0-dev`(개발 헤더) | RGB HID 백엔드, 빌드 시 정적 링크 |
| `libudev-dev` | 하드웨어/장치 열거 |
| `systemd`, `polkit`, `dbus`(런타임) | 데몬 서비스, 권한 분리, IPC |
| `libusb-1.0-0`(런타임) | RGB HID 백엔드의 런타임 종속성 |

```bash
# Debian/Ubuntu(CI와 동일)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**핵심 Rust 크레이트** — `zbus`(D-Bus), `serde`/`serde_json`(데이터
및 장치 프로필), `hidapi`(MysticLight RGB를 위해 정적으로 링크된
`linux-static-libusb` 백엔드 — 배포판의 `hidapi` 패키지에서 링커
오류가 발생하면
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)를
참고하세요). 전체 종속성 그래프는 `Cargo.lock`과 각 크레이트의
`Cargo.toml`에 있습니다.

**사용된 커널 모듈** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(EC 시맨틱 상태, 팬 모드, Cooler Boost, Super Battery, 웹캠/Fn 키),
`msi_wmi_platform`/hwmon(실측 팬 RPM), Linux의 `power_supply`(배터리
상태와 충전 임계값).

**개발 중 참고한 프로젝트** — 조사/참고 자료일 뿐이며, 이들 중
어느 것도 포함되거나 링크되지 않았습니다. 각 쓰기 경로는 출시 전
독립적으로 검증되었습니다([안전 모델](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)
참고):

| 프로젝트 | 사용 목적 |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSI 모델/펌웨어 지식, EC 레지스터 조사, 팬 커브, 검증 방법론 |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux의 MSI 전용 EC/sysfs 시맨틱, 모드, Cooler Boost, 온도, 팬 레벨, 지원 모델 |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | Linux에서의 MSI 노트북 기능/UX 동작 비교 |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | 권한 분리, Polkit 접근 방식, 팬 제어, 픽스처/롤백 |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana Mystic Light USB/HID 프로토콜 및 4존 RGB 조사 |
| [Linux 커널](https://github.com/torvalds/linux) | hwmon, power_supply, WMI, ACPI, HID, DRM 및 플랫폼 드라이버 시맨틱에 대한 최우선 권위 참조 |

## 면책 조항 — 사용자 본인의 책임 하에 사용

이 소프트웨어는 임베디드 컨트롤러(EC), 배터리 충전 인터페이스,
USB HID를 통한 RGB 컨트롤러를 포함한 노트북 하드웨어를 제어합니다.
이러한 인터페이스에 대한 잘못된 쓰기 작업은 불안정성, 열 문제,
배터리 수명 감소, 데이터 손실 또는 하드웨어/펌웨어 손상을 초래할 수
있습니다.

**이 프로젝트는 명시적이든 묵시적이든 어떠한 종류의 보증 없이
"있는 그대로" 제공됩니다. 저자 및 기여자는 이 소프트웨어의 사용으로
인해 발생하는 손해, 데이터 손실 또는 오작동(노트북, 배터리,
키보드 또는 기타 하드웨어에 대한 손상 포함)에 대해 책임을 지지
않습니다.**

이 프로젝트에 내장된 완화 조치(펌웨어 보호, 기능별 옵트인, Polkit
인가, 읽기 검증, 레퍼런스 하드웨어에서의 실제 검증)는 위험을
줄여주지만 제거하지는 않습니다. 이는 최선의 노력을 다한 엔지니어링
조치일 뿐 보증이 아닙니다.

- 배터리 임계값, 팬 모드, Cooler Boost, RGB, 웹캠, 웹캠 차단,
  fn-key 쓰기는 설치된 systemd 유닛에서 **기본적으로** 활성화되어
  있습니다(Super Battery와 비휘발성 RGB 저장은 비활성 상태 유지).
  각 기능이 무엇을 하는지 이해하는 경우에만 설치하시고, 완전히
  읽기 전용 기본값을 원하시면 설치 전에 유닛 파일을 수정하세요
- 이 동작은 **MSI Katana 17 B13VGK**(펌웨어
  `17L5EMS1.115`)에서만 실제 검증되었습니다. 다른 모델은
  보호되지만 검증되지 않았습니다
- 손상을 감당할 수 없는 노트북에서는 이 소프트웨어를 사용하지
  마시고, 민감한 하드웨어에서는 절대 쓰기 기능을 활성화하지
  마십시오
- 확신이 서지 않는다면 읽기 전용 텔레메트리 기능만 사용하세요

**주의하십시오. 이 소프트웨어 사용의 모든 결과에 대한 책임은
전적으로 본인에게 있습니다.**

## 기여

먼저 [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)를
읽어 주세요. 하드웨어 쓰기 경로에는 출처 문서화, 가드, 실제 검증
로그가 필요합니다. 이를 생략한 PR은 병합되지 않습니다.

## 라이선스

원하시는 대로 [MIT](LICENSE-MIT) 또는
[Apache-2.0](LICENSE-APACHE) 중 하나를 선택할 수 있는 이중
라이선스입니다.
