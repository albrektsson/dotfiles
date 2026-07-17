#!/usr/bin/env bash
# bootstrap.sh — set up a fresh machine from dotfiles
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Detect OS
case "$(uname -s)" in
  Darwin) OS="mac" ;;
  Linux)  OS="linux" ;;
  *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

export DOTFILES_DIR OS

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  dotfiles bootstrap — $OS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Parse flags
SKIP_BREW=false
SKIP_STOW=false
SKIP_OMZ=false
SKIP_MISE=false
SKIP_VIM=false
SKIP_FONTS=false

for arg in "$@"; do
  case "$arg" in
    --skip-brew)  SKIP_BREW=true ;;
    --skip-stow)  SKIP_STOW=true ;;
    --skip-omz)   SKIP_OMZ=true ;;
    --skip-mise)  SKIP_MISE=true ;;
    --skip-vim)   SKIP_VIM=true ;;
    --skip-fonts) SKIP_FONTS=true ;;
    --help)
      echo "Usage: bootstrap.sh [--skip-brew] [--skip-omz] [--skip-vim] [--skip-mise] [--skip-fonts] [--skip-stow]"
      exit 0
      ;;
  esac
done

run_step() {
  local name="$1"
  local script="$2"
  local skip="$3"

  if [ "$skip" = true ]; then
    echo "⏭  Skipping $name"
    return
  fi

  echo "▶  $name"
  bash "$script"
  echo "✓  $name done"
  echo
}

run_step "Homebrew + packages" "$SCRIPTS_DIR/brew.sh"  "$SKIP_BREW"
run_step "oh-my-zsh"           "$SCRIPTS_DIR/omz.sh"   "$SKIP_OMZ"
run_step "vim runtime"         "$SCRIPTS_DIR/vim.sh"   "$SKIP_VIM"
run_step "mise"                "$SCRIPTS_DIR/mise.sh"  "$SKIP_MISE"
run_step "fonts"               "$SCRIPTS_DIR/fonts.sh" "$SKIP_FONTS"
run_step "stow dotfiles"       "$SCRIPTS_DIR/stow.sh"  "$SKIP_STOW"

# ── Check for machine-local git config ──────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ! -f "$HOME/.gitconfig.local" ]; then
  echo
  echo "  ⚠  ~/.gitconfig.local not found!"
  echo
  echo "  Create it with your machine-specific git settings:"
  echo
  case "$OS" in
    mac)
      cat <<'EOF'
  ~/.gitconfig.local (macOS):

  [gpg]
      program = /opt/homebrew/bin/gpg

  [credential "https://github.com"]
      helper =
      helper = !/opt/homebrew/bin/gh auth git-credential

  [credential "https://gist.github.com"]
      helper =
      helper = !/opt/homebrew/bin/gh auth git-credential
EOF
      ;;
    linux)
      cat <<'EOF'
  ~/.gitconfig.local (Linux/Bazzite):

  [gpg]
      program = /home/linuxbrew/.linuxbrew/bin/gpg

  [credential "https://github.com"]
      helper =
      helper = !/home/linuxbrew/.linuxbrew/bin/gh auth git-credential

  [credential "https://gist.github.com"]
      helper =
      helper = !/home/linuxbrew/.linuxbrew/bin/gh auth git-credential
EOF
      ;;
  esac
  echo
else
  echo "  ✓  ~/.gitconfig.local found"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All done! Restart your shell."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
