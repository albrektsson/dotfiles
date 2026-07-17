#!/usr/bin/env bash
# scripts/omz.sh — install oh-my-zsh (skip if already present)
set -euo pipefail

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [ -d "$OMZ_DIR" ]; then
  echo "  oh-my-zsh already installed at $OMZ_DIR"
  exit 0
fi

echo "  Installing oh-my-zsh..."
# --unattended: don't switch shell or start a new one mid-script
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended

echo "  oh-my-zsh installed"
