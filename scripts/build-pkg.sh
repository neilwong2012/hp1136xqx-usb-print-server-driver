#!/bin/sh
set -eu

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/.build"
SRC_DIR="$BUILD_DIR/src"
PAYLOAD="$BUILD_DIR/pkgroot"
PKG_SCRIPTS="$BUILD_DIR/pkg-scripts"
DIST="$REPO_ROOT/dist"
VERSION="${VERSION:-1.0.0}"
PKG_ID="${PKG_ID:-com.neil.hp1136xqx.fusionwrt}"
FOO2ZJS_URL="${FOO2ZJS_URL:-https://deb.debian.org/debian/pool/main/f/foo2zjs/foo2zjs_20200505dfsg0.orig.tar.xz}"
FOO2ZJS_TARBALL="$BUILD_DIR/foo2zjs.orig.tar.xz"
FOO2ZJS_DIR="$SRC_DIR/foo2zjs-20200505dfsg0"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

need pkgbuild
need curl
need tar
need make
need otool
need install_name_tool
need codesign

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install ghostscript and gnu-sed first." >&2
  exit 1
fi

GS_PREFIX="$(brew --prefix ghostscript 2>/dev/null || true)"
SED_PREFIX="$(brew --prefix gnu-sed 2>/dev/null || true)"
if [ -z "$GS_PREFIX" ] || [ ! -x "$GS_PREFIX/bin/gs" ]; then
  echo "Missing Homebrew ghostscript. Run: brew install ghostscript" >&2
  exit 1
fi
if [ -z "$SED_PREFIX" ] || [ ! -x "$SED_PREFIX/bin/gsed" ]; then
  echo "Missing Homebrew gnu-sed. Run: brew install gnu-sed" >&2
  exit 1
fi

rm -rf "$BUILD_DIR" "$DIST"
mkdir -p "$SRC_DIR" "$PAYLOAD/usr/libexec/cups/filter" \
  "$PAYLOAD/Library/Printers/PPDs/Contents/Resources" \
  "$PAYLOAD/usr/local/bin" "$PKG_SCRIPTS" "$DIST"

curl -L "$FOO2ZJS_URL" -o "$FOO2ZJS_TARBALL"
tar -xf "$FOO2ZJS_TARBALL" -C "$SRC_DIR"

(
  cd "$FOO2ZJS_DIR"
  make PREFIX=/usr/local foo2xqx foo2xqx-wrapper foo2zjs-pstops
)

install -m 755 "$FOO2ZJS_DIR/foo2xqx" "$PAYLOAD/usr/libexec/cups/filter/foo2xqx"
install -m 755 "$FOO2ZJS_DIR/foo2xqx-wrapper" "$PAYLOAD/usr/libexec/cups/filter/foo2xqx-wrapper"
install -m 755 "$FOO2ZJS_DIR/foo2zjs-pstops" "$PAYLOAD/usr/libexec/cups/filter/foo2zjs-pstops"
install -m 755 "$SED_PREFIX/bin/gsed" "$PAYLOAD/usr/libexec/cups/filter/gsed"
install -m 755 "$REPO_ROOT/filters/hp1136xqx-filter" "$PAYLOAD/usr/libexec/cups/filter/hp1136xqx-filter"
install -m 644 "$REPO_ROOT/ppd/HP1136XQX.ppd" "$PAYLOAD/Library/Printers/PPDs/Contents/Resources/HP1136XQX.ppd"
install -m 755 "$REPO_ROOT/scripts/hp1136xqx-setup" "$PAYLOAD/usr/local/bin/hp1136xqx-setup"
install -m 755 "$REPO_ROOT/scripts/hp1136xqx-uninstall" "$PAYLOAD/usr/local/bin/hp1136xqx-uninstall"

"$REPO_ROOT/scripts/bundle_ghostscript.py" \
  --gs "$GS_PREFIX/bin/gs" \
  --out "$BUILD_DIR/gsbundle" \
  --homebrew-prefix "$(brew --prefix)"

install -m 755 "$BUILD_DIR/gsbundle/gs" "$PAYLOAD/usr/libexec/cups/filter/gs"
cp -R "$BUILD_DIR/gsbundle/hp1136libs" "$PAYLOAD/usr/libexec/cups/filter/hp1136libs"
cp -R "$GS_PREFIX/share/ghostscript" "$PAYLOAD/usr/libexec/cups/filter/ghostscript"

cp "$REPO_ROOT/packaging/scripts/postinstall" "$PKG_SCRIPTS/postinstall"
chmod 755 "$PKG_SCRIPTS/postinstall"

find "$PAYLOAD" -name '.DS_Store' -delete
find "$PAYLOAD" -name '._*' -delete
find "$PAYLOAD" -type d -exec chmod 755 {} +
find "$PAYLOAD" -type f -exec chmod 644 {} +
chmod 755 "$PAYLOAD/usr/libexec/cups/filter/hp1136xqx-filter" \
  "$PAYLOAD/usr/libexec/cups/filter/foo2xqx" \
  "$PAYLOAD/usr/libexec/cups/filter/foo2xqx-wrapper" \
  "$PAYLOAD/usr/libexec/cups/filter/foo2zjs-pstops" \
  "$PAYLOAD/usr/libexec/cups/filter/gsed" \
  "$PAYLOAD/usr/libexec/cups/filter/gs" \
  "$PAYLOAD/usr/local/bin/hp1136xqx-setup" \
  "$PAYLOAD/usr/local/bin/hp1136xqx-uninstall"
find "$PAYLOAD/usr/libexec/cups/filter/hp1136libs" -type f -exec chmod 755 {} +
xattr -cr "$PAYLOAD" "$PKG_SCRIPTS" 2>/dev/null || true
find "$PAYLOAD" -name '.DS_Store' -delete
find "$PAYLOAD" -name '._*' -delete

export COPYFILE_DISABLE=1
pkgbuild \
  --root "$PAYLOAD" \
  --scripts "$PKG_SCRIPTS" \
  --identifier "$PKG_ID" \
  --version "$VERSION" \
  --install-location / \
  "$DIST/HP1136XQX-FusionWrt-Installer-$VERSION.pkg"

echo "$DIST/HP1136XQX-FusionWrt-Installer-$VERSION.pkg"
