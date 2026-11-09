#!/usr/bin/env bash
# Forwarder to scheme-emacs.sh for backward compatibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/scheme-emacs.sh" ]]; then
    exec "${SCRIPT_DIR}/scheme-emacs.sh" "$@"
else
    curl -fsSL https://raw.githubusercontent.com/ouut/scheme_emacs/main/scheme-emacs.sh | bash -s -- "$@"
fi
