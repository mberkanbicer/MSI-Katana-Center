<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — gestion native Linux, à portes de sécurité, des ventilateurs, de la batterie et du RGB clavier pour portables MSI, vérifiée sur le Katana 17 B13VGK">
</p>

<p align="center">
  <sub>
    <a href="README.md">English</a> ·
    <a href="README.zh.md">简体中文</a> ·
    <a href="README.tr.md">Türkçe</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <b>Français</b> ·
    <a href="README.sv.md">Svenska</a> ·
    <a href="README.it.md">Italiano</a> ·
    <a href="README.pt.md">Português</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.ar.md">العربية</a> ·
    <a href="README.hi.md">हिन्दी</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a>
  </sub>
</p>

# MSI Katana Center

[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-MIT)
[![CI](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml/badge.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/actions/workflows/ci.yml)
[![Rust ≥ 1.75](https://img.shields.io/badge/rust-%E2%89%A5%201.75-orange.svg)](Cargo.toml)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#dépendances)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> Ce fichier est une traduction fournie par la communauté. En cas de
> divergence, le [README anglais](README.md) fait foi.

Gestion matérielle native Linux et open-source pour portables MSI.
Développé à partir du **MSI Katana 17 B13VGK** (carte MS-17L5, EC
`17L5EMS1.115`) comme appareil de référence. Cœur en Rust, démon
D-Bus, client de bureau Qt/QML.

Chaque écriture matérielle est verrouillée par la version du
firmware, autorisée par Polkit, activable par fonctionnalité
(opt-in), vérifiée par relecture, et n'est activée qu'après
vérification physique sur l'appareil de référence. Les règles sont
détaillées dans
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **Avis de développement assisté par IA :** ce projet est
> entièrement « vibecodé » — chaque commit a été écrit par un agent
> de codage IA suivant les règles de
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md), sous
> la direction d'un humain qui a défini la portée, relu les
> modifications, et validé explicitement chaque écriture matérielle
> avant son exécution sur du matériel réel. Aucune ligne de code,
> aucun document de conception, aucun enregistrement de vérification
> physique n'a été généré sans cette relecture humaine. Cela ne
> change rien à l'
> [avertissement](#avertissement--utilisation-à-vos-risques-et-périls)
> ci-dessous : utilisation à vos risques et périls — lisez les
> mécanismes de sécurité avant d'activer un opt-in d'écriture.

## Interface en action

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="Vue d'ensemble du système : températures CPU/GPU, charge de la batterie, mode ventilateur et RPM en direct sur le Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Tour des pages : Refroidissement, Alimentation, Batterie, RGB clavier, Scènes et Diagnostics">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Page RGB clavier avec aperçu des zones MysticLight MS-1565">
</p>

## Qu'est-ce que c'est

Une application Center de bureau et un outil CLI qui lisent l'état
EC/ventilateur, les températures, les RPM et l'état de la batterie
— et, si vous l'activez, appliquent un petit ensemble d'écritures
vérifiées : seuils de charge, mode ventilateur, Cooler Boost,
Super Battery, webcam/touches Fn, et RGB MysticLight.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="L'interface Qt/QML et le CLI communiquent via D-Bus et Polkit avec msi-daemon, qui accède à msi-ec, hwmon, l'interface batterie et le RGB MysticLight">
</p>

## Fonctionnalités

- **Télémétrie en lecture seule** — modes EC/ventilateur,
  températures CPU/GPU, température/charge par cœur, température/
  charge par GPU, niveaux de ventilateur et RPM réel, état de la
  batterie et seuils de charge, rapport des capacités à l'exécution
- **Écritures verrouillées et vérifiées** — seuils de charge de la
  batterie, mode ventilateur, Cooler Boost, Super Battery, webcam/
  blocage webcam, échange des touches Fn/Win
- **RGB clavier** — couleur fixe et effets MysticLight MS-1565
  (respiration, cycle, vague), non persistant par défaut ;
  l'enregistrement en flash nécessite un opt-in distinct
- **Scènes** — regroupements nommés des écritures verrouillées,
  avec application/import/export en CLI et UI, exemples de départ
  (Silencieux / Frais / Économie de batterie / Éclairage gaming),
  automatisation optionnelle au démarrage/secteur-batterie/niveau
  de batterie/planning (tout en opt-in, tout géré par l'UI)
- **Icône système** — infobulle en direct des températures/RPM,
  actions rapides, raccourcis clavier (Ctrl+Maj+C/B/L/P)
- **Interface de bureau** — sept pages (Vue d'ensemble,
  Refroidissement, Alimentation, Batterie, RGB clavier, Scènes,
  Diagnostics) avec une carte thermique principale, des actions
  primaires épinglées, un accordéon d'automatisation des scènes, un
  statut de connexion/obsolescence et une bannière d'actions en
  attente
- **Diagnostics communautaires** — `msicenter report` sans numéro
  de série pour les demandes de support en amont
- **Environnement de test avec faux sysroot** — développement et
  tests sans matériel via `MSI_LINUX_CENTER_SYSROOT`

## Installation

Compile le démon, le CLI et l'interface Qt en version release, puis
installe systemd, Polkit, la politique D-Bus, le fichier desktop et
(par défaut) le démarrage automatique de session. L'unité systemd
fournie active par défaut les opt-ins d'écriture batterie, mode
ventilateur, cooler-boost, RGB, webcam, blocage webcam et touche
fn ; Super Battery et l'enregistrement flash RGB restent
désactivés. Quelle que soit cette configuration par défaut, chaque
écriture reste verrouillée par Polkit dans le démon, associée à une
correspondance exacte de firmware et vérifiée par relecture/
restauration — modifiez
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
avant l'installation si vous voulez un comportement entièrement en
lecture seule par défaut.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` ne supprime pas `~/.config/msi-linux-center`. Le
préfixe est `/usr` par défaut (`PREFIX`, `SYSCONFDIR`).

### Prérequis

- Chaîne d'outils Rust (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- Linux avec les modules noyau `msi-ec` et `msi_wmi_platform` pour
  le matériel réel (les chemins de lecture et d'écriture se
  dégradent proprement en leur absence)

Voir [Dépendances](#dépendances) ci-dessous pour les paquets
système exacts et les OS pris en charge.

### Compiler depuis les sources

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Exécution

Contre l'environnement de test inclus (aucun matériel nécessaire) :

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

En lecture seule sur le vrai portable :

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

N'exécutez **pas** le CLI avec sudo. Les écritures privilégiées ne
sont effectuées que par le démon après autorisation Polkit.

## Commandes d'écriture (verrouillées)

Chaque commande exige que le démon fonctionne avec l'opt-in
correspondant (`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) et complète
une invite Polkit :

```bash
msicenter battery-thresholds START END      # p. ex. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # non persistant
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # enregistrement flash persistant (opt-in distinct)
msicenter panic-reset                       # Cooler Boost désactivé, Super Battery désactivé, ventilateur auto
msicenter scene list|examples|apply NAME
```

Avec l'opt-in désactivé, le démon refuse avec `NotSupported`. Le
périmètre exact de prise en charge, les verrous et les
enregistrements de vérification physique se trouvent dans
[`docs/dbus-contract.md`](docs/dbus-contract.md) et les fichiers
`docs/phase4-*-validation.md`.

## Modèle de sécurité

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Six verrous d'écriture : correspondance du firmware, opt-in, Polkit, relecture, vérification physique sur le Katana 17 B13VGK, et aucun registre non documenté">
</p>

1. **Verrou firmware** — les écritures ne s'exécutent que lorsque
   le firmware EC de l'appareil correspond exactement à une chaîne
   de firmware vérifiée physiquement
2. **Verrou opt-in** — chaque famille d'écritures dépend de sa
   propre variable d'environnement du démon ; l'unité systemd
   fournie active par défaut batterie, mode ventilateur,
   cooler-boost, RGB, webcam, blocage webcam et touche fn (Super
   Battery et l'enregistrement flash RGB restent désactivés)
3. **Verrou Polkit** — chaque méthode d'écriture D-Bus correspond à
   une action Polkit
4. **Vérification par relecture** — les écritures EC et batterie
   sont relues et vérifiées ; les écritures échouées sont
   restaurées
5. **Vérification physique** — un chemin d'écriture n'est publié
   qu'après avoir été testé sur le portable de référence et
   consigné dans `docs/`
6. **Aucune supposition** — les registres non documentés ne sont
   jamais écrits ; la provenance de chaque fonctionnalité matérielle
   est enregistrée dans le profil de l'appareil

## Appareils pris en charge

| Appareil | Statut |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | appareil de référence vérifié |
| Autres portables MSI avec `msi-ec` | télémétrie en lecture seule uniquement ; écritures verrouillées par correspondance exacte du firmware |
| Modèles non reconnus | lecture seule + rapport de diagnostic ; support communautaire via `msicenter report` |

<details>
<summary>Statut des phases</summary>

| Phase | Portée | Statut |
|---|---|---|
| 0 | reconnaissance matérielle en lecture seule | terminée |
| 1–2 | cœur en lecture seule, base de données des appareils, capacités à l'exécution, environnement de test | terminée |
| 3 | démon D-Bus, unité systemd, politique D-Bus, actions Polkit | terminée |
| 4 | écritures sémantiques verrouillées (seuils de batterie, mode ventilateur, Cooler Boost, Super Battery) | terminée — vérifiée physiquement le 05/09/2026 |
| 5 | courbes de ventilateur personnalisées | [étude de conception](docs/phase5-fan-curve-design.md) — aucune écriture avant l'expérience §11 |
| 6 | interface de bureau Qt/QML | terminée — [conception](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` vérifiée physiquement ; modes d'effet implémentés ; enregistrement flash implémenté, test physique en attente |
| 8 | scènes | terminée — CLI + UI validées |
| 9 | diagnostics communautaires | terminée — [conception](docs/phase9-diagnostics.md) |
| 10 | MUX | recherche uniquement — [notes](docs/deferred-features-research.md) |

</details>

## Documentation

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — contrat d'API D-Bus
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — protocole filaire MysticLight
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — inventaire de rétro-ingénierie
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — règles de sécurité pour contributeurs et agents
- [Wiki du projet](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — installation, modèle de sécurité, API D-Bus et FAQ sous forme consultable

## Dépendances

**OS pris en charge** — Linux uniquement. Développé et testé sur
Arch Linux et Ubuntu (la CI tourne sur `ubuntu-latest`) ; toute
distribution avec `systemd`, Polkit, D-Bus, Qt 6 et une chaîne
d'outils Rust récente devrait fonctionner. Les modules noyau
`msi-ec` et `msi_wmi_platform` sont requis pour la
télémétrie/écriture sur du matériel réel — le projet compile et
s'exécute quand même en lecture seule via l'environnement de test
sans eux.

**Paquets système indispensables**

| Paquet | Utilité |
|---|---|
| Chaîne d'outils Rust ≥ 1.75 (`cargo`) | compile toutes les crates Rust |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | interface de bureau |
| CMake ≥ 3.21 | compilation de l'interface Qt |
| `pkg-config` | localise `libusb-1.0` à la compilation |
| `libusb-1.0-0-dev` (en-têtes de dev) | backend HID RGB, lié statiquement à la compilation |
| `libudev-dev` | énumération matériel/appareils |
| `systemd`, `polkit`, `dbus` (exécution) | service du démon, verrouillage des privilèges, IPC |
| `libusb-1.0-0` (exécution) | dépendance d'exécution du backend HID RGB |

```bash
# Debian/Ubuntu (identique à la CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**Crates Rust clés** — `zbus` (D-Bus), `serde`/`serde_json`
(données + profils d'appareils), `hidapi` (backend
`linux-static-libusb` lié statiquement pour le RGB MysticLight —
voir la
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
si le paquet `hidapi` de votre distribution provoque des erreurs de
liaison). Graphe de dépendances complet dans `Cargo.lock` et dans
le `Cargo.toml` de chaque crate.

**Modules noyau utilisés** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(état sémantique EC, modes ventilateur, Cooler Boost, Super
Battery, webcam/touche Fn), `msi_wmi_platform`/hwmon (RPM réel du
ventilateur), `power_supply` Linux (état de la batterie et seuils
de charge).

**Projets consultés durant le développement** — matériel de
recherche/référence uniquement ; rien n'est intégré ni lié, et
chaque chemin d'écriture a été vérifié indépendamment avant sa mise
en production (voir le
[modèle de sécurité](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)) :

| Projet | Utilisé pour |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | connaissance des modèles/firmwares MSI, recherche EC/registres, courbes de ventilateur, méthodologie de vérification |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | sémantique Linux MSI EC/sysfs, modes, Cooler Boost, températures, niveaux de ventilateur et modèles pris en charge |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | comportement comparatif des fonctionnalités/UX MSI sous Linux |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | séparation des privilèges, concepts Polkit, contrôle du ventilateur, simulation et récupération |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | protocole USB/HID Katana Mystic Light et recherche RGB à 4 zones |
| [Noyau Linux](https://github.com/torvalds/linux) | référence d'implémentation prioritaire pour hwmon, power_supply, WMI, ACPI, HID, DRM et pilotes de plateforme |

## Avertissement — utilisation à vos risques et périls

Ce logiciel contrôle le matériel du portable via le contrôleur
embarqué (EC), les interfaces de charge de la batterie et un
contrôleur RGB USB HID. Des écritures incorrectes sur ces
interfaces peuvent provoquer instabilité, problèmes thermiques,
réduction de la durée de vie de la batterie, perte de données ou
dommages matériels/firmware.

**Ce projet est fourni « tel quel », sans garantie d'aucune sorte,
expresse ou implicite. Les auteurs et contributeurs n'assument
aucune responsabilité pour tout dommage, perte de données ou
dysfonctionnement résultant de l'utilisation de ce logiciel — y
compris les dommages à votre portable, votre batterie, votre
clavier ou tout autre matériel.**

Les mesures d'atténuation intégrées au projet (verrouillage
firmware, opt-ins par fonctionnalité, autorisation Polkit,
vérification par relecture, vérification physique sur l'appareil
de référence) réduisent le risque mais ne l'éliminent pas. Ce sont
des mesures d'ingénierie de bonne foi, pas des garanties.

- Les écritures de seuils de batterie, mode ventilateur, Cooler
  Boost, RGB, webcam, blocage webcam et touche Fn sont **activées
  par défaut** dans l'unité systemd installée (Super Battery et
  l'enregistrement flash RGB restent désactivés) ; ne les installez
  que si vous comprenez ce qu'elles font, et modifiez le fichier
  d'unité avant l'installation si vous voulez un comportement
  entièrement en lecture seule par défaut
- Le comportement n'est vérifié physiquement que sur le **MSI
  Katana 17 B13VGK** (EC `17L5EMS1.115`) ; les autres modèles sont
  verrouillés mais non vérifiés
- N'utilisez pas ce logiciel sur un portable dont vous ne pourriez
  pas vous permettre d'endommager, et n'activez jamais les opt-ins
  d'écriture sur du matériel critique
- En cas de doute, utilisez uniquement les fonctionnalités de
  télémétrie en lecture seule

**Soyez prudent. Vous êtes seul responsable des conséquences de
l'utilisation de ce logiciel.**

## Contribuer

Lisez d'abord
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md). Les
chemins d'écriture matérielle nécessitent une provenance, un
verrouillage et des enregistrements de vérification physique — les
PR qui les omettent ne seront pas fusionnées.

## Licence

Double licence [MIT](LICENSE-MIT) ou [Apache-2.0](LICENSE-APACHE),
à votre choix.
