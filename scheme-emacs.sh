#!/usr/bin/env bash
# ==============================================================================
# 🪓 Scheme Emacs - One-Step Universal Runner & Installer
# Idempotent: Can be run repeatedly via curl or directly as a local script.
#
# Usage via curl:
#   curl -fsSL https://raw.githubusercontent.com/ouut/scheme_emacs/main/scheme-emacs.sh | bash
#
# Usage locally (after first run):
#   ./scheme-emacs.sh [file.scm]
#   ./scheme-emacs.sh -nw [file.scm]  (terminal mode)
#   ./scheme-emacs.sh --update        (force update to latest release)
# ==============================================================================
set -euo pipefail

REPO="ouut/scheme_emacs"
INSTALL_DIR="${HOME}/.local/share/scheme-emacs"
BIN_DIR="${HOME}/.local/bin"
TARGET_BIN="${BIN_DIR}/scheme-emacs"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"
SCRIPT_URL="https://raw.githubusercontent.com/${REPO}/main/scheme-emacs.sh"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Check for --update flag
FORCE_UPDATE=false
ARGS=()
for arg in "$@"; do
    if [[ "${arg}" == "--update" ]]; then
        FORCE_UPDATE=true
    else
        ARGS+=("${arg}")
    fi
done

# 1. Architecture Check
OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "${OS}" != "Linux" ]]; then
    echo -e "${RED}✗ Error: This script is designed for Linux.${NC}"
    echo "For macOS or Windows, download native bundles from:"
    echo "  https://github.com/${REPO}/releases"
    exit 1
fi

