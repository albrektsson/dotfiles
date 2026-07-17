#!/usr/bin/env bash
# scripts/brew.sh — install Homebrew and restore packages
set -euo pipefail

PACKAGES_DIR="$DOTFILES_DIR/packages"

# ── Install Homebrew if missing ─────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for the rest of this script
  case "$OS" in
    mac)   eval "$(/opt/homebrew/bin/brew shellenv)" ;;
    linux) eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" ;;
  esac
else
  echo "  Homebrew already installed: $(brew --version | head -1)"
fi

# ── Install packages ────────────────────────────────────────────────────────
install_brewfile() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "  Installing from $(basename "$file")..."
    brew bundle install --file="$file" --no-lock
  else
    echo "  No $(basename "$file") found, skipping"
  fi
}

install_brewfile "$PACKAGES_DIR/Brewfile.common"
install_brewfile "$PACKAGES_DIR/Brewfile.$OS"
