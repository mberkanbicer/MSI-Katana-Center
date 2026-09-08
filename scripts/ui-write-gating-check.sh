#!/usr/bin/env bash
# Software stand-in for UI write gating. Does not talk to live hardware writes.
# Desktop visual test: docs/phase6-ui-write-visual-test.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MSI_LINUX_CENTER_SYSROOT="${MSI_LINUX_CENTER_SYSROOT:-$ROOT/tests/fixtures/katana17-b13vgk}"
# Force a missing system bus so write commands cannot reach a real daemon.
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/msicenter-ui-gating-nonexistent-bus"

cd "$ROOT"
cargo build -q -p msicenter-cli
CLI="$ROOT/target/debug/msicenter"

echo "==> fixture status (no D-Bus daemon required for collect_status sysroot path)"
unset DBUS_SYSTEM_BUS_ADDRESS
MSI_LINUX_CENTER_SYSROOT="$ROOT/tests/fixtures/katana17-b13vgk" \
    "$CLI" status >/dev/null

echo "==> write commands must fail closed without a system bus"
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/msicenter-ui-gating-nonexistent-bus"
fail_closed() {
    local cmd="$1"
    shift
    set +e
    "$CLI" "$cmd" "$@" >/tmp/msicenter-gating-out 2>/tmp/msicenter-gating-err
    local rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
        echo "expected non-zero exit for $cmd, got 0" >&2
        cat /tmp/msicenter-gating-out /tmp/msicenter-gating-err >&2 || true
        exit 1
    fi
    echo "  ok   $cmd failed closed (exit $rc)"
}

fail_closed fan-mode silent
fail_closed cooler-boost on
fail_closed super-battery on
fail_closed panic-reset

UI_BIN="$ROOT/crates/msicenter-ui/build/msicenter-ui"
if [[ -x "$UI_BIN" ]]; then
    echo "==> UI offscreen smoke (no clicks, no writes)"
    set +e
    QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" timeout 5 "$UI_BIN"
    rc=$?
    set -e
    # 124 = timeout sent SIGTERM after a successful start; 0 = exited cleanly.
    if [[ "$rc" -eq 0 || "$rc" -eq 124 ]]; then
        echo "  ok   UI started (exit $rc)"
    else
        echo "  skip UI smoke failed to stay up (exit $rc); not a write-path failure"
    fi
else
    echo "==> UI binary absent; skip offscreen smoke"
fi

echo "==> gating check passed"
