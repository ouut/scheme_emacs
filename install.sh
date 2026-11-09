#!/usr/bin/env bash
# ==============================================================================
# 🪓 Scheme Emacs - One-Click Installer for Linux
# Installs standalone Scheme Emacs (Emacs + Rust Steel REPL + Strict Paredit)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ouut/scheme_emacs/main/install.sh | bash
#
# Options (via environment or arguments):
#   SCHEME_EMACS_MODE="appimage" | "lightweight" | "auto" (default: auto)
#   SCHEME_EMACS_NO_LAUNCH=1  (do not automatically launch after installation)
# ==============================================================================
set -euo pipefail

REPO="ouut/scheme_emacs"
INSTALL_DIR="${HOME}/.local/share/scheme-emacs"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ____       _                          _____                               "
echo " / ___|  ___| |__   ___ _ __ ___   ___ | ____|_ __ ___   __ _  ___ ___      "
echo " \___ \ / __| '_ \ / _ \ '_ \` _ \ / _ \|  _| | '_ \` _ \ / _\` |/ __/ __|   "
echo "  ___) | (__| | | |  __/ | | | | |  __/| |___| | | | | | (_| | (__\__ \    "
echo " |____/ \___|_| |_|\___|_| |_| |_|\___||_____|_| |_| |_|\__,_|\___|___/    "
echo -e "${NC}"
echo -e "${BLUE}  ⚡ Rust Steel Scheme & Strict Paredit 17-Key IDE  ${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

# 1. Architecture Check
OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "${OS}" != "Linux" ]]; then
    echo -e "${RED}✗ Error: This installer is designed for Linux.${NC}"
    echo "For macOS or Windows, download native bundles from:"
    echo "  https://github.com/${REPO}/releases"
    exit 1
fi

if [[ "${ARCH}" != "x86_64" ]]; then
    echo -e "${YELLOW}⚠️ Warning: Architecture ${ARCH} detected. Pre-built standalone AppImage is optimized for x86_64.${NC}"
fi

# 2. Query Latest Release Tag from GitHub
echo -e "${BLUE}[1/4] Fetching latest release info from GitHub...${NC}"
TAG=""
if command -v curl >/dev/null 2>&1; then
    TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
fi

if [[ -z "${TAG}" ]]; then
    TAG="v0.2.0"
fi
echo -e "${GREEN}✓ Target version:${NC} ${BOLD}${TAG}${NC}"

mkdir -p "${INSTALL_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

# 3. Determine Installation Mode
# If emacs already exists on host, default to lightweight 6.5MB bundle; otherwise standalone AppImage (zero-dependency).
MODE="${SCHEME_EMACS_MODE:-auto}"
if [[ "${MODE}" == "auto" ]]; then
    if command -v emacs >/dev/null 2>&1; then
        MODE="lightweight"
        echo -e "${GREEN}✓ Found host GNU Emacs:${NC} $(emacs --version | head -n1)"
        echo -e "  Installing fast lightweight distribution (6.5 MB)..."
    else
        MODE="appimage"
        echo -e "${YELLOW}ℹ GNU Emacs not detected on system.${NC}"
        echo -e "  Installing standalone all-in-one AppImage (includes Emacs + Steel, no root/sudo needed)..."
    fi
fi

# 4. Download and Install
echo -e "\n${BLUE}[2/4] Downloading and setting up Scheme Emacs (${MODE})...${NC}"

if [[ "${MODE}" == "appimage" ]]; then
    APPIMAGE_URL="https://github.com/${REPO}/releases/download/${TAG}/scheme-emacs-${TAG}-linux-x86_64.AppImage"
    TARGET_BIN="${BIN_DIR}/scheme-emacs"
    
    echo -e "Downloading AppImage from ${APPIMAGE_URL}..."
    curl -fsSL -o "${TARGET_BIN}.tmp" "${APPIMAGE_URL}"
    mv "${TARGET_BIN}.tmp" "${TARGET_BIN}"
    chmod +x "${TARGET_BIN}"

    # Also extract sample.scm and desktop assets from repo
    curl -fsSL -o "${INSTALL_DIR}/sample.scm" "https://raw.githubusercontent.com/${REPO}/main/sample.scm" 2>/dev/null || true
    curl -fsSL -o "${ICON_DIR}/scheme-emacs.svg" "https://raw.githubusercontent.com/${REPO}/main/assets/scheme-emacs.svg" 2>/dev/null || true
    curl -fsSL -o "${DESKTOP_DIR}/scheme-emacs.desktop" "https://raw.githubusercontent.com/${REPO}/main/assets/scheme-emacs.desktop" 2>/dev/null || true

