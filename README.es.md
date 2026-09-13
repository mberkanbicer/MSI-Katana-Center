<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — gestión nativa de Linux, con puertas de seguridad, de ventiladores, batería y RGB del teclado para portátiles MSI, verificada en el Katana 17 B13VGK">
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
    <b>Español</b> ·
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
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#dependencias)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> Este archivo es una traducción proporcionada por la comunidad. En
> caso de discrepancia, prevalece el [README en inglés](README.md).

Gestión de hardware nativa de Linux y de código abierto para
portátiles MSI. Desarrollado sobre el **MSI Katana 17 B13VGK**
(placa MS-17L5, EC `17L5EMS1.115`) como dispositivo de referencia.
Núcleo en Rust, demonio D-Bus, cliente de escritorio Qt/QML.

Cada escritura de hardware está bloqueada por coincidencia de
firmware, autorizada por Polkit, es opt-in por función, se verifica
mediante relectura y solo se habilita tras la verificación física
en el portátil de referencia. Las reglas están en
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **Aviso de desarrollo asistido por IA:** este proyecto está
> completamente "vibecoded" — cada commit fue escrito por un agente
> de codificación de IA que seguía las reglas de
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md),
> mientras un humano definía el alcance, revisaba los cambios y
> bloqueaba cada escritura de hardware tras una confirmación
> explícita antes de ejecutarla en hardware real. Ninguna línea de
> código, documento de diseño o registro de verificación física se
> generó sin esa revisión humana. Esto no cambia el
> [descargo de responsabilidad](#descargo-de-responsabilidad--úselo-bajo-su-propio-riesgo)
> que aparece más abajo: úselo bajo su propio riesgo, y lea los
> mecanismos de seguridad antes de habilitar cualquier opt-in de
> escritura.

## Interfaz en acción

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="Vista general del sistema: temperaturas de CPU/GPU, carga de la batería, modo del ventilador y RPM en vivo en el Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Recorrido por las páginas: Refrigeración, Energía, Batería, RGB del teclado, Escenas y Diagnóstico">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Página de RGB del teclado con vista previa de zonas MysticLight MS-1565">
</p>

## Qué es

Una aplicación Center de escritorio y una herramienta CLI que leen
el estado de modo/ventilador del EC, temperaturas, RPM y estado de
la batería — y, cuando lo activa (opt-in), aplica un pequeño
conjunto de escrituras verificadas: umbrales de carga, modo del
ventilador, Cooler Boost, Super Battery, cámara web/teclas Fn y RGB
MysticLight.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="La interfaz Qt/QML y la CLI se comunican mediante D-Bus y Polkit con msi-daemon, que a su vez accede a msi-ec, hwmon, la interfaz de batería y el RGB MysticLight">
</p>

## Características

- **Telemetría de solo lectura** — modos de EC/ventilador,
  temperaturas de CPU/GPU, temperatura/carga por núcleo,
  temperatura/carga por GPU, niveles del ventilador y RPM real,
  estado de la batería y umbrales de carga, informe de capacidades
  en tiempo de ejecución
- **Escrituras bloqueadas y verificadas** — umbrales de carga de la
  batería, modo del ventilador, Cooler Boost, Super Battery, cámara
  web/bloqueo de cámara web, intercambio de teclas Fn/Win
- **RGB del teclado** — color fijo y efectos MysticLight MS-1565
  (respiración, ciclo, onda), no persistente por defecto; guardar
  en flash requiere un opt-in independiente
- **Escenas** — paquetes con nombre de las escrituras bloqueadas,
  con aplicación/importación/exportación desde CLI y UI, ejemplos
  iniciales (Silencioso / Fresco / Ahorro de batería / Luces de
  juego), automatización opcional al iniciar/red-batería/nivel de
  batería/programación (todo opt-in, todo gestionado por la UI)
- **Icono de bandeja del sistema** — información sobre temperaturas
  y RPM en vivo, acciones rápidas, atajos de teclado
  (Ctrl+Mayús+C/B/L/P)
- **Interfaz de escritorio** — siete páginas (Vista general,
  Refrigeración, Energía, Batería, RGB del teclado, Escenas,
  Diagnóstico) con una tarjeta térmica principal, acciones
  primarias fijas, un acordeón de automatización de escenas,
  estado de conexión/desactualización y un banner de acciones en
  cola
- **Diagnóstico comunitario** — `msicenter report` sin números de
  serie para solicitudes de soporte ascendente
- **Entorno de prueba con sysroot ficticio** — desarrollo y pruebas
  sin hardware mediante `MSI_LINUX_CENTER_SYSROOT`

## Instalación

Compila el demonio, la CLI y la interfaz Qt en modo release, y
luego instala systemd, Polkit, la política D-Bus, el archivo
desktop y (por defecto) el autoarranque de sesión. La unidad
systemd incluida habilita por defecto los opt-in de escritura de
batería, modo del ventilador, cooler-boost, RGB, cámara web,
bloqueo de cámara web y tecla fn; Super Battery y el guardado en
flash de RGB permanecen desactivados. Independientemente de estos
valores predeterminados, cada escritura sigue bloqueada por Polkit
en el demonio, coincide exactamente con el firmware y se verifica
mediante relectura/reversión — edite
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
antes de instalar si desea un comportamiento predeterminado
totalmente de solo lectura.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` no elimina `~/.config/msi-linux-center`. El prefijo por
defecto es `/usr` (`PREFIX`, `SYSCONFDIR`).

### Requisitos

- Cadena de herramientas Rust (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- Linux con los módulos del kernel `msi-ec` y `msi_wmi_platform`
  para hardware real (tanto la ruta de lectura como la de escritura
  se degradan con elegancia si no están presentes)

Consulte [Dependencias](#dependencias) más abajo para conocer los
paquetes de sistema exactos y los sistemas operativos compatibles.

### Compilar desde el código fuente

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Ejecución

Contra el entorno de prueba incluido (no se necesita hardware):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

En modo de solo lectura en el portátil real:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

**No** ejecute la CLI con sudo. Las escrituras privilegiadas solo
las realiza el demonio tras la autorización de Polkit.

## Comandos de escritura (bloqueados)

Cada comando requiere que el demonio se ejecute con el opt-in
correspondiente (`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) y completa
una solicitud de Polkit:

