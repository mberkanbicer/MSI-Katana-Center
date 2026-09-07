#!/usr/bin/env bash
# Build all release artifacts for a new MSI Katana Center release and
# optionally upload them to a GitHub release.
#
# Artifacts produced in target/release-artifacts/:
#   msi-katana-center-<ver>-x86_64.tar.gz   binaries + data + setup script
#   msi-daemon_<ver>-1_amd64.deb            Debian daemon package
#   msicenter-cli_<ver>-1_amd64.deb         Debian CLI package
#   msi-daemon-<ver>-1.x86_64.rpm           RPM daemon package
#   msicenter-cli-<ver>-1.x86_64.rpm        RPM CLI package
#   MSI-Katana-Center-<ver>-x86_64.AppImage portable Qt desktop client
#   checksums-<ver>.txt                     SHA-256 of every artifact
#
# Usage:
#   ./scripts/build-release.sh [--upload] [--tag vX.Y.Z] [--notes-file FILE]
#
#   --upload         Publish/overwrite a GitHub release with gh (needs gh auth)
#   --tag            Release tag (default: v<version from Cargo.toml>)
#   --notes-file     Markdown file with release notes
#                    (default: keep existing notes on edit)
#
# Requirements: cargo, cargo-deb, cargo-generate-rpm, cmake, Qt 6,
# ImageMagick (convert), appimagetool (auto-downloaded to /tmp if absent).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

UPLOAD=0
TAG=""
NOTES_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --upload) UPLOAD=1 ;;
        --tag) TAG="$2"; shift ;;
        --notes-file) NOTES_FILE="$2"; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -1)"
if [[ -z "$VERSION" ]]; then echo "cannot read workspace version" >&2; exit 1; fi
if [[ -z "$TAG" ]]; then TAG="v$VERSION"; fi

OUT="target/release-artifacts"
rm -rf "$OUT"
mkdir -p "$OUT"
echo "==> version $VERSION, tag $TAG, artifacts in $OUT"

# ---------- 1. Rust release build ----------
echo "==> cargo build --release"
cargo build --release

# ---------- 2. Tarball ----------
echo "==> tarball"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
TARBALL_DIR="$STAGE/msi-katana-center-$VERSION-x86_64"
mkdir -p "$TARBALL_DIR"
cp target/release/msicenter target/release/msi-daemon "$TARBALL_DIR/"
cp -r data "$TARBALL_DIR/"
cp README.md LICENSE-MIT LICENSE-APACHE "$TARBALL_DIR/"
cp scripts/setup.sh "$TARBALL_DIR/"
chmod +x "$TARBALL_DIR/setup.sh"
tar -C "$STAGE" -czf "$OUT/msi-katana-center-$VERSION-x86_64.tar.gz" \
    "msi-katana-center-$VERSION-x86_64"

# ---------- 3. Debian packages ----------
echo "==> deb packages"
if ! command -v cargo-deb >/dev/null 2>&1 && [[ ! -x ~/.cargo/bin/cargo-deb ]]; then
    echo "cargo-deb not found; installing" >&2
    cargo install cargo-deb