else
    # Lightweight mode (requires host emacs)
    TAR_URL="https://github.com/${REPO}/releases/download/${TAG}/scheme-emacs-${TAG}-linux-x86_64.tar.gz"
    echo -e "Downloading lightweight bundle from ${TAR_URL}..."
    curl -fsSL "${TAR_URL}" | tar -xzf - -C "${INSTALL_DIR}" --strip-components=1
    
    # Create symlink in ~/.local/bin
    ln -sf "${INSTALL_DIR}/bin/scheme-emacs" "${BIN_DIR}/scheme-emacs"
    chmod +x "${INSTALL_DIR}/bin/scheme-emacs" "${BIN_DIR}/scheme-emacs"

    # Copy icons & desktop entry
    if [[ -f "${INSTALL_DIR}/assets/scheme-emacs.svg" ]]; then
        cp "${INSTALL_DIR}/assets/scheme-emacs.svg" "${ICON_DIR}/scheme-emacs.svg" 2>/dev/null || true
    fi
    if [[ -f "${INSTALL_DIR}/assets/scheme-emacs.desktop" ]]; then
        cp "${INSTALL_DIR}/assets/scheme-emacs.desktop" "${DESKTOP_DIR}/scheme-emacs.desktop" 2>/dev/null || true
    fi
fi

# Copy sample.scm to current directory for immediate practice
if [[ ! -f "sample.scm" && -f "${INSTALL_DIR}/sample.scm" ]]; then
    cp "${INSTALL_DIR}/sample.scm" ./sample.scm
fi

# 5. PATH Verification and Configuration
echo -e "\n${BLUE}[3/4] Configuring shell environment...${NC}"
PATH_UPDATED=false
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    # Add to shell profile
    SHELL_NAME="$(basename "${SHELL:-bash}")"
    RC_FILE="${HOME}/.bashrc"
    if [[ "${SHELL_NAME}" == "zsh" ]]; then
        RC_FILE="${HOME}/.zshrc"
    fi
    
    if [[ -f "${RC_FILE}" ]] && ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "${RC_FILE}"; then
        echo -e '\n# Scheme Emacs PATH' >> "${RC_FILE}"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${RC_FILE}"
        echo -e "${GREEN}✓ Added ~/.local/bin to PATH in ${RC_FILE}${NC}"
        PATH_UPDATED=true
    fi
    export PATH="${BIN_DIR}:${PATH}"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Scheme Emacs Successfully Installed!${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo -e "Executable location: ${BOLD}${BIN_DIR}/scheme-emacs${NC}"
echo -e "Interactive file:    ${BOLD}sample.scm${NC} (Practice the 17-key Strict Paredit!)"
echo -e "\nHow to run anytime:"
echo -e "  ${CYAN}scheme-emacs sample.scm${NC}       # Launch GUI IDE"
echo -e "  ${CYAN}scheme-emacs -nw sample.scm${NC}   # Launch in Terminal mode"

# 6. Auto-Launch Option
NO_LAUNCH="${SCHEME_EMACS_NO_LAUNCH:-0}"
if [[ "${NO_LAUNCH}" != "1" ]]; then
    echo -e "\n${BLUE}[4/4] 🚀 Launching Scheme Emacs now...${NC}\n"
    sleep 1

    # Reconnect terminal TTY when piping curl | bash
    if [ -t 0 ] || [ -e /dev/tty ]; then
        exec < /dev/tty
    fi

    # Launch Scheme Emacs with sample.scm
    if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        exec "${BIN_DIR}/scheme-emacs" "sample.scm"
    else
        exec "${BIN_DIR}/scheme-emacs" -nw "sample.scm"
    fi
fi
