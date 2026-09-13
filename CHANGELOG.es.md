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
    <b>Español</b> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *Esta es una traducción proporcionada por la comunidad. En caso de conflicto, el `CHANGELOG.md` en inglés es la versión autorizada.*

# Registro de cambios

Todos los cambios relevantes de este proyecto se documentan en este archivo. El formato sigue de forma flexible [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), agrupado por fase de desarrollo en lugar de incrementos estrictos de versión semántica, ya que este proyecto se publica como una instantánea continua validada frente a un único dispositivo de referencia (MSI Katana 17 B13VGK, firmware `17L5EMS1.115`).

## [Unreleased]

### Añadido
- Traducciones comunitarias de `README.md` a 12 idiomas (chino, turco, alemán, francés, sueco, italiano, portugués, español, árabe, hindi, japonés y coreano) con un selector de idioma.
- Páginas traducidas de la wiki de GitHub y este changelog en esos mismos 12 idiomas.
- Sección `Dependencies` en `README.md` que documenta los paquetes del sistema necesarios, los sistemas operativos compatibles, los módulos del kernel y los proyectos de referencia upstream.
- Aviso de divulgación sobre desarrollo asistido por IA ("vibecoded") en `README.md`.
- Badges de Rust/Platform/Wiki y reorganización del diseño del README.

### Cambiado
- Las escrituras de umbral de batería, modo de ventilador, Cooler Boost, RGB, webcam, bloqueo de webcam y tecla Fn ahora están habilitadas **por defecto** en la unidad systemd instalada (Super Battery y el guardado RGB no volátil siguen siendo opt-out).

### Corregido
- `hidapi` enlazado estáticamente (`linux-static-libusb` backend) para corregir fallos de CI y errores del enlazador dependientes de la versión de la distro cuando el paquete del sistema `hidapi` es incompatible.
- El flujo de CI instala `libhidapi-dev` para que el crate `hidapi` compile correctamente.
- Corregido el mensaje de denegación de Polkit y añadida cobertura para la ruta de fallo de la reversión.

## [0.2.0] — 2026-09-06

### Añadido
- **Phase 9 — Community diagnostics**: comando `msicenter report` que genera un paquete de diagnóstico compartible sin números de serie.
- **Phase 8 — Scenes**: conjuntos con nombre de escrituras protegidas, comandos CLI `scene list|examples|apply`, escenas de ejemplo (quiet / cool / battery saver / gaming rgb) y una página Scenes en la UI de escritorio con desencadenadores opcionales de automatización (arranque, cambio AC/batería, nivel de batería, horario).
- **Phase 7 — RGB (MysticLight MS-1565)**: sonda del controlador HID de solo lectura, generador de paquetes del protocolo con pruebas unitarias, escrituras protegidas no persistentes de `SetRgbColor` y efectos (breathing, rainbow, wave), `rgb-save` no volátil protegido y una página de RGB del teclado en la UI de escritorio.
- **Phase 6 — Qt/QML desktop UI**: cliente de escritorio completo de siete páginas (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes, Diagnostics) con rediseño estilo Material, navegación lateral, tarjeta térmica destacada, vistas detalladas por núcleo de CPU y por GPU, acciones rápidas fijas, menús de automatización plegables, estado de conexión/actualización y una barra toast para acciones pendientes.
- Informe completo de temperatura/carga por núcleo de CPU y de detalles por GPU de extremo a extremo (core → daemon → UI).
- Icono de bandeja del sistema con información en vivo de temperatura/RPM, acciones rápidas y atajos de teclado (Ctrl+Shift+C/B/L/P).

### Cambiado
- Se unificaron las comprobaciones de barreras de escritura entre los handlers de escritura del daemon y se añadieron pruebas de disponibilidad.
- Se relajó el pin de versión de `zbus`.

## [0.1.0] — 2026-09-05

### Añadido
- **Phase 0–2 — Read-only foundation**: detección de hardware, una base Rust de solo lectura, base de datos de dispositivos (`msi-device-db`), informe de capacidades en tiempo de ejecución y una fixture con sysroot falso para desarrollo y pruebas sin hardware (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: servicio systemd `msi-daemon`, política D-Bus y acciones de Polkit que protegen cada método privilegiado.
- **Phase 4 — Safe, gated writes**: rutas de escritura para umbral de carga de batería, modo de ventilador (auto/silent/advanced), Cooler Boost y Super Battery, cada una protegida por coincidencia de firmware, variable de entorno opt-in por función, autorización de Polkit y verificación mediante lectura de confirmación con reversión en caso de fallo. Las cuatro rutas de escritura se verificaron físicamente en el dispositivo de referencia MSI Katana 17 B13VGK el 2026-09-05.
- Cliente de línea de comandos `msicenter-cli` (`status`, `capabilities` y los subcomandos de escritura protegidos).
- Reglas de seguridad de `MSI-Linux-Center-AGENTS.md` para colaboradores y agentes de codificación con IA.
- Estudios de diseño para funciones aplazadas: curvas de ventilador personalizadas (Phase 5, solo diseño, pendiente de un experimento de reversión de tabla EC con consentimiento) y conmutación de GPU MUX (solo investigación).

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
