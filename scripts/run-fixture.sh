#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MSI_LINUX_CENTER_SYSROOT="$ROOT/tests/fixtures/katana17-b13vgk"
exec cargo run -q -p msicenter-cli -- status "$@"
