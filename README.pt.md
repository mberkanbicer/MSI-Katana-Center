<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="MSI Katana Center — gerenciamento nativo em Linux, com portões de segurança, de ventoinhas, bateria e RGB do teclado para laptops MSI, verificado no Katana 17 B13VGK">
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
    <b>Português</b> ·
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
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-informational.svg)](#dependências)
[![Wiki](https://img.shields.io/badge/docs-wiki-8957e5.svg)](https://github.com/mberkanbicer/MSI-Katana-Center/wiki)

> Este arquivo é uma tradução fornecida pela comunidade. Em caso de
> divergência, prevalece o [README em inglês](README.md).

Gerenciamento de hardware nativo em Linux e de código aberto para
laptops MSI. Desenvolvido com base no **MSI Katana 17 B13VGK**
(placa MS-17L5, EC `17L5EMS1.115`) como dispositivo de referência.
Núcleo em Rust, daemon D-Bus, cliente desktop Qt/QML.

Toda escrita de hardware é bloqueada por verificação de firmware,
autorizada pelo Polkit, opt-in por recurso, verificada por
releitura e só é habilitada após verificação física no laptop de
referência. As regras estão em
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).

> **Aviso de desenvolvimento assistido por IA:** este projeto é
> totalmente "vibecoded" — cada commit foi escrito por um agente de
> codificação de IA seguindo as regras em
> [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md), com um
> humano definindo o escopo, revisando as alterações e exigindo
> confirmação explícita antes de qualquer escrita de hardware ser
> executada em hardware real. Nenhuma linha de código, documento de
> design ou registro de verificação física foi gerado sem essa
> revisão humana. Isso não muda o
> [aviso legal](#aviso-legal--use-por-sua-conta-e-risco) abaixo: uso
> por sua conta e risco — leia os mecanismos de segurança antes de
> habilitar qualquer opt-in de escrita.

## Interface em ação

<p align="center">
  <img src="docs/screenshots/ui-overview.gif" width="100%" alt="Visão geral do sistema: temperaturas de CPU/GPU, carga da bateria, modo da ventoinha e RPM em tempo real no Katana 17">
</p>

<p align="center">
  <img src="docs/screenshots/ui-pages.gif" width="49%" alt="Tour pelas páginas: Resfriamento, Energia, Bateria, RGB do teclado, Cenas e Diagnóstico">
  <img src="docs/screenshots/ui-telemetry.gif" width="49%" alt="Página de RGB do teclado com prévia das zonas MysticLight MS-1565">
</p>

## O que é

Um aplicativo Center de desktop e uma ferramenta de CLI que lê o
estado de modo/ventoinha do EC, temperaturas, RPM e status da
bateria — e, quando você ativa (opt-in), aplica um pequeno conjunto
de escritas verificadas: limites de carga, modo da ventoinha,
Cooler Boost, Super Battery, webcam/teclas Fn e RGB MysticLight.

<p align="center">
  <img src="./assets/readme/architecture.svg" width="100%" alt="A interface Qt/QML e a CLI se comunicam via D-Bus e Polkit com o msi-daemon, que por sua vez acessa o msi-ec, hwmon, a interface de bateria e o RGB MysticLight">
</p>

## Funcionalidades

- **Telemetria somente leitura** — modos de EC/ventoinha,
  temperaturas de CPU/GPU, temperatura/carga por núcleo,
  temperatura/carga por GPU, níveis da ventoinha e RPM real, status
  da bateria e limites de carga, relatório de capacidades em tempo
  de execução
- **Escritas bloqueadas e verificadas** — limites de carga da
  bateria, modo da ventoinha, Cooler Boost, Super Battery, webcam/
  bloqueio de webcam, troca das teclas Fn/Win
- **RGB do teclado** — cor fixa e efeitos MysticLight MS-1565
  (respiração, ciclo, onda), não persistente por padrão; salvar em
  flash exige um opt-in separado
- **Cenas** — pacotes nomeados das escritas bloqueadas, com
  aplicação/importação/exportação via CLI e UI, exemplos iniciais
  (Silencioso / Fresco / Economia de bateria / Luzes gaming),
  automação opcional na inicialização/rede-bateria/nível de
  bateria/agendamento (tudo opt-in, tudo gerenciado pela UI)
- **Bandeja do sistema** — dica em tempo real de temperaturas/RPM,
  ações rápidas, atalhos de teclado (Ctrl+Shift+C/B/L/P)
- **Interface desktop** — sete páginas (Visão geral, Resfriamento,
  Energia, Bateria, RGB do teclado, Cenas, Diagnóstico) com um
  cartão térmico principal, ações primárias fixas, um acordeão de
  automação de cenas, status de conexão/desatualização e um banner
  de ações na fila
- **Diagnóstico da comunidade** — `msicenter report` sem números de
  série para solicitações de suporte upstream
- **Ambiente de teste com sysroot falso** — desenvolvimento e
  testes sem hardware via `MSI_LINUX_CENTER_SYSROOT`

## Instalação

Compila o daemon, a CLI e a interface Qt em modo release, depois
instala systemd, Polkit, política D-Bus, arquivo desktop e (por
padrão) autostart de sessão. A unidade systemd fornecida habilita
por padrão os opt-ins de escrita de bateria, modo da ventoinha,
cooler-boost, RGB, webcam, bloqueio de webcam e tecla fn; Super
Battery e o salvamento em flash de RGB permanecem desativados.
Independentemente desses padrões, toda escrita permanece bloqueada
pelo Polkit no daemon, com correspondência exata de firmware e
verificação por releitura/rollback — edite
[`data/systemd/system/msi-linux-center.service`](data/systemd/system/msi-linux-center.service)
antes de instalar se quiser um padrão totalmente somente leitura.

```bash
./scripts/setup.sh install
./scripts/setup.sh install --no-autostart
./scripts/setup.sh uninstall
```

`uninstall` não exclui `~/.config/msi-linux-center`. O prefixo
padrão é `/usr` (`PREFIX`, `SYSCONFDIR`).

### Requisitos

- Toolchain Rust (≥ 1.75)
- Qt 6 (Core, QML, Quick, DBus, QuickControls2, Widgets) +
  CMake ≥ 3.21
- Linux com os módulos de kernel `msi-ec` e `msi_wmi_platform` para
  hardware real (tanto o caminho de leitura quanto o de escrita
  degradam graciosamente na ausência deles)

Veja [Dependências](#dependências) abaixo para os pacotes de
sistema exatos e sistemas operacionais suportados.

### Compilar a partir do código-fonte

```bash
cargo build --release
cd crates/msicenter-ui && cmake -S . -B build && cmake --build build -j
```

## Execução

Contra o ambiente de teste incluído (nenhum hardware necessário):

```bash
./scripts/run-fixture.sh
./scripts/run-fixture.sh --json
```

Somente leitura no laptop real:

```bash
./scripts/run-local-readonly.sh
cargo run -p msicenter-cli -- status [--json]
cargo run -p msicenter-cli -- capabilities
```

**Não** execute a CLI com sudo. Escritas privilegiadas são
realizadas apenas pelo daemon após autorização do Polkit.

## Comandos de escrita (bloqueados)

Cada comando exige que o daemon esteja em execução com o opt-in
correspondente (`MSI_LINUX_CENTER_ENABLE_*_WRITES=1`) e completa um
prompt do Polkit:

```bash
msicenter battery-thresholds START END      # ex. 80 90
msicenter fan-mode auto|silent|advanced
msicenter cooler-boost on|off
msicenter super-battery on|off
msicenter webcam on|off
msicenter webcam-block on|off
msicenter fn-key left|right
msicenter rgb-color ZONE_MASK RRGGBB        # não persistente
msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS
msicenter rgb-save                          # salvamento em flash persistente (opt-in separado)
msicenter panic-reset                       # Cooler Boost desligado, Super Battery desligada, ventoinha automática
msicenter scene list|examples|apply NAME
```

Com o opt-in desativado, o daemon recusa com `NotSupported`. O
escopo exato de suporte, os bloqueios e os registros de verificação
física estão em
[`docs/dbus-contract.md`](docs/dbus-contract.md) e nos arquivos
`docs/phase4-*-validation.md`.

## Modelo de segurança

<p align="center">
  <img src="./assets/readme/safety.svg" width="100%" alt="Seis portões de escrita: correspondência de firmware, opt-in, Polkit, releitura, verificação física no Katana 17 B13VGK e nenhum registro não documentado">
</p>

1. **Portão de firmware** — as escritas só ocorrem quando o
   firmware do EC do dispositivo corresponde exatamente a uma
   string de firmware verificada fisicamente
2. **Portão de opt-in** — cada família de escrita depende de sua
   própria variável de ambiente do daemon; a unidade systemd
   fornecida habilita por padrão bateria, modo da ventoinha,
   cooler-boost, RGB, webcam, bloqueio de webcam e tecla fn (Super
   Battery e salvamento em flash de RGB permanecem desativados)
3. **Portão Polkit** — cada método de escrita D-Bus é mapeado para
   uma ação do Polkit
4. **Verificação por releitura** — escritas de EC e bateria são
   relidas e verificadas; escritas com falha são revertidas
5. **Verificação física** — um caminho de escrita só é lançado após
   ser testado no laptop de referência e registrado em `docs/`
6. **Nada de suposições** — registros não documentados nunca são
   escritos; a origem de cada funcionalidade de hardware é
   registrada no perfil do dispositivo

## Dispositivos suportados

| Dispositivo | Status |
|---|---|
| MSI Katana 17 B13VGK (MS-17L5, EC `17L5EMS1.115`) | dispositivo de referência verificado |
| Outros laptops MSI com `msi-ec` | apenas telemetria somente leitura; escritas bloqueadas por correspondência exata de firmware |
| Modelos não correspondentes | apenas leitura + relatório de diagnóstico; suporte da comunidade via `msicenter report` |

<details>
<summary>Status das fases</summary>

| Fase | Escopo | Status |
|---|---|---|
| 0 | reconhecimento de hardware somente leitura | concluída |
| 1–2 | núcleo somente leitura, banco de dados de dispositivos, capacidades em tempo de execução, ambiente de teste | concluída |
| 3 | daemon D-Bus, unidade systemd, política D-Bus, ações Polkit | concluída |
| 4 | escritas semânticas bloqueadas (limites de bateria, modo da ventoinha, Cooler Boost, Super Battery) | concluída — verificada fisicamente em 05/09/2026 |
| 5 | curvas de ventoinha personalizadas | [estudo de design](docs/phase5-fan-curve-design.md) — nenhuma escrita até a conclusão do experimento §11 |
| 6 | interface desktop Qt/QML | concluída — [design](docs/phase6-ui-design.md) |
| 7 | RGB (MysticLight MS-1565) | `SetRgbColor` verificado fisicamente; modos de efeito implementados; salvamento em flash implementado, teste físico pendente |
| 8 | cenas | concluída — CLI + UI validadas |
| 9 | diagnóstico da comunidade | concluída — [design](docs/phase9-diagnostics.md) |
| 10 | MUX | apenas pesquisa — [notas](docs/deferred-features-research.md) |

</details>

## Documentação

- [`docs/dbus-contract.md`](docs/dbus-contract.md) — contrato de API D-Bus
- [`docs/phase7-rgb-protocol.md`](docs/phase7-rgb-protocol.md) — protocolo MysticLight
- [`docs/reverse-engineering-inventory.md`](docs/reverse-engineering-inventory.md) — inventário de engenharia reversa
- [`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md) — regras de segurança para contribuidores e agentes
- [Wiki do projeto](https://github.com/mberkanbicer/MSI-Katana-Center/wiki) — instalação, modelo de segurança, API D-Bus e FAQ em formato navegável

## Dependências

**Sistemas operacionais suportados** — Apenas Linux. Desenvolvido e
testado no Arch Linux e no Ubuntu (a CI roda em `ubuntu-latest`);
qualquer distribuição com `systemd`, Polkit, D-Bus, Qt 6 e uma
toolchain Rust recente deve funcionar. Os módulos de kernel
`msi-ec` e `msi_wmi_platform` são necessários para
telemetria/escrita em hardware real — o projeto ainda compila e
roda somente leitura via ambiente de teste sem eles.

**Pacotes de sistema indispensáveis**

| Pacote | Finalidade |
|---|---|
| Toolchain Rust ≥ 1.75 (`cargo`) | compila todas as crates Rust |
| Qt 6 ≥ 6.4 (Core, Gui, Qml, Quick, DBus, QuickControls2, Widgets) | interface desktop |
| CMake ≥ 3.21 | compilação da interface Qt |
| `pkg-config` | localiza `libusb-1.0` no momento da compilação |
| `libusb-1.0-0-dev` (headers de desenvolvimento) | backend HID RGB, vinculado estaticamente na compilação |
| `libudev-dev` | enumeração de hardware/dispositivos |
| `systemd`, `polkit`, `dbus` (runtime) | serviço do daemon, bloqueio de privilégios, IPC |
| `libusb-1.0-0` (runtime) | dependência de runtime do backend HID RGB |

```bash
# Debian/Ubuntu (igual à CI)
sudo apt-get install -y pkg-config libusb-1.0-0-dev libudev-dev

# Arch
sudo pacman -S base-devel cmake qt6-base qt6-declarative libusb systemd polkit
```

**Crates Rust principais** — `zbus` (D-Bus), `serde`/`serde_json`
(dados + perfis de dispositivo), `hidapi` (backend
`linux-static-libusb` vinculado estaticamente para o RGB
MysticLight — veja o
[FAQ](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/FAQ-and-Troubleshooting#the-daemon-wont-start--build-fails-on-hidapi)
caso o pacote `hidapi` da sua distribuição cause erros de link).
Grafo completo de dependências no `Cargo.lock` e no `Cargo.toml`
de cada crate.

**Módulos de kernel utilizados** — [`msi-ec`](https://github.com/BeardOverflow/msi-ec)
(estado semântico do EC, modos da ventoinha, Cooler Boost, Super
Battery, webcam/tecla Fn), `msi_wmi_platform`/hwmon (RPM real da
ventoinha), `power_supply` do Linux (status da bateria e limites de
carga).

**Projetos consultados durante o desenvolvimento** — apenas
material de pesquisa/referência; nada aqui é incorporado ou
vinculado, e cada caminho de escrita foi verificado de forma
independente antes de ser lançado (veja o
[Modelo de Segurança](https://github.com/mberkanbicer/MSI-Katana-Center/wiki/Safety-Model)):

| Projeto | Usado para |
|---|---|
| [GhostDeck](https://github.com/wygodad/ghostdeck) | conhecimento de modelo/firmware da MSI, pesquisa de EC/registradores, curvas de ventoinha, metodologia de verificação |
| [msi-ec](https://github.com/BeardOverflow/msi-ec) | semântica Linux MSI EC/sysfs, modos, Cooler Boost, temperaturas, níveis de ventoinha e modelos suportados |
| [MControlCenter](https://github.com/dmitry-s93/MControlCenter) | comportamento comparativo de recursos/UX da MSI no Linux |
| [OpenFreezeCenter](https://github.com/YoCodingMonster/OpenFreezeCenter) | separação de privilégios, conceitos do Polkit, controle de ventoinha, simulação e recuperação |
| [msi-katana-rgb](https://github.com/sarpowsky/msi-katana-rgb) | protocolo USB/HID Katana Mystic Light e pesquisa de RGB de 4 zonas |
| [Kernel Linux](https://github.com/torvalds/linux) | referência de implementação de maior prioridade para hwmon, power_supply, WMI, ACPI, HID, DRM e drivers de plataforma |

## Aviso legal — use por sua conta e risco

Este software controla o hardware do laptop através do controlador
embutido (EC), interfaces de carga da bateria e um controlador RGB
USB HID. Escritas incorretas nessas interfaces podem causar
instabilidade, problemas térmicos, redução da vida útil da bateria,
perda de dados ou danos ao hardware/firmware.

**Este projeto é fornecido "como está", sem garantia de qualquer
tipo, expressa ou implícita. Os autores e contribuidores não
assumem nenhuma responsabilidade por qualquer dano, perda de dados
ou mau funcionamento decorrente do uso deste software — incluindo
danos ao seu laptop, bateria, teclado ou qualquer outro hardware.**

As mitigações incorporadas ao projeto (bloqueio por firmware,
opt-ins por recurso, autorização do Polkit, verificação por
releitura, verificação física no dispositivo de referência) reduzem
o risco, mas não o eliminam. São medidas de engenharia feitas com o
melhor esforço, não garantias.

- As escritas de limites de bateria, modo da ventoinha, Cooler
  Boost, RGB, webcam, bloqueio de webcam e tecla Fn estão
  **habilitadas por padrão** na unidade systemd instalada (Super
  Battery e salvamento em flash de RGB permanecem desativados);
  instale-as apenas se você entender o que elas fazem, e edite o
  arquivo de unidade antes de instalar se quiser um padrão
  totalmente somente leitura
- O comportamento é verificado fisicamente apenas no **MSI Katana
  17 B13VGK** (EC `17L5EMS1.115`); outros modelos são bloqueados
  mas não verificados
- Não use este software em um laptop que você não pode se dar ao
  luxo de danificar, e nunca habilite opt-ins de escrita em
  hardware crítico
- Se você não tiver certeza, use apenas os recursos de telemetria
  somente leitura

**Tenha cuidado. Você é o único responsável por quaisquer
consequências do uso deste software.**

## Contribuindo

Leia primeiro
[`MSI-Linux-Center-AGENTS.md`](MSI-Linux-Center-AGENTS.md).
Caminhos de escrita de hardware exigem procedência, bloqueio e
registros de verificação física — PRs que pularem isso não serão
mesclados.

## Licença

Licenciado de forma dupla sob [MIT](LICENSE-MIT) ou
[Apache-2.0](LICENSE-APACHE), à sua escolha.