fi
CARGO_DEB="$(command -v cargo-deb || echo ~/.cargo/bin/cargo-deb)"
"$CARGO_DEB" -p msi-daemon
"$CARGO_DEB" -p msicenter-cli
cp target/debian/*.deb "$OUT/"

# ---------- 4. RPM packages ----------
echo "==> rpm packages"
if ! command -v cargo-generate-rpm >/dev/null 2>&1 && [[ ! -x ~/.cargo/bin/cargo-generate-rpm ]]; then
    echo "cargo-generate-rpm not found; installing" >&2
    cargo install cargo-generate-rpm
fi
CARGO_RPM="$(command -v cargo-generate-rpm || echo ~/.cargo/bin/cargo-generate-rpm)"
mkdir -p target/generate-rpm
"$CARGO_RPM" -p crates/msi-daemon
"$CARGO_RPM" -p crates/msicenter-cli
cp target/generate-rpm/*.rpm "$OUT/"

# ---------- 5. AppImage (Qt desktop client) ----------
echo "==> AppImage"
if command -v appimagetool >/dev/null 2>&1; then
    AIT="$(command -v appimagetool)"
elif [[ -x /tmp/appimagetool ]]; then
    AIT=/tmp/appimagetool
else
    echo "downloading appimagetool to /tmp"
    curl -sL -o /tmp/appimagetool \
        https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x /tmp/appimagetool
    AIT=/tmp/appimagetool
fi

UI_BUILD="$(mktemp -d)"
cmake -S crates/msicenter-ui -B "$UI_BUILD" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr >/dev/null
cmake --build "$UI_BUILD" -j"$(nproc)" >/dev/null

APPDIR="$STAGE/AppDir"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
    "$APPDIR/usr/plugins" "$APPDIR/usr/qml" \
    "$APPDIR/usr/share/applications" \
    "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp "$UI_BUILD/msicenter-ui" "$APPDIR/usr/bin/"
cp data/msicenter-ui.svg "$APPDIR/usr/share/icons/hicolor/256x256/apps/"

cat > "$APPDIR/msicenter-ui.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=MSI Katana Center
Comment=Hardware management for MSI laptops
Exec=msicenter-ui
Icon=msicenter-ui
Categories=System;HardwareSettings;
Terminal=false
StartupWMClass=msicenter-ui
DESKTOP
cp "$APPDIR/msicenter-ui.desktop" "$APPDIR/usr/share/applications/"
convert -background none -background none data/msicenter-ui.svg -resize 256x256 \
    "$APPDIR/msicenter-ui.png" 2>/dev/null || cp data/msicenter-ui.svg "$APPDIR/msicenter-ui.png"
cp "$APPDIR/msicenter-ui.png" "$APPDIR/.DirIcon" 2>/dev/null || true

# recursive shared-library collection (skip glibc core, keep libgcc/libstdc++)
collect_deps() {
    local lib
    for lib in $(ldd "$1" 2>/dev/null | awk '{print $3}' | grep '^/'); do
        [[ -f "$APPDIR/usr/lib/$(basename "$lib")" ]] && continue
        case "$(basename "$lib")" in
            libc.so*|ld-linux*|libm.so*|libpthread*|libdl*|librt*|libresolv*) continue ;;
        esac
        cp -n "$lib" "$APPDIR/usr/lib/" 2>/dev/null || true
        collect_deps "$lib"
    done
}
collect_deps "$APPDIR/usr/bin/msicenter-ui"

# Qt plugins (skip jpegxr, which needs a rarely installed lib)
for p in platforms imageformats iconengines \
         wayland-graphics-integration-client wayland-shell-integration; do
    [[ -d /usr/lib/qt6/plugins/$p ]] || continue
    mkdir -p "$APPDIR/usr/plugins/$p"
    for f in /usr/lib/qt6/plugins/$p/*.so; do
        case "$(basename "$f")" in *jxr*) continue ;; esac
        cp "$f" "$APPDIR/usr/plugins/$p/"
    done
done

# QML modules used by the client
cp -r /usr/lib/qt6/qml/QtQuick "$APPDIR/usr/qml/"

cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export QT_PLUGIN_PATH="$HERE/usr/plugins"
export QML2_IMPORT_PATH="$HERE/usr/qml"
export QML_IMPORT_PATH="$HERE/usr/qml"
export LD_LIBRARY_PATH="$HERE/usr/lib:$LD_LIBRARY_PATH"
exec "$HERE/usr/bin/msicenter-ui" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$AIT" "$APPDIR" \
    "$OUT/MSI-Katana-Center-$VERSION-x86_64.AppImage" >/dev/null

# ---------- 6. Checksums ----------
echo "==> checksums"
cd "$OUT"
sha256sum ./*.deb ./*.rpm ./*.tar.gz ./*.AppImage > "checksums-$VERSION.txt"

echo
echo "Artifacts:"
ls -la

# ---------- 7. Upload ----------
if [[ "$UPLOAD" -eq 1 ]]; then
    echo "==> uploading to GitHub release $TAG"
    if ! gh release view "$TAG" >/dev/null 2>&1; then
        if [[ -n "$NOTES_FILE" ]]; then
            gh release create "$TAG" --notes-file "$NOTES_FILE" --title "MSI Katana Center $TAG"
        else
            gh release create "$TAG" --generate-notes --title "MSI Katana Center $TAG"
        fi
    fi
    ARGS=(--clobber)
    if [[ -n "$NOTES_FILE" ]]; then ARGS+=(--notes-file "$NOTES_FILE"); fi
    gh release upload "$TAG" ./*.deb ./*.rpm ./*.tar.gz ./*.AppImage "checksums-$VERSION.txt" "${ARGS[@]}"
    echo "uploaded: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/$TAG"
fi