```bash
msicenter battery-thresholds START END      # p. ej. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # no persistente
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # guardado en flash persistente (opt-in independiente)
msicenter panic-reset                       # Cooler Boost desactivado, Super Battery desactivada, ventilador automático
msicenter scene list|examples|apply NAME
```

Con el opt-in desactivado, el demonio rechaza la solicitud con
`NotSupported`. El alcance exacto de soporte, los bloqueos y los
registros de verificación física están en
[`docs/dbus-contract.md`](docs/dbus-contract.md) y en los archivos
`docs/phase4-*-validation.md`.

## Modelo de seguridad

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Seis puertas de escritura: coincidencia de firmware, opt-in, Polkit, relectura, verificación física en el Katana 17 B13VGK, y ningún registro no documentado">
</p>

1. **Puerta de firmware** — las escrituras solo se ejecutan cuando
   el firmware del EC del dispositivo coincide exactamente con una
   cadena de firmware verificada físicamente
2. **Puerta de opt-in** — cada familia de escritura depende de su
   propia variable de entorno del demonio; la unidad systemd
   incluida habilita por defecto batería, modo del ventilador,
   cooler-boost, RGB, cámara web, bloqueo de cámara web y tecla fn
   (Super Battery y el guardado en flash de RGB permanecen
   desactivados)
3. **Puerta Polkit** — cada método de escritura D-Bus se asigna a
   una acción de Polkit
