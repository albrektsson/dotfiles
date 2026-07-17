#!/usr/bin/env bash
# scripts/linux-setup.sh — Bazzite-specific setup
# - Creates ~/.zshenv with Homebrew init and ZDOTDIR
# - Creates ~/.config/zsh/ dir for XDG zsh config
set -euo pipefail

ZSHENV="$HOME/.zshenv"
ZSH_CONFIG_DIR="$HOME/.config/zsh"

# ── ZDOTDIR / .zshenv ────────────────────────────────────────────────────────
if [ -f "$ZSHENV" ]; then
  if grep -q "ZDOTDIR" "$ZSHENV"; then
    echo "  ~/.zshenv already configured"
  else
    echo "  ~/.zshenv exists but missing ZDOTDIR — appending..."
    cat >> "$ZSHENV" << 'EOF'

# Initialize Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# XDG zsh config dir — zsh reads this before .zshrc
export ZDOTDIR="$HOME/.config/zsh"
EOF
  fi
else
  echo "  Creating ~/.zshenv..."
  cat > "$ZSHENV" << 'EOF'
# Initialize Homebrew — must be first so all brew tools are on PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# XDG zsh config dir — zsh reads this before .zshrc
export ZDOTDIR="$HOME/.config/zsh"
EOF
fi

# ── XDG zsh config dir ───────────────────────────────────────────────────────
if [ ! -d "$ZSH_CONFIG_DIR" ]; then
  echo "  Creating $ZSH_CONFIG_DIR..."
  mkdir -p "$ZSH_CONFIG_DIR"
else
  echo "  $ZSH_CONFIG_DIR already exists"
fi

echo "  ~/.zshenv and ZDOTDIR configured"
