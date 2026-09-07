#!/usr/bin/env bash
# Build, install, or remove MSI Linux Center.
# Write opt-ins stay off. Privileged writes remain Polkit-gated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PREFIX:-/usr}"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
UI_BUILD="$ROOT/crates/msicenter-ui/build"
AUTOSTART=1
JOBS="$(nproc 2>/dev/null || echo 4)"

usage() {
    cat <<EOF
Usage: $0 build|install|uninstall [--no-autostart]

  build       Compile daemon, CLI (release) and the Qt UI
  install     Build, then install system files with sudo
  uninstall   Stop the unit and remove installed files (sudo)
              Does not delete ~/.config/msi-linux-center

Options:
  --no-autostart   Skip /etc/xdg/autostart on install

Environment:
  PREFIX=$PREFIX
  SYSCONFDIR=$SYSCONFDIR
EOF
}

as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

CMD=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        build | install | uninstall) CMD="$1" ;;
        --no-autostart) AUTOSTART=0 ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

build() {
    echo "==> cargo release (msi-daemon, msicenter)"
    cargo build --manifest-path "$ROOT/Cargo.toml" --release \
        -p msi-daemon -p msicenter-cli

    echo "==> Qt UI (Release)"
    cmake -S "$ROOT/crates/msicenter-ui" -B "$UI_BUILD" \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build "$UI_BUILD" -j"$JOBS"
}

unit_path() {
    echo "${SYSCONFDIR}/systemd/system/msi-linux-center.service"
}

install_files() {
    local tmp
    tmp="$(mktemp)"
    sed "s|^ExecStart=.*|ExecStart=${PREFIX}/bin/msi-daemon|" \
        "$ROOT/data/systemd/system/msi-linux-center.service" >"$tmp"

    echo "==> install binaries and policy"
    as_root install -d \
        "${PREFIX}/bin" \
        "${PREFIX}/share/polkit-1/actions" \
        "${PREFIX}/share/dbus-1/system.d" \
        "${PREFIX}/share/applications" \
        "${PREFIX}/share/icons/hicolor/scalable/apps" \
        "${SYSCONFDIR}/systemd/system"

    as_root install -m 755 "$ROOT/target/release/msi-daemon" "${PREFIX}/bin/msi-daemon"
    as_root install -m 755 "$ROOT/target/release/msicenter" "${PREFIX}/bin/msicenter"
    as_root install -m 755 "$UI_BUILD/msicenter-ui" "${PREFIX}/bin/msicenter-ui"
    as_root install -m 644 "$tmp" "$(unit_path)"
    as_root install -m 644 \
        "$ROOT/data/polkit-1/actions/org.msilinux.Center.policy" \
        "${PREFIX}/share/polkit-1/actions/org.msilinux.Center.policy"
    as_root install -m 644 \
        "$ROOT/data/dbus-1/system.d/org.msilinux.Center.conf" \
        "${PREFIX}/share/dbus-1/system.d/org.msilinux.Center.conf"
    as_root install -m 644 \
        "$ROOT/data/msicenter-ui.desktop" \
        "${PREFIX}/share/applications/msicenter-ui.desktop"
    as_root install -m 644 \
        "$ROOT/data/msicenter-ui.svg" \
        "${PREFIX}/share/icons/hicolor/scalable/apps/msicenter-ui.svg"
    rm -f "$tmp"

    if [[ "$AUTOSTART" -eq 1 ]]; then
        as_root install -d "${SYSCONFDIR}/xdg/autostart"
        as_root install -m 644 \
            "$ROOT/data/autostart/msi-linux-center.desktop" \
            "${SYSCONFDIR}/xdg/autostart/msi-linux-center.desktop"
    fi

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        as_root gtk-update-icon-cache -q -t \
            "${PREFIX}/share/icons/hicolor" || true
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
        as_root update-desktop-database -q \
            "${PREFIX}/share/applications" || true
    fi

    echo "==> systemd"
    as_root systemctl daemon-reload
    as_root systemctl enable --now msi-linux-center.service
    echo "installed. writes remain disabled (opt-ins = 0)."
    echo "check: systemctl is-active msi-linux-center.service && msicenter status"
}

uninstall_files() {
    echo "==> stop unit"
    as_root systemctl disable --now msi-linux-center.service 2>/dev/null || true

    echo "==> remove files"
    as_root rm -f \
        "${PREFIX}/bin/msi-daemon" \
        "${PREFIX}/bin/msicenter" \
        "${PREFIX}/bin/msicenter-ui" \
        "$(unit_path)" \
        "${PREFIX}/share/polkit-1/actions/org.msilinux.Center.policy" \
        "${PREFIX}/share/dbus-1/system.d/org.msilinux.Center.conf" \
        "${PREFIX}/share/applications/msicenter-ui.desktop" \
        "${PREFIX}/share/icons/hicolor/scalable/apps/msicenter-ui.svg" \
        "${SYSCONFDIR}/xdg/autostart/msi-linux-center.desktop"

    as_root systemctl daemon-reload
    echo "removed. user config ~/.config/msi-linux-center was left in place."
}

case "$CMD" in
    build) build ;;
    install)
        build
        install_files
        ;;
    uninstall) uninstall_files ;;
    "" | -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "unknown command: $CMD" >&2
        usage >&2
        exit 2
        ;;
esac
