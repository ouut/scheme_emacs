#!/usr/bin/env bash
# ==============================================================================
# Build Standalone Linux AppImage for Scheme Emacs
# Bundles GNU Emacs + Rust Steel Scheme + Strict Paredit + Dependencies
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${ROOT_DIR}/build-appimage"
VERSION="${VERSION:-v0.1.0}"

echo "======================================================================"
echo "🚀 Building Linux AppImage for Scheme Emacs (${VERSION})"
echo "======================================================================"

mkdir -p "${DIST_DIR}" "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 1. Download Base GNU Emacs AppImage (x86_64)
EMACS_APPIMAGE_URL="https://github.com/blahgeek/emacs-appimage/releases/download/v20240326-29.3/Emacs-29.3-pgtk.AppImage"
echo "📦 Step 1: Downloading base Emacs AppImage..."
if [[ ! -f "base-emacs.AppImage" ]]; then
  curl -fsSL -o "base-emacs.AppImage" "${EMACS_APPIMAGE_URL}"
fi
chmod +x base-emacs.AppImage

# 2. Extract Base AppImage
echo "📦 Step 2: Extracting AppImage filesystem..."
rm -rf squashfs-root
./base-emacs.AppImage --appimage-extract >/dev/null

# 3. Locate and bundle Steel binary
echo "📦 Step 3: Bundling Rust Steel Scheme interpreter..."
STEEL_BIN=""
if [[ -x "${ROOT_DIR}/bin/steel" ]]; then
  STEEL_BIN="${ROOT_DIR}/bin/steel"
elif [[ -x "${HOME}/.cargo/bin/steel" ]]; then
  STEEL_BIN="${HOME}/.cargo/bin/steel"
elif command -v steel >/dev/null 2>&1; then
  STEEL_BIN="$(command -v steel)"
fi

if [[ -z "${STEEL_BIN}" ]]; then
  echo "❌ Error: steel binary not found! Please build or install steel first." >&2
  exit 1
fi

mkdir -p squashfs-root/usr/bin
cp "${STEEL_BIN}" squashfs-root/usr/bin/steel
if command -v strip >/dev/null 2>&1; then
  strip squashfs-root/usr/bin/steel 2>/dev/null || true
fi
chmod +x squashfs-root/usr/bin/steel

# 4. Copy Scheme Emacs configuration & vendor dependencies
echo "📦 Step 4: Injecting Scheme Emacs configuration..."
APP_CONF="squashfs-root/opt/scheme-emacs"
mkdir -p "${APP_CONF}/lisp" "${APP_CONF}/bin"

cp "${ROOT_DIR}"/early-init.el* "${APP_CONF}/"
cp "${ROOT_DIR}"/init.el* "${APP_CONF}/"
cp "${ROOT_DIR}"/sample.scm "${APP_CONF}/"
cp "${ROOT_DIR}"/README.md "${APP_CONF}/"
cp -r "${ROOT_DIR}"/lisp/* "${APP_CONF}/lisp/"

# Symlink steel into the config bin as well
ln -sf "../../usr/bin/steel" "${APP_CONF}/bin/steel"

# Vendor ELPA packages
mkdir -p "${APP_CONF}/elpa"
if [[ -d "${ROOT_DIR}/elpa" && -n "$(ls -A "${ROOT_DIR}/elpa" 2>/dev/null)" ]]; then
  cp -r "${ROOT_DIR}"/elpa/* "${APP_CONF}/elpa/"
elif [[ -d "${HOME}/.emacs.d/elpa" && -n "$(ls -A "${HOME}/.emacs.d/elpa" 2>/dev/null)" ]]; then
  cp -r "${HOME}"/.emacs.d/elpa/* "${APP_CONF}/elpa/"
fi

# 5. Pre-compile bytecode if not already compiled
echo "📦 Step 5: Byte-compiling Elisp modules..."
emacs -batch -Q \
  -L "${APP_CONF}/lisp" \
  -l "${APP_CONF}/early-init.el" \
  -l "${APP_CONF}/init.el" \
  -f batch-byte-compile \
  "${APP_CONF}"/lisp/*.el "${APP_CONF}"/early-init.el "${APP_CONF}"/init.el 2>/dev/null || true

# 6. Customize AppRun launcher
echo "📦 Step 6: Creating AppRun entrypoint..."
cat << 'EOF' > squashfs-root/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"

# Configure Emacs data directories inside the AppImage
if [[ -d "${HERE}/usr/share/emacs" ]]; then
  EMACS_VER="$(ls "${HERE}/usr/share/emacs" | grep -E '^[0-9]' | head -n1)"
  if [[ -n "${EMACS_VER}" ]]; then
    export EMACSDATA="${HERE}/usr/share/emacs/${EMACS_VER}/etc"
    export EMACSDOC="${HERE}/usr/share/emacs/${EMACS_VER}/etc"
    export EMACSLOADPATH="${HERE}/usr/share/emacs/${EMACS_VER}/lisp"
  fi
fi

# Ensure user directory points directly to bundled config
exec "${HERE}/usr/bin/emacs" --init-directory "${HERE}/opt/scheme-emacs" "$@"
EOF
chmod +x squashfs-root/AppRun

# 7. Desktop entry and icons
echo "📦 Step 7: Configuring Desktop file and icons..."
cp "${ROOT_DIR}/assets/scheme-emacs.desktop" squashfs-root/scheme-emacs.desktop
cp "${ROOT_DIR}/assets/scheme-emacs.desktop" squashfs-root/default.desktop 2>/dev/null || true
cp "${ROOT_DIR}/assets/scheme-emacs.svg" squashfs-root/scheme-emacs.svg
cp "${ROOT_DIR}/assets/scheme-emacs.png" squashfs-root/scheme-emacs.png
cp "${ROOT_DIR}/assets/scheme-emacs.png" squashfs-root/.DirIcon

# 8. Package using appimagetool
echo "📦 Step 8: Packaging with appimagetool..."
if [[ ! -f "appimagetool" ]]; then
  curl -fsSL -o "appimagetool" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x appimagetool
fi

TARGET_APPIMAGE="${DIST_DIR}/scheme-emacs-${VERSION}-linux-x86_64.AppImage"
ARCH=x86_64 ./appimagetool --appimage-extract-and-run squashfs-root "${TARGET_APPIMAGE}"

cd "${DIST_DIR}"
sha256sum "$(basename "${TARGET_APPIMAGE}")" > "$(basename "${TARGET_APPIMAGE}").sha256"

echo "======================================================================"
echo "✅ AppImage Built Successfully: ${TARGET_APPIMAGE}"
echo "   Size: $(du -h "${TARGET_APPIMAGE}" | cut -f1)"
echo "======================================================================"