4. **Verificación por relectura** — las escrituras de EC y batería
   se releen y verifican; las escrituras fallidas se revierten
5. **Verificación física** — una ruta de escritura solo se publica
   después de haberse probado en el portátil de referencia y
   documentado en `docs/`
6. **Sin suposiciones** — nunca se escribe en registros no
   documentados; la procedencia de cada función de hardware queda
   registrada en el perfil del dispositivo

## Dispositivos compatibles

| Dispositivo | Estado |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | dispositivo de referencia verificado |
| Otros portátiles MSI con `msi-ec` | solo telemetría de solo lectura; escrituras bloqueadas por coincidencia exacta de firmware |
| Modelos no coincidentes | solo lectura + informe de diagnóstico; soporte de la comunidad mediante `msicenter report` |

<details>
<summary>Estado de las fases</summary>

| Fase | Alcance | Estado |
|---|---|---|
| 0 | reconocimiento de hardware de solo lectura | completada |
| 1–2 | núcleo de solo lectura, base de datos de dispositivos, capacidades en tiempo de ejecución, entorno de prueba | completada |
| 3 | demonio D-Bus, unidad systemd, política D-Bus, acciones Polkit | completada |
| 4 | escrituras semánticas bloqueadas (umbrales de batería, modo del ventilador, Cooler Boost, Super Battery) | completada — verificada físicamente el 05/09/2026 |
| 5 | curvas de ventilador personalizadas | [estudio de diseño](docs/phase5-fan-curve-design.md) — sin escrituras hasta completar el experimento §11 |
| 6 | interfaz de escritorio Qt/QML | completada — [diseño](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` verificado físicamente; modos de efecto implementados; guardado en flash implementado, prueba física pendiente |
| 8 | escenas | completada — CLI + UI validadas |
| 9 | diagnóstico comunitario | completada — [diseño](docs/phase9-diagnostics.md) |
| 10 | MUX | solo investigación — [notas](docs/deferred-features-research.md) |

</details>

## Documentación

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — contrato de la API D-Bus
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — protocolo MysticLight
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — inventario de ingeniería inversa
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — reglas de seguridad para colaboradores y agentes
- [Wiki del proyecto](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — instalación, modelo de seguridad, API D-Bus y preguntas frecuentes en formato navegable

## Dependencias

**Sistemas operativos compatibles** — Solo Linux. Desarrollado y
probado en Arch Linux y Ubuntu (la CI se ejecuta en
`ubuntu-latest`); cualquier distribución con `systemd`, Polkit,
D-Bus, Qt 6 y una cadena de herramientas Rust reciente debería
funcionar. Los módulos del kernel `msi-ec` y `msi_wmi_platform` son
necesarios para la telemetría/escritura en hardware real — el
proyecto igualmente se compila y se ejecuta en modo de solo
lectura mediante el entorno de prueba sin ellos.

**Paquetes del sistema imprescindibles**

| Paquete | Propósito |
|---|---|
| Cadena de herramientas Rust ≥ 1.75 (`cargo`) | compila todos los crates de Rust |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | interfaz de escritorio |
| CMake ≥ 3.21 | compilación de la interfaz Qt |
| `pkg-config` | localiza `libusb-1.0` en tiempo de compilación |
| `libusb-1.0-0-dev` (cabeceras de desarrollo) | backend HID RGB, enlazado estáticamente en tiempo de compilación |
| `libudev-dev` | enumeración de hardware/dispositivos |
| `systemd`, `polkit`, `dbus` (en tiempo de ejecución) | servicio del demonio, bloqueo de privilegios, IPC |
| `libusb-1.0-0` (en tiempo de ejecución) | dependencia en tiempo de ejecución del backend HID RGB |

```bash
# Debian/Ubuntu (igual que la CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**Crates de Rust clave** — `zbus` (D-Bus), `serde`/`serde_json`
(datos + perfiles de dispositivo), `hidapi` (backend
`linux-static-libusb` enlazado estáticamente para el RGB
MysticLight — consulte las
[preguntas frecuentes](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
si el paquete `hidapi` de su distribución llega a causar errores de
enlace). Gráfico de dependencias completo en `Cargo.lock` y en el
`Cargo.toml` de cada crate.

**Módulos del kernel utilizados** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(estado semántico del EC, modos del ventilador, Cooler Boost, Super
Battery, cámara web/tecla Fn), `msi_wmi_platform`/hwmon (RPM real
del ventilador), `power_supply` de Linux (estado de la batería y
umbrales de carga).

**Proyectos consultados durante el desarrollo** — solo material de
investigación/referencia; nada de esto se ha integrado ni enlazado,
y cada ruta de escritura se verificó de forma independiente antes
de publicarse (consulte el
[Modelo de seguridad](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| Proyecto | Utilizado para |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | conocimiento de modelos/firmware de MSI, investigación de EC/registros, curvas de ventilador, metodología de verificación |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | semántica de EC/sysfs de MSI en Linux, modos, Cooler Boost, temperaturas, niveles del ventilador y modelos compatibles |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | comportamiento comparativo de funciones/UX de MSI en Linux |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | separación de privilegios, conceptos de Polkit, control del ventilador, simulación y recuperación |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | protocolo USB/HID Katana Mystic Light e investigación de RGB de 4 zonas |
| [Kernel de Linux](https://github.com/torvalds/linux) | referencia de implementación de máxima prioridad para hwmon, power_supply, WMI, ACPI, HID, DRM y controladores de plataforma |

## Descargo de responsabilidad — úselo bajo su propio riesgo

Este software controla el hardware del portátil a través del
controlador embebido (EC), las interfaces de carga de la batería y
un controlador RGB USB HID. Las escrituras incorrectas en estas
interfaces pueden causar inestabilidad, problemas térmicos,
reducción de la vida útil de la batería, pérdida de datos o daños
en el hardware/firmware.

**Este proyecto se proporciona "tal cual", sin garantía de ningún
tipo, expresa o implícita. Los autores y colaboradores no asumen
ninguna responsabilidad por daños, pérdida de datos o mal
funcionamiento derivados del uso de este software — incluidos los
daños a su portátil, batería, teclado o cualquier otro hardware.**

Las medidas de mitigación incorporadas al proyecto (bloqueo de
firmware, opt-in por función, autorización de Polkit, verificación
por relectura, verificación física en el dispositivo de
referencia) reducen el riesgo, pero no lo eliminan. Son medidas de
ingeniería hechas de buena fe, no garantías.

- Las escrituras de umbrales de batería, modo del ventilador,
  Cooler Boost, RGB, cámara web, bloqueo de cámara web y tecla Fn
  están **habilitadas por defecto** en la unidad systemd instalada
  (Super Battery y el guardado en flash de RGB permanecen
  desactivados); instálelas solo si entiende lo que hacen, y edite
  el archivo de la unidad antes de instalar si desea un
  comportamiento predeterminado totalmente de solo lectura
- El comportamiento solo está verificado físicamente en el **MSI
  Katana 17 B13VGK** (EC `17L5EMS1.115`); otros modelos están
  bloqueados pero sin verificar
- No use este software en un portátil cuyo daño no pueda permitirse,
  y nunca habilite opt-in de escritura en hardware crítico
- Si no está seguro, use únicamente las funciones de telemetría de
  solo lectura

**Tenga cuidado. Usted es el único responsable de cualquier
consecuencia derivada del uso de este software.**

## Contribuir

Lea primero
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md). Las
rutas de escritura de hardware requieren procedencia, bloqueo y
registros de verificación física — los PR que omitan esto no se
fusionarán.

## Licencia

Doblemente licenciado bajo [MIT](LICENSE-MIT) o
[Apache-2.0](LICENSE-APACHE), a su elección.