# 2. Self-Persistence: Ensure this script is saved in the current directory
if [[ ! -f "./scheme-emacs.sh" ]]; then
    if [[ -f "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && -f "${BASH_SOURCE[0]}" ]]; then
        cp "${BASH_SOURCE[0]}" "./scheme-emacs.sh" 2>/dev/null || true
        chmod +x "./scheme-emacs.sh" 2>/dev/null || true
    else
        curl -fsSL -o "./scheme-emacs.sh" "${SCRIPT_URL}" 2>/dev/null && chmod +x "./scheme-emacs.sh" 2>/dev/null || true
    fi
    if [[ -f "./scheme-emacs.sh" ]]; then
        echo -e "${GREEN}✓ Saved runner to current directory:${NC} ${BOLD}./scheme-emacs.sh${NC} (runnable directly anytime)"
    fi
fi

# 3. Idempotent Installation Check
mkdir -p "${INSTALL_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

if [[ -x "${TARGET_BIN}" && "${FORCE_UPDATE}" != "true" && -z "${SCHEME_EMACS_UPDATE:-}" ]]; then
    # Already installed and ready - Fast Path!
    :
else
    echo -e "${CYAN}${BOLD}"
    echo "  ____       _                          _____                               "
    echo " / ___|  ___| |__   ___ _ __ ___   ___ | ____|_ __ ___   __ _  ___ ___      "
    echo " \___ \ / __| '_ \ / _ \ '_ \` _ \ / _ \|  _| | '_ \` _ \ / _\` |/ __/ __|   "
    echo "  ___) | (__| | | |  __/ | | | | |  __/| |___| | | | | | (_| | (__\__ \    "
    echo " |____/ \___|_| |_|\___|_| |_| |_|\___||_____|_| |_| |_|\__,_|\___|___/    "
    echo -e "${NC}"
    echo -e "${BLUE}  ⚡ Rust Steel Scheme & Strict Paredit 17-Key IDE  ${NC}"
    echo -e "${BLUE}======================================================================${NC}"

    echo -e "\n${BLUE}[1/3] Resolving latest Scheme Emacs release...${NC}"
    TAG=""
    if command -v curl >/dev/null 2>&1; then
        TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
    fi
    if [[ -z "${TAG}" ]]; then
        TAG="v0.2.0"
    fi
    echo -e "${GREEN}✓ Target version:${NC} ${BOLD}${TAG}${NC}"

    # Determine mode: if host emacs exists -> lightweight (6.5MB); else standalone AppImage (zero dependency)
    MODE="${SCHEME_EMACS_MODE:-auto}"
    if [[ "${MODE}" == "auto" ]]; then
        if command -v emacs >/dev/null 2>&1; then
            MODE="lightweight"
            echo -e "${GREEN}✓ Found host GNU Emacs:${NC} $(emacs --version | head -n1)"
            echo -e "  Installing fast lightweight distribution (6.5 MB)..."
        else
            MODE="appimage"
            echo -e "${YELLOW}ℹ GNU Emacs not detected on host.${NC}"
            echo -e "  Installing standalone all-in-one AppImage (includes Emacs + Steel, zero sudo/root needed)..."
        fi
    fi

    echo -e "\n${BLUE}[2/3] Downloading Scheme Emacs (${MODE})...${NC}"
    if [[ "${MODE}" == "appimage" ]]; then
        APPIMAGE_URL="https://github.com/${REPO}/releases/download/${TAG}/scheme-emacs-${TAG}-linux-x86_64.AppImage"
        curl -fsSL -o "${TARGET_BIN}.tmp" "${APPIMAGE_URL}"
        mv "${TARGET_BIN}.tmp" "${TARGET_BIN}"
        chmod +x "${TARGET_BIN}"

        curl -fsSL -o "${INSTALL_DIR}/sample.scm" "https://raw.githubusercontent.com/${REPO}/main/sample.scm" 2>/dev/null || true
        curl -fsSL -o "${ICON_DIR}/scheme-emacs.svg" "https://raw.githubusercontent.com/${REPO}/main/assets/scheme-emacs.svg" 2>/dev/null || true
        curl -fsSL -o "${DESKTOP_DIR}/scheme-emacs.desktop" "https://raw.githubusercontent.com/${REPO}/main/assets/scheme-emacs.desktop" 2>/dev/null || true
    else
        TAR_URL="https://github.com/${REPO}/releases/download/${TAG}/scheme-emacs-${TAG}-linux-x86_64.tar.gz"
        curl -fsSL "${TAR_URL}" | tar -xzf - -C "${INSTALL_DIR}" --strip-components=1
        ln -sf "${INSTALL_DIR}/bin/scheme-emacs" "${TARGET_BIN}"
        chmod +x "${INSTALL_DIR}/bin/scheme-emacs" "${TARGET_BIN}"

        if [[ -f "${INSTALL_DIR}/assets/scheme-emacs.svg" ]]; then
            cp "${INSTALL_DIR}/assets/scheme-emacs.svg" "${ICON_DIR}/scheme-emacs.svg" 2>/dev/null || true
        fi
        if [[ -f "${INSTALL_DIR}/assets/scheme-emacs.desktop" ]]; then
            cp "${INSTALL_DIR}/assets/scheme-emacs.desktop" "${DESKTOP_DIR}/scheme-emacs.desktop" 2>/dev/null || true
        fi
    fi

    # 4. PATH Configuration
    echo -e "\n${BLUE}[3/3] Verifying shell environment...${NC}"
    if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
        SHELL_NAME="$(basename "${SHELL:-bash}")"
        RC_FILE="${HOME}/.bashrc"
        if [[ "${SHELL_NAME}" == "zsh" ]]; then
            RC_FILE="${HOME}/.zshrc"
        fi
        if [[ -f "${RC_FILE}" ]] && ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "${RC_FILE}"; then
            echo -e '\n# Scheme Emacs PATH' >> "${RC_FILE}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${RC_FILE}"
            echo -e "${GREEN}✓ Added ~/.local/bin to PATH in ${RC_FILE}${NC}"
        fi
        export PATH="${BIN_DIR}:${PATH}"
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
    fi

    echo -e "\n${GREEN}======================================================================${NC}"
    echo -e "${GREEN}${BOLD}🎉 Scheme Emacs Is Ready!${NC}"
    echo -e "${GREEN}======================================================================${NC}"
fi

# Ensure sample.scm is available in current directory if needed
if [[ ! -f "sample.scm" && -f "${INSTALL_DIR}/sample.scm" ]]; then
    cp "${INSTALL_DIR}/sample.scm" ./sample.scm 2>/dev/null || true
fi

# 5. Determine target file to launch
TARGET_FILE=""
if [[ ${#ARGS[@]} -gt 0 ]]; then
    # Arguments passed by user
    TARGET_FILE=("${ARGS[@]}")
else
    # Default to sample.scm
    if [[ -f "sample.scm" ]]; then
        TARGET_FILE=("sample.scm")
    elif [[ -f "${INSTALL_DIR}/sample.scm" ]]; then
        TARGET_FILE=("${INSTALL_DIR}/sample.scm")
    fi
fi

# 6. Reconnect TTY if run via pipe (curl | bash) and launch
if [[ "${SCHEME_EMACS_NO_LAUNCH:-0}" != "1" ]]; then
    if [ ! -t 0 ] && [ -e /dev/tty ]; then
        exec < /dev/tty
    fi

    if [[ ${#TARGET_FILE[@]} -gt 0 ]]; then
        exec "${TARGET_BIN}" "${TARGET_FILE[@]}"
    else
        exec "${TARGET_BIN}"
    fi
fi
