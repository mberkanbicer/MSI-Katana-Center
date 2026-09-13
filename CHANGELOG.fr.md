<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <b>Français</b> ·
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

> *Cette traduction est fournie par la communauté. En cas de divergence, la version anglaise `CHANGELOG.md` fait autorité.*

# Journal des modifications

Tous les changements notables de ce projet sont documentés dans ce
fichier. Le format suit librement [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
regroupé par phase de développement plutôt que par incréments stricts de
version sémantique, car ce projet est livré sous forme d'instantané
continu validé sur un seul appareil de référence (MSI Katana 17 B13VGK,
firmware `17L5EMS1.115`).

## [Non publié]

### Ajouts
- Traductions communautaires de `README.md` en 12 langues (chinois,
  turc, allemand, français, suédois, italien, portugais, espagnol,
  arabe, hindi, japonais, coréen) avec un sélecteur de langue.
- Traduction des pages du wiki GitHub et de ce journal des modifications
  dans les mêmes 12 langues.
- Section `Dependencies` dans `README.md` documentant les paquets
  système requis, les OS pris en charge, les modules noyau et les
  projets de référence amont.
- Mention de divulgation du développement assisté par IA
  (« vibecoded ») dans `README.md`.
- Badges Rust/Platform/Wiki et restructuration de la mise en page du
  README.

### Modifications
- Les écritures battery threshold, fan-mode, Cooler Boost, RGB, webcam,
  webcam block et fn-key sont désormais activées **par défaut** dans
  l'unité systemd installée (Super Battery et l'enregistrement RGB non
  volatil restent désactivables).

### Corrections
- Liaison statique de `hidapi` (backend `linux-static-libusb`) pour
  corriger les échecs CI et les erreurs de linkage liées aux versions de
  distribution lorsque le paquet système `hidapi` est incompatible.
- Le workflow CI installe `libhidapi-dev` afin que la crate `hidapi` se
  compile proprement.
- Correction du message de refus Polkit et ajout de couverture pour le
  chemin d'échec du rollback.

## [0.2.0] — 2026-09-06

### Ajouts
- **Phase 9 — Diagnostics communautaires** : commande `msicenter report`
  produisant une archive de diagnostic partageable sans numéros de
  série.
- **Phase 8 — Scènes** : bundles nommés d'écritures protégées, commandes
  CLI `scene list|examples|apply`, scènes d'exemple (quiet / cool /
  battery saver / gaming rgb) et une page Scenes dans l'UI bureau avec
  déclencheurs d'automatisation facultatifs (boot, bascule secteur/
  batterie, niveau de batterie, planification).
- **Phase 7 — RGB (MysticLight MS-1565)** : sonde en lecture seule du
  contrôleur HID, générateur de paquets de protocole avec tests unitaires,
  écritures protégées non persistantes `SetRgbColor` et d'effets
  (breathing, rainbow, wave), `rgb-save` non volatil protégé, et page RGB
  clavier dans l'UI bureau.
- **Phase 6 — UI bureau Qt/QML** : client bureau complet de sept pages
  (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes,
  Diagnostics) avec refonte au style Material, navigation latérale,
  carte thermique héro, vues détaillées CPU par cœur / GPU par GPU,
  actions rapides persistantes, menus d'automatisation repliables,
  état de connexion/rafraîchissement et barre toast pour les actions en
  attente.
- Rapport détaillé de température/charge CPU par cœur et GPU par GPU de
  bout en bout (core → daemon → UI).
- Icône de zone de notification avec infobulle température/RPM en
  direct, actions rapides et raccourcis clavier (Ctrl+Shift+C/B/L/P).

### Modifications
- Vérifications de gate d'écriture unifiées dans l'ensemble des handlers
  d'écriture du daemon et ajout de tests de disponibilité.
- Assouplissement du verrouillage de version `zbus`.

## [0.1.0] — 2026-09-05

### Ajouts
- **Phase 0–2 — Fondation en lecture seule** : découverte matérielle,
  cœur Rust en lecture seule, base de données des appareils
  (`msi-device-db`), rapport de capacités à l'exécution et fixture fake-
  sysroot pour développement et tests sans matériel
  (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — Daemon D-Bus** : service systemd `msi-daemon`, politique
  D-Bus et actions Polkit protégeant chaque méthode privilégiée.
- **Phase 4 — Écritures sûres et protégées** : seuil de charge batterie,
  mode de ventilation (auto/silent/advanced), Cooler Boost et chemins
  d'écriture Super Battery, chacun protégé par correspondance exacte du
  firmware, variable d'opt-in par fonctionnalité, autorisation Polkit et
  vérification par relecture avec rollback en cas d'échec. Les quatre
  chemins d'écriture ont été vérifiés physiquement sur l'appareil de
  référence MSI Katana 17 B13VGK le 2026-09-05.
- Client en ligne de commande `msicenter-cli` (`status`, `capabilities`
  et les sous-commandes d'écriture protégées).
- Règles de sécurité `MSI-Linux-Center-AGENTS.md` pour les contributeurs
  et les agents de codage IA.
- Études de conception pour des fonctionnalités différées : courbes de
  ventilation personnalisées (Phase 5, conception uniquement en attente
  d'une expérience de rollback de table EC soumise à consentement) et
  commutation GPU MUX (recherche uniquement).

[Non publié]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
