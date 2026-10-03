#!/usr/bin/env bash
# scripts/omz.sh — install oh-my-zsh (skip if already present)
set -euo pipefail

# Arch-based: oh-my-zsh comes from the oh-my-zsh-git package (packages/pacman.txt)
if [ "${PKG_MANAGER:-}" = "pacman" ]; then
  if [ -f /usr/share/oh-my-zsh/oh-my-zsh.sh ]; then
    echo "  oh-my-zsh already installed at /usr/share/oh-my-zsh (pacman)"
  else
    echo "  Installing oh-my-zsh via pacman..."
    sudo pacman -S --needed oh-my-zsh-git
  fi
  exit 0
fi

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"

# Check for oh-my-zsh.sh, not just the dir — stow may have created ~/.oh-my-zsh/custom
if [ -f "$OMZ_DIR/oh-my-zsh.sh" ]; then
  echo "  oh-my-zsh already installed at $OMZ_DIR"
  exit 0
fi

echo "  Installing oh-my-zsh..."
# --unattended: don't switch shell or start a new one mid-script
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended

echo "  oh-my-zsh installed"
