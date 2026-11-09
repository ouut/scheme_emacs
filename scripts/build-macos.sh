#!/usr/bin/env bash
# ==============================================================================
# Build Standalone macOS App Bundle & DMG for Scheme Emacs
# Bundles GNU Emacs + Rust Steel Scheme + Strict Paredit + Dependencies
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${ROOT_DIR}/build-macos"
VERSION="${VERSION:-v0.1.0}"
ARCH="$(uname -m)"

echo "======================================================================"
echo "🚀 Building macOS Application for Scheme Emacs (${VERSION} - ${ARCH})"
echo "======================================================================"

mkdir -p "${DIST_DIR}" "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 1. Download Universal GNU Emacs DMG for macOS
EMACS_DMG_URL="https://emacsformacosx.com/download/emacs-builds/Emacs-29.4-universal.dmg"
echo "📦 Step 1: Downloading GNU Emacs universal build for macOS..."
if [[ ! -f "Emacs-universal.dmg" ]]; then
  curl -fsSL -o "Emacs-universal.dmg" "${EMACS_DMG_URL}"
fi

# 2. Extract Emacs.app
echo "📦 Step 2: Extracting Emacs.app from DMG..."
rm -rf SchemeEmacs.app /Volumes/Emacs
hdiutil attach Emacs-universal.dmg -mountpoint /Volumes/Emacs -nobrowse -quiet
cp -R /Volumes/Emacs/Emacs.app SchemeEmacs.app
hdiutil detach /Volumes/Emacs -quiet

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

mkdir -p SchemeEmacs.app/Contents/MacOS
cp "${STEEL_BIN}" SchemeEmacs.app/Contents/MacOS/steel
strip SchemeEmacs.app/Contents/MacOS/steel 2>/dev/null || true
chmod +x SchemeEmacs.app/Contents/MacOS/steel

# 4. Inject Scheme Emacs configuration & vendor dependencies
echo "📦 Step 4: Injecting Scheme Emacs configuration into App Bundle..."
APP_RESOURCES="SchemeEmacs.app/Contents/Resources/scheme-emacs"
mkdir -p "${APP_RESOURCES}/lisp" "${APP_RESOURCES}/bin"

cp "${ROOT_DIR}"/early-init.el* "${APP_RESOURCES}/"
cp "${ROOT_DIR}"/init.el* "${APP_RESOURCES}/"
cp "${ROOT_DIR}"/sample.scm "${APP_RESOURCES}/"
cp "${ROOT_DIR}"/README.md "${APP_RESOURCES}/"
cp -r "${ROOT_DIR}"/lisp/* "${APP_RESOURCES}/lisp/"

# Symlink steel
ln -sf "../../../MacOS/steel" "${APP_RESOURCES}/bin/steel"

# Vendor packages
mkdir -p "${APP_RESOURCES}/elpa"
if [[ -d "${ROOT_DIR}/elpa" && -n "$(ls -A "${ROOT_DIR}/elpa" 2>/dev/null)" ]]; then
  cp -r "${ROOT_DIR}"/elpa/* "${APP_RESOURCES}/elpa/"
elif [[ -d "${HOME}/.emacs.d/elpa" && -n "$(ls -A "${HOME}/.emacs.d/elpa" 2>/dev/null)" ]]; then
  cp -r "${HOME}"/.emacs.d/elpa/* "${APP_RESOURCES}/elpa/"
fi

# 5. Pre-compile bytecode
echo "📦 Step 5: Byte-compiling Elisp modules..."
EMACS_EXE="SchemeEmacs.app/Contents/MacOS/Emacs"
"${EMACS_EXE}" -batch -Q \
  -L "${APP_RESOURCES}/lisp" \
  -l "${APP_RESOURCES}/early-init.el" \
  -l "${APP_RESOURCES}/init.el" \
  -f batch-byte-compile \
  "${APP_RESOURCES}"/lisp/*.el "${APP_RESOURCES}"/early-init.el "${APP_RESOURCES}"/init.el 2>/dev/null || true

# Ensure all packages are vendored
"${EMACS_EXE}" --batch --init-directory "${APP_RESOURCES}" -l "${APP_RESOURCES}/init.el" --eval '(message "macOS ELPA vendored")' 2>/dev/null || true

# 6. Create custom SchemeEmacs launcher script
echo "📦 Step 6: Creating macOS launcher entrypoint..."
cat << 'EOF' > SchemeEmacs.app/Contents/MacOS/SchemeEmacs
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${DIR}/../.." && pwd)"
RESOURCES_DIR="${APP_DIR}/Contents/Resources/scheme-emacs"

export PATH="${DIR}:${PATH}"
exec "${DIR}/Emacs" --init-directory "${RESOURCES_DIR}" "$@"
EOF
chmod +x SchemeEmacs.app/Contents/MacOS/SchemeEmacs

# 7. Update Info.plist
echo "📦 Step 7: Updating Info.plist metadata..."
INFO_PLIST="SchemeEmacs.app/Contents/Info.plist"
if [[ -f "${INFO_PLIST}" ]]; then
  plutil -replace CFBundleExecutable -string "SchemeEmacs" "${INFO_PLIST}" 2>/dev/null || true
  plutil -replace CFBundleName -string "SchemeEmacs" "${INFO_PLIST}" 2>/dev/null || true
  plutil -replace CFBundleDisplayName -string "SchemeEmacs" "${INFO_PLIST}" 2>/dev/null || true
  plutil -replace CFBundleIdentifier -string "org.gnu.SchemeEmacs" "${INFO_PLIST}" 2>/dev/null || true
fi

# 8. Create Distribution Artifacts (Zip & DMG)
echo "📦 Step 8: Packaging portable ZIP and DMG..."
ZIP_NAME="scheme-emacs-${VERSION}-macos-${ARCH}.zip"
DMG_NAME="SchemeEmacs-${VERSION}-macos-${ARCH}.dmg"

zip -q -r -y "${DIST_DIR}/${ZIP_NAME}" SchemeEmacs.app

DMG_TMP="${BUILD_DIR}/dmg_root"
rm -rf "${DMG_TMP}"
mkdir -p "${DMG_TMP}"
cp -R SchemeEmacs.app "${DMG_TMP}/"
ln -s /Applications "${DMG_TMP}/Applications"

hdiutil create -volname "SchemeEmacs" -srcfolder "${DMG_TMP}" -ov -format UDZO "${DIST_DIR}/${DMG_NAME}" -quiet

cd "${DIST_DIR}"
shasum -a 256 "${ZIP_NAME}" > "${ZIP_NAME}.sha256"
shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256"

echo "======================================================================"
echo "✅ macOS App Built Successfully!"
echo "   ZIP: ${DIST_DIR}/${ZIP_NAME} ($(du -h "${DIST_DIR}/${ZIP_NAME}" | cut -f1))"
echo "   DMG: ${DIST_DIR}/${DMG_NAME} ($(du -h "${DIST_DIR}/${DMG_NAME}" | cut -f1))"
echo "======================================================================"
