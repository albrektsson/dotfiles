#!/usr/bin/env bash
# scripts/fonts.sh — install FiraCode Nerd Font (required by starship prompt icons)
set -euo pipefail

FONT_NAME="FiraCode Nerd Font"

case "$OS" in
  mac)
    if brew list --cask font-fira-code-nerd-font &>/dev/null; then
      echo "  $FONT_NAME already installed"
    else
      echo "  Installing $FONT_NAME via brew cask..."
      brew install --cask font-fira-code-nerd-font
    fi
    ;;
  linux)
    FONT_DIR="$HOME/.local/share/fonts/FiraCodeNerdFont"
    if [ -d "$FONT_DIR" ] && [ -n "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
      echo "  $FONT_NAME already installed"
    else
      echo "  Installing $FONT_NAME..."
      mkdir -p "$FONT_DIR"
      TMPZIP="$(mktemp -d)/FiraCode.zip"
      curl -fsSL -o "$TMPZIP" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
      unzip -oq "$TMPZIP" -d "$FONT_DIR"
      rm -f "$TMPZIP"
      fc-cache -f "$FONT_DIR" &>/dev/null || true
    fi
    ;;
esac
