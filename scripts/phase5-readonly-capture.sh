#!/usr/bin/env bash
# Read-only Phase 5 capture helper. Never writes EC, sysfs, or D-Bus.
# Design: docs/phase5-fan-curve-design.md §9–11.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EC_IO="/sys/kernel/debug/ec/ec0/io"
OUT="${1:-}"

usage() {
    cat <<EOF
Usage: $0 [output-directory]

Dumps msicenter status JSON and, if debugfs EC I/O is readable, a hex dump
of the documented fan-table region. Refuses any write-shaped arguments.

This is not the consent-gated single-point write experiment. That experiment
must be run by the laptop owner after an explicit go-ahead
(docs/phase5-fan-curve-design.md §11).
EOF
}

for arg in "$@"; do
    case "$arg" in
        -h | --help)
            usage
            exit 0
            ;;
        --write | write | --apply | --experiment)
            echo "refusing write-shaped argument: $arg" >&2
            echo "this script is read-only" >&2
            exit 2
            ;;
    esac
done

if [[ -z "$OUT" ]]; then
    OUT="$(mktemp -d /tmp/msi-phase5-capture-XXXXXX)"
else
    mkdir -p "$OUT"
fi

echo "==> read-only capture into $OUT"

if command -v msicenter >/dev/null 2>&1; then
    msicenter status --json >"$OUT/status.json"
else
    cargo run --manifest-path "$ROOT/Cargo.toml" -q -p msicenter-cli -- \
        status --json >"$OUT/status.json"
fi

if [[ -r "$EC_IO" ]]; then
    # Table window used by the design study (CPU/GPU curve region + 0x9E).
    # bs=1 reads only; never seek-write.
    dd if="$EC_IO" bs=1 skip=$((0x60)) count=80 status=none \
        | xxd -g1 -offset 0x60 >"$OUT/ec-0x60-0xaf.xxd"
    echo "==> EC debugfs dump written (read-only)"
else
    echo "==> $EC_IO not readable; status JSON only (no EC dump)"
fi

echo "==> done. Fan-curve production code stays blocked until §11 rollback is recorded."
echo "$OUT"
