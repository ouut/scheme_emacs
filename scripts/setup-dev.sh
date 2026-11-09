#!/usr/bin/env bash
# ==============================================================================
# Development Environment Setup Script for Scheme Emacs
# Sets up Rust Steel, installs Emacs ELPA packages, and runs ERT test suite.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  🛠️  Scheme Emacs - Developer Environment Setup  ${NC}"
echo -e "${BLUE}======================================================================${NC}"

# 1. Check Emacs
echo -e "\n${BLUE}[1/5] Checking GNU Emacs...${NC}"
if command -v emacs >/dev/null 2>&1; then
    EMACS_VERSION="$(emacs --version | head -n1)"
    echo -e "${GREEN}✓ Found GNU Emacs:${NC} ${EMACS_VERSION}"
else
    echo -e "${RED}✗ Emacs is not installed!${NC}"
    echo "Please install Emacs 28+ using your package manager:"
    echo "  - Ubuntu/Debian:  sudo apt install emacs-nox (or emacs)"
    echo "  - macOS:          brew install emacs"
    echo "  - Fedora:         sudo dnf install emacs"
    echo "  - Arch Linux:     sudo pacman -S emacs"
    exit 1
fi

# 2. Check Rust & Cargo (Optional if downloading pre-compiled)
echo -e "\n${BLUE}[2/5] Checking Rust & Cargo (Optional)...${NC}"
if command -v cargo >/dev/null 2>&1; then
    CARGO_VERSION="$(cargo --version)"
    echo -e "${GREEN}✓ Found Cargo:${NC} ${CARGO_VERSION}"
else
    echo -e "${YELLOW}ℹ Cargo not found; setup will download official pre-compiled Steel binary.${NC}"
fi

# 3. Check & Install Rust Steel Scheme Interpreter
echo -e "\n${BLUE}[3/5] Setting up Rust Steel Scheme Interpreter (v0.8.2)...${NC}"
mkdir -p "${ROOT_DIR}/bin"

STEEL_BIN=""
if [[ -x "${ROOT_DIR}/bin/steel" ]]; then
    STEEL_BIN="${ROOT_DIR}/bin/steel"
elif [[ -x "${HOME}/.cargo/bin/steel" ]]; then
    STEEL_BIN="${HOME}/.cargo/bin/steel"
elif command -v steel >/dev/null 2>&1; then
    STEEL_BIN="$(command -v steel)"
fi

if [[ -z "${STEEL_BIN}" ]]; then
    echo -e "${YELLOW}Steel Scheme interpreter not found. Downloading official pre-compiled binary...${NC}"
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    DOWNLOADED=false
    
    if [[ "${OS}" == "Linux" && "${ARCH}" == "x86_64" ]]; then
        URL="https://github.com/mattwparas/steel/releases/download/v0.8.2/steel-interpreter-x86_64-unknown-linux-gnu.tar.xz"
        curl -fsSL "${URL}" | tar -xJf - --strip-components=1 -C "${ROOT_DIR}/bin" steel-interpreter-x86_64-unknown-linux-gnu/steel 2>/dev/null && DOWNLOADED=true
    elif [[ "${OS}" == "Linux" && "${ARCH}" == "aarch64" ]]; then
        URL="https://github.com/mattwparas/steel/releases/download/v0.8.2/steel-interpreter-aarch64-unknown-linux-gnu.tar.xz"
        curl -fsSL "${URL}" | tar -xJf - --strip-components=1 -C "${ROOT_DIR}/bin" steel-interpreter-aarch64-unknown-linux-gnu/steel 2>/dev/null && DOWNLOADED=true
    elif [[ "${OS}" == "Darwin" && "${ARCH}" == "arm64" ]]; then
        URL="https://github.com/mattwparas/steel/releases/download/v0.8.2/steel-interpreter-aarch64-apple-darwin.tar.xz"
        curl -fsSL "${URL}" | tar -xJf - --strip-components=1 -C "${ROOT_DIR}/bin" steel-interpreter-aarch64-apple-darwin/steel 2>/dev/null && DOWNLOADED=true
    fi
    
    if [[ "${DOWNLOADED}" == "true" && -x "${ROOT_DIR}/bin/steel" ]]; then
        chmod +x "${ROOT_DIR}/bin/steel"
        STEEL_BIN="${ROOT_DIR}/bin/steel"
        echo -e "${GREEN}✓ Successfully downloaded pre-compiled Steel 0.8.2 binary!${NC}"
    elif command -v cargo >/dev/null 2>&1; then
        echo -e "${YELLOW}Pre-compiled binary unavailable for ${OS}-${ARCH}; building via cargo...${NC}"
        cargo install steel-interpreter --version 0.8.2 --locked
        STEEL_BIN="${HOME}/.cargo/bin/steel"
    else
        echo -e "${RED}✗ Failed to download pre-compiled binary and cargo is not installed.${NC}"
        exit 1
    fi
fi

# Link / copy to local bin/
if [[ "${STEEL_BIN}" != "${ROOT_DIR}/bin/steel" ]]; then
    cp "${STEEL_BIN}" "${ROOT_DIR}/bin/steel"
    chmod +x "${ROOT_DIR}/bin/steel"
fi

STEEL_VER="$("${ROOT_DIR}/bin/steel" --version 2>&1 || true)"
echo -e "${GREEN}✓ Steel Scheme ready:${NC} ${STEEL_VER} (${ROOT_DIR}/bin/steel)"

# 4. Install & Vendor ELPA Packages
echo -e "\n${BLUE}[4/5] Installing & Vendoring ELPA Packages (offline cache)...${NC}"
mkdir -p "${ROOT_DIR}/elpa"
emacs --batch --init-directory "${ROOT_DIR}" -l "${ROOT_DIR}/init.el" \
    --eval '(message "All required packages installed into: %s" package-user-dir)'

# Byte-compile Elisp modules
echo -e "\n${BLUE}[5/5] Byte-compiling Elisp modules for fast startup...${NC}"
emacs -batch -Q \
    -L "${ROOT_DIR}/lisp" \
    -l "${ROOT_DIR}/early-init.el" \
    -l "${ROOT_DIR}/init.el" \
    -f batch-byte-compile \
    "${ROOT_DIR}"/lisp/*.el "${ROOT_DIR}"/early-init.el "${ROOT_DIR}"/init.el

# 5. Run Regression Tests
echo -e "\n${BLUE}🧪 Running ERT Regression Test Suite...${NC}"
emacs -batch -l "${ROOT_DIR}/test_config.el" -f ert-run-tests-batch-and-exit

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}🎉 Development Environment Successfully Configured!${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo -e "You can now start developing and testing immediately:"
echo -e "  - Launch Interactive Playground: ${YELLOW}./bin/scheme-emacs sample.scm${NC}"
echo -e "  - Run Automated Tests:           ${YELLOW}make test${NC} (or ${YELLOW}emacs -batch -l test_config.el -f ert-run-tests-batch-and-exit${NC})"
echo -e "  - Build Standalone Package:      ${YELLOW}./scripts/build.sh${NC}"
echo -e "${GREEN}======================================================================${NC}"
