<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — MSIノートPCのファン・バッテリー・キーボードRGBを対象とした、安全機構付きのネイティブLinuxデバイス管理ツール。Katana 17 B13VGKで検証済み">
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
    <b>日本語</b> ·
    <a href="README.ko.md">한국어</a>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#依存関係)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> このファイルはコミュニティによる翻訳です。内容に相違がある場合は
> [英語版README](README.md) が正となります。

MSIノートPC向けのオープンソースなネイティブLinuxデバイス管理ツール
です。**MSI Katana 17 B13VGK**（ボードMS-17L5、EC ファームウェア
`17L5EMS1.115`）をリファレンス機として開発されています。Rust製の
コア、D-Busデーモン、Qt/QMLデスクトップクライアントで構成されます。

すべてのハードウェア書き込みは、ファームウェアの完全一致確認で
ゲートされ、Polkitで認可され、機能ごとのオプトインの背後に置かれ、
読み戻し検証を経て、実機での検証が完了して初めて有効化されます。
完全なルールは
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) を参照
してください。

> **AI支援開発に関する告知:** このプロジェクトは完全にAIによって
> 記述されています（"vibecoded"）。すべてのコミットは
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) に
> 定められたルールの下で動作するAIコーディングエージェントによって
> 書かれ、人間がスコープを定義し、変更をレビューし、実機への適用
> 前にすべてのハードウェア書き込みに明示的な承認を必須としました。
> この人間によるレビューを経ずに存在するコード、設計文書、実機検証
> 記録は一切ありません。これは以下の
> [免責事項](#免責事項--自己責任での利用) を変更するものではあり
> ません。ご自身の責任でご利用ください。書き込み機能を有効にする
> 前に安全モデルをお読みください。

## ライブUI

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="システム概要: CPU/GPU温度、バッテリー残量、ファンモード、Katana 17の実測ファン回転数">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="ページツアー: 冷却、電源、バッテリー、キーボードRGB、シーン、診断">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="MysticLight MS-1565ゾーンプレビュー付きキーボードRGBページ">
</p>

## これは何か

デスクトップアプリ（Center）とCLIで構成され、EC モード/ファン
状態、温度、ファン回転数、バッテリー状態を読み取ります。オプト
インにより、検証済みの書き込み操作（充電しきい値、ファンモード、
Cooler Boost、Super Battery、ウェブカメラ/Fnキー、MysticLight
RGB）の小さなセットを適用できます。

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="Qt/QML UIとCLIはD-BusとPolkitを介してmsi-daemonと通信し、msi-daemonはmsi-ec、hwmon、バッテリーインターフェース、MysticLight RGBにアクセスする">
</p>

## 機能

- **読み取り専用テレメトリ** — ECモード/ファンモード、CPU/GPU温度、
  コア別温度/負荷、GPU別温度/負荷、ファンレベルと実回転数、
  バッテリー状態と充電しきい値、実行時の機能対応レポート
- **安全に検証された書き込み** — バッテリー充電しきい値、ファン
  モード、Cooler Boost、Super Battery、ウェブカメラ/ウェブカメラ
  ブロック、Fn/Winキー入れ替え
- **キーボードRGB** — 単色とMysticLight MS-1565エフェクト
  （ブリージング、レインボー、ウェーブ）、既定では非永続化。不揮発
  保存には別途オプトインが必要
- **シーン** — 安全な書き込みの名前付きバンドル。CLI/UIでの適用/
  インポート/エクスポート、すぐ使えるサンプル（quiet / cool /
  battery saver / gaming rgb）、起動時/AC-バッテリー切替時/
  バッテリー残量/スケジュールでのオプションの自動化トリガー
  （すべてオプトインで、UIから完全に管理可能）
- **トレイアイコン** — 温度と回転数をリアルタイムに表示する
  ツールチップ、クイックアクション、キーボードショートカット
  （Ctrl+Shift+C/B/L/P）
- **デスクトップUI** — 7ページ構成（概要、冷却、電源、バッテリー、
  キーボードRGB、シーン、診断）、ヒーローサーマルカード、常設
  クイックアクション、折りたたみ式シーン自動化メニュー、接続/
  更新ステータス、保留中アクションのトーストバー
- **コミュニティ診断** — シリアル番号を含まない上流サポート依頼用
  の `msicenter report`
- **フェイクsysroot** — 実機がなくても
  `MSI_LINUX_CENTER_SYSROOT` による開発/テストが可能

## インストール

リリースビルドはデーモン、CLI、Qt UIをビルドし、systemd、Polkit、
D-Busポリシー、デスクトップエントリ、そして（既定で）セッション
自動起動をインストールします。付属のsystemdユニットは**既定で**
バッテリー、ファンモード、Cooler Boost、RGB、ウェブカメラ、
ウェブカメラブロック、fn-keyの書き込みを有効化します。Super
Batteryと不揮発RGB保存は無効のままです。これらの既定値にかかわ
らず、すべての書き込みはデーモン内でPolkitにより保護され、
ファームウェアに厳密一致し、読み戻し/ロールバックにより検証され
ます。完全に読み取り専用の既定を希望する場合は、インストール前に
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
を編集してください。

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` は `~/.config/msi-linux-center` を削除しません。既定の
プレフィックスは `/usr` です（`PREFIX` と `SYSCONFDIR` で設定可能）。

### 要件

- Rustツールチェーン（≥ 1.75）
- Qt 6（Core, QML, Quick, DBus, QuickControls2, Widgets）+
  CMake ≥ 3.21
- 実機で動作させるには `msi-ec` と `msi_wmi_platform` カーネル
  モジュールを備えたLinux（いずれも存在しない場合、読み取り/書き
  込みの両パスは安全にデグレードします）

正確なシステムパッケージとサポート対象OSは、下記の
[依存関係](#依存関係) セクションを参照してください。

### ソースからビルド

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## 実行

付属のフィクスチャを使用（実機不要）:

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

実機での読み取り専用実行:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

CLIをsudoで実行し**ない**でください。権限が必要な書き込みは、
Polkitの認可後にデーモンによってのみ実行されます。

## 書き込みコマンド（安全機構付き）

各コマンドは、対応するオプトイン
（`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`）でデーモンが実行され、
Polkit認可プロンプトが完了している必要があります。

```bash
msicenter battery-thresholds START END      # 例: 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # 非永続
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # 不揮発保存（別途オプトイン）
msicenter panic-reset                       # Cooler Boost無効化、Super Battery無効化、ファンをautoに戻す
msicenter scene list|examples|apply NAME
```

オプトインが無効の場合、デーモンは `NotSupported` で拒否します。
正確な対応マトリクス、ガード、実機検証ログについては
[`docs/dbus-contract.md`](docs/dbus-contract.md) と
`docs/phase4-*-validation.md` を参照してください。

## 安全モデル

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="書き込みに対する6つの安全ゲート: ファームウェア一致、オプトイン、Polkit、読み戻し、Katana 17 B13VGKでの実機検証、未文書化レジスタへの推測書き込みなし">
</p>

1. **ファームウェアゲート** — ECファームウェア文字列が実機検証済み
   のファームウェアと厳密に一致する場合にのみ書き込みが実行されます
2. **オプトインゲート** — 各書き込みカテゴリはデーモン内で独自の
   環境変数の背後にあります。付属のsystemdユニットは既定でバッ
   テリー、ファンモード、Cooler Boost、RGB、ウェブカメラ、ウェブ
   カメラブロック、fn-keyを有効化します（Super Batteryと不揮発
   RGB保存は無効のまま）
3. **Polkitゲート** — すべてのD-Bus書き込みメソッドはPolkit
   アクションにマッピングされます
4. **読み戻し検証** — EC/バッテリーの書き込みは読み戻され検証され
   ます。失敗した書き込みはロールバックされます
5. **実機検証** — リファレンス機で検証され`docs/`に文書化される
   まで、いかなる書き込みパスも出荷されません
6. **推測は一切なし** — 未文書化のレジスタへ書き込むことは決して
   なく、各ハードウェア機能の出典はデバイスプロファイルに記録され
   ます

## サポート対象デバイス

| デバイス | ステータス |
|---|---|
| MSI Katana 17 B13VGK（MS-17L5、ファームウェア `17L5EMS1.115`） | 実機検証済みリファレンス機 |
| その他の `msi-ec` 対応MSIノートPC | 読み取り専用テレメトリ。書き込みは厳密なファームウェア一致で保護 |
| 非一致モデル | 読み取り専用 + 診断レポート。`msicenter report` によるコミュニティサポート |

<details>
<summary>フェーズステータス</summary>

| フェーズ | 範囲 | ステータス |
|---|---|---|
| 0 | 読み取り専用ハードウェア調査 | 完了 |
| 1–2 | 読み取り専用コア、デバイスDB、実行時機能、フィクスチャ | 完了 |
| 3 | D-Busデーモン、systemdユニット、D-Busポリシー、Polkitアクション | 完了 |
| 4 | 安全なセマンティック書き込み（バッテリーしきい値、ファンモード、Cooler Boost、Super Battery） | 完了 — 2026-09-05に実機検証済み |
| 5 | カスタムファンカーブ | [設計のみ](docs/phase5-fan-curve-design.md) — §11の実験完了までコードなし |
| 6 | Qt/QMLデスクトップUI | 完了 — [設計](docs/phase6-ui-design.md) |
| 7 | RGB（MysticLight MS-1565） | `SetRgbColor` 実機検証済み。エフェクトモード実装済み。不揮発保存は実装済みで実機テスト待ち |
| 8 | シーン | 完了 — CLI + UIで検証済み |
| 9 | コミュニティ診断 | 完了 — [設計](docs/phase9-diagnostics.md) |
| 10 | GPU MUX切り替え | 調査のみ — [ノート](docs/deferred-features-research.md) |

</details>

## ドキュメント

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — D-Bus API契約
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — MysticLightプロトコル
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — リバースエンジニアリング一覧
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — コントリビューターとAIエージェント向けの安全ルール
- [プロジェクトWiki](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — インストール、安全モデル、D-Bus API、FAQをブラウズ可能な形式で提供

## 依存関係

**サポート対象OS** — Linuxのみ。Arch LinuxとUbuntuで開発・テスト
済み（CIは`ubuntu-latest`で実行）。`systemd`、Polkit、D-Bus、
Qt 6、最新のRustツールチェーンを備えたディストリビューションであ
れば動作するはずです。実機でのテレメトリ/書き込みには`msi-ec`と
`msi_wmi_platform`カーネルモジュールが必要です。これらがなくても、
フィクスチャを通じて読み取り専用でビルド・実行できます。

**主要システムパッケージ**

| パッケージ | 用途 |
|---|---|
| Rustツールチェーン ≥ 1.75（`cargo`） | すべてのRustクレートをビルド |
| Qt 6 ≥ 6.4（Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets） | デスクトップUI |
| CMake ≥ 3.21 | Qt UIをビルド |
| `pkg-config` | ビルド時に`libusb-1.0`を検出 |
| `libusb-1.0-0-dev`（開発ヘッダー） | RGB HIDバックエンド、ビルド時に静的リンク |
| `libudev-dev` | ハードウェア/デバイス列挙 |
| `systemd`, `polkit`, `dbus`（ランタイム） | デーモンサービス、権限分離、IPC |
| `libusb-1.0-0`（ランタイム） | RGB HIDバックエンドのランタイム依存 |

```bash
# Debian/Ubuntu（CIと一致）
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**主要Rustクレート** — `zbus`（D-Bus）、`serde`/`serde_json`
（データとデバイスプロファイル）、`hidapi`（MysticLight RGB用に
静的リンクされた`linux-static-libusb`バックエンド — お使いの
ディストリビューションの`hidapi`パッケージでリンカーエラーが発生
する場合は
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
を参照）。完全な依存関係グラフは`Cargo.lock`と各クレートの
`Cargo.toml`にあります。

**使用しているカーネルモジュール** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
（ECセマンティック状態、ファンモード、Cooler Boost、Super
Battery、ウェブカメラ/Fnキー）、`msi_wmi_platform`/hwmon（実測
ファン回転数）、Linuxの`power_supply`（バッテリー状態と充電しきい
値）。

**開発中に参照したプロジェクト** — 調査/参考資料のみであり、これら
のいずれも組み込みまたはリンクされていません。各書き込みパスは
出荷前に独立して検証されています（[安全モデル](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)
参照）:

| プロジェクト | 用途 |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | MSIモデル/ファームウェアの知識、ECレジスタ調査、ファンカーブ、検証手法 |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | Linux上のMSI固有EC/sysfsセマンティクス、モード、Cooler Boost、温度、ファンレベル、対応モデル |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | Linux上のMSIノートPCの機能/UX挙動比較 |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | 権限分離、Polkitアプローチ、ファン制御、フィクスチャ/ロールバック |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | Katana Mystic LightのUSB/HIDプロトコルと4ゾーンRGB調査 |
| [Linuxカーネル](https://github.com/torvalds/linux) | hwmon、power_supply、WMI、ACPI、HID、DRM、プラットフォームドライバーのセマンティクスに関する最優先の権威ある参考資料 |

## 免責事項 — 自己責任での利用

本ソフトウェアは、組み込みコントローラー（EC）、バッテリー充電
インターフェース、USB HID経由のRGBコントローラーを含むノートPCの
ハードウェアを制御します。これらのインターフェースへの誤った
書き込みは、不安定動作、熱問題、バッテリー寿命の低下、データ
損失、またはハードウェア/ファームウェアの損傷を引き起こす可能性
があります。

**本プロジェクトは、明示または黙示を問わずいかなる保証もなく
「現状のまま」提供されます。作者およびコントリビューターは、本
ソフトウェアの使用によって生じるいかなる損害、データ損失、または
不具合についても責任を負いません。これにはノートPC、バッテリー、
キーボード、その他のハードウェアへの損傷が含まれます。**

本プロジェクトに組み込まれた緩和策（ファームウェア保護、機能ごと
のオプトイン、Polkit認可、読み戻し検証、リファレンス機での実機
検証）はリスクを低減しますが、排除するものではありません。これら
はベストエフォートのエンジニアリング対策であり、保証ではありません。

- バッテリーしきい値、ファンモード、Cooler Boost、RGB、ウェブ
  カメラ、ウェブカメラブロック、fn-keyの書き込みは、インストール
  されたsystemdユニットで**既定で有効**です（Super Batteryと不揮発
  RGB保存は無効のまま）。それらが何を行うか理解している場合のみ
  インストールしてください。完全に読み取り専用の既定を希望する
  場合は、インストール前にユニットファイルを編集してください
- 動作は**MSI Katana 17 B13VGK**（ファームウェア
  `17L5EMS1.115`）でのみ実機検証されています。他のモデルは保護
  されていますが未検証です
- 損傷を許容できないノートPCで本ソフトウェアを使用しないでくだ
  さい。また、機微なハードウェアで書き込み機能を決して有効にしな
  いでください
- 不安な場合は、読み取り専用のテレメトリ機能のみを使用してくだ
  さい

**十分ご注意ください。本ソフトウェアの使用によるいかなる結果に
ついても、責任を負うのはあなた自身です。**

## コントリビューション

まず [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md)
をお読みください。ハードウェア書き込みパスには、出典の文書化、
ガード、実機検証ログが必要です。これらを省略したPRはマージされ
ません。

## ライセンス

[MIT](LICENSE-MIT) または [Apache-2.0](LICENSE-APACHE) の
デュアルライセンスの下で提供されます（お好きな方をお選びくださ
い）。
