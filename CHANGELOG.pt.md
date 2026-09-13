<p align="center">
  <sub>
    <a href="CHANGELOG.md">English</a> ·
    <a href="CHANGELOG.zh.md">简体中文</a> ·
    <a href="CHANGELOG.tr.md">Türkçe</a> ·
    <a href="CHANGELOG.de.md">Deutsch</a> ·
    <a href="CHANGELOG.fr.md">Français</a> ·
    <a href="CHANGELOG.sv.md">Svenska</a> ·
    <a href="CHANGELOG.it.md">Italiano</a> ·
    <b>Português</b> ·
    <a href="CHANGELOG.es.md">Español</a> ·
    <a href="CHANGELOG.ar.md">العربية</a> ·
    <a href="CHANGELOG.hi.md">हिन्दी</a> ·
    <a href="CHANGELOG.ja.md">日本語</a> ·
    <a href="CHANGELOG.ko.md">한국어</a>
  </sub>
</p>

> *Esta é uma tradução fornecida pela comunidade. Em caso de divergência, o `CHANGELOG.md` em inglês é a versão autoritativa.*

# Registro de alterações

Todas as mudanças relevantes deste projeto são documentadas neste arquivo. O formato segue de forma livre o [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), agrupado por fase de desenvolvimento em vez de incrementos estritos de versão semântica, já que este projeto é distribuído como um snapshot contínuo validado em relação a um único dispositivo de referência (MSI Katana 17 B13VGK, firmware `17L5EMS1.115`).

## [Unreleased]

### Adicionado
- Traduções da comunidade de `README.md` em 12 idiomas (chinês, turco, alemão, francês, sueco, italiano, português, espanhol, árabe, hindi, japonês e coreano) com um alternador de idiomas.
- Páginas traduzidas da wiki do GitHub e este changelog nos mesmos 12 idiomas.
- Seção `Dependencies` em `README.md` documentando os pacotes de sistema necessários, sistemas operacionais suportados, módulos de kernel e projetos de referência upstream.
- Aviso de divulgação de desenvolvimento assistido por IA ("vibecoded") em `README.md`.
- Badges de Rust/Platform/Wiki e layout do README reestruturado.

### Alterado
- As gravações de limite de bateria, modo de ventoinha, Cooler Boost, RGB, webcam, bloqueio da webcam e tecla Fn agora são habilitadas **por padrão** na unidade systemd instalada (Super Battery e o salvamento RGB não volátil continuam como opt-out).

### Corrigido
- `hidapi` vinculado estaticamente (`linux-static-libusb` backend) para corrigir falhas de CI e erros de linker dependentes da versão da distro quando o pacote de sistema `hidapi` é incompatível.
- O fluxo de CI instala `libhidapi-dev` para que o crate `hidapi` seja compilado corretamente.
- Corrigida a mensagem de negação do Polkit e adicionada cobertura para o caminho de falha da reversão.

## [0.2.0] — 2026-09-06

### Adicionado
- **Phase 9 — Community diagnostics**: comando `msicenter report` que produz um pacote de diagnóstico compartilhável sem números de série.
- **Phase 8 — Scenes**: conjuntos nomeados de gravações protegidas, comandos CLI `scene list|examples|apply`, exemplos de cenas (quiet / cool / battery saver / gaming rgb) e uma página Scenes na UI desktop com gatilhos opcionais de automação (boot, troca AC/bateria, nível da bateria, agendamento).
- **Phase 7 — RGB (MysticLight MS-1565)**: probe do controlador HID somente leitura, construtor de pacotes de protocolo com testes unitários, gravações protegidas não persistentes de `SetRgbColor` e de efeitos (breathing, rainbow, wave), `rgb-save` não volátil protegido e uma página de RGB do teclado na UI desktop.
- **Phase 6 — Qt/QML desktop UI**: cliente desktop completo de sete páginas (Overview, Cooling, Power, Battery, Keyboard RGB, Scenes, Diagnostics) com redesign em estilo Material, navegação por barra lateral, cartão térmico hero, visualizações detalhadas por núcleo de CPU e por GPU, ações rápidas persistentes, menus de automação recolhíveis, status de conexão/atualização e uma barra de toast para ações pendentes.
- Relatório completo de temperatura/carga por núcleo da CPU e detalhes por GPU de ponta a ponta (core → daemon → UI).
- Ícone de bandeja do sistema com dica ao vivo de temperatura/RPM, ações rápidas e atalhos de teclado (Ctrl+Shift+C/B/L/P).

### Alterado
- Verificações de proteção de escrita unificadas entre os handlers de gravação do daemon e adicionados testes de disponibilidade.
- Relaxado o pin de versão de `zbus`.

## [0.1.0] — 2026-09-05

### Adicionado
- **Phase 0–2 — Read-only foundation**: descoberta de hardware, uma base Rust somente leitura, banco de dados de dispositivos (`msi-device-db`), relatório de capacidades em tempo de execução e uma fixture com sysroot falso para desenvolvimento e testes sem hardware (`MSI_LINUX_CENTER_SYSROOT`).
- **Phase 3 — D-Bus daemon**: serviço systemd `msi-daemon`, política D-Bus e ações do Polkit protegendo cada método privilegiado.
- **Phase 4 — Safe, gated writes**: caminhos de escrita para limite de carga da bateria, modo de ventoinha (auto/silent/advanced), Cooler Boost e Super Battery, cada um protegido por correspondência de firmware, variável de ambiente opt-in por recurso, autorização Polkit e verificação por leitura de retorno com reversão em caso de falha. Os quatro caminhos de escrita foram verificados fisicamente no dispositivo de referência MSI Katana 17 B13VGK em 2026-09-05.
- Cliente de linha de comando `msicenter-cli` (`status`, `capabilities` e os subcomandos protegidos de escrita).
- Regras de segurança em `MSI-Linux-Center-AGENTS.md` para contribuidores e agentes de codificação com IA.
- Estudos de design para recursos adiados: curvas de ventoinha personalizadas (Phase 5, apenas design, aguardando um experimento de reversão de tabela EC com consentimento) e troca de GPU MUX (apenas pesquisa).

[Unreleased]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mberkanbicer/MSI-Katana-Center/releases/tag/v0.2.0
[0.1.0]: https://github.com/mberkanbicer/MSI-Katana-Center/compare/aef171d...v0.2.0
