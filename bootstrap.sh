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
SKIP_LINUX_SETUP=false

for arg in "$@"; do
  case "$arg" in
    --skip-brew)         SKIP_BREW=true ;;
    --skip-stow)         SKIP_STOW=true ;;
    --skip-omz)          SKIP_OMZ=true ;;
    --skip-mise)         SKIP_MISE=true ;;
    --skip-vim)          SKIP_VIM=true ;;
    --skip-fonts)        SKIP_FONTS=true ;;
    --skip-linux-setup)  SKIP_LINUX_SETUP=true ;;
    --help)
      echo "Usage: bootstrap.sh [--skip-brew] [--skip-stow] [--skip-omz] [--skip-mise] [--skip-vim] [--skip-fonts] [--skip-linux-setup]"
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

run_step "Homebrew + packages" "$SCRIPTS_DIR/brew.sh"   "$SKIP_BREW"
run_step "oh-my-zsh"           "$SCRIPTS_DIR/omz.sh"    "$SKIP_OMZ"
run_step "vim runtime"         "$SCRIPTS_DIR/vim.sh"    "$SKIP_VIM"
run_step "mise"                "$SCRIPTS_DIR/mise.sh"   "$SKIP_MISE"
run_step "fonts"               "$SCRIPTS_DIR/fonts.sh"  "$SKIP_FONTS"

# Linux-specific setup must run before stow so dirs exist
if [ "$OS" = "linux" ]; then
  run_step "linux setup" "$SCRIPTS_DIR/linux-setup.sh" "$SKIP_LINUX_SETUP"
fi

run_step "stow dotfiles" "$SCRIPTS_DIR/stow.sh" "$SKIP_STOW"

# ── Check for machine-local files ───────────────────────────────────────────
MISSING_LOCALS=false
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Checking machine-local config files..."
echo

if [ ! -f "$HOME/.gitconfig.local" ]; then
  MISSING_LOCALS=true
  echo "  ⚠  ~/.gitconfig.local not found!"
  echo "     Create it with your machine-specific git settings:"
  echo
  case "$OS" in
    mac)
      cat <<'HEREDOC'
  [gpg]
      program = /opt/homebrew/bin/gpg

  [credential "https://github.com"]
      helper =
      helper = !/opt/homebrew/bin/gh auth git-credential

  [credential "https://gist.github.com"]
      helper =
      helper = !/opt/homebrew/bin/gh auth git-credential
HEREDOC
      ;;
    linux)
      cat <<'HEREDOC'
  [user]
      signingkey = <your-bazzite-gpg-key-id>

  [gpg]
      program = /home/linuxbrew/.linuxbrew/bin/gpg

  [credential "https://github.com"]
      helper =
      helper = !/home/linuxbrew/.linuxbrew/bin/gh auth git-credential

  [credential "https://gist.github.com"]
      helper =
      helper = !/home/linuxbrew/.linuxbrew/bin/gh auth git-credential
HEREDOC
      ;;
  esac
  echo
else
  echo "  ✓  ~/.gitconfig.local found"
fi

# zshrc.local lives in ZDOTDIR on linux, $HOME on mac
if [ "$OS" = "linux" ]; then
  ZSHRC_LOCAL="$HOME/.config/zsh/.zshrc.local"
  ZSHRC_LOCAL_TEMPLATE="cp ~/dotfiles/zsh/.config/zsh/.zshrc.local.bazzite ~/.config/zsh/.zshrc.local"
else
  ZSHRC_LOCAL="$HOME/.zshrc.local"
  ZSHRC_LOCAL_TEMPLATE="cp ~/dotfiles/zsh/.zshrc.local.mac ~/.zshrc.local"
fi

if [ ! -f "$ZSHRC_LOCAL" ]; then
  MISSING_LOCALS=true
  echo "  ⚠  $ZSHRC_LOCAL not found!"
  echo "     Copy the template and edit as needed:"
  echo
  echo "     $ZSHRC_LOCAL_TEMPLATE"
  echo
else
  echo "  ✓  $ZSHRC_LOCAL found"
fi

echo
if [ "$MISSING_LOCALS" = true ]; then
  echo "  ⚠  Some machine-local files are missing — see above."
else
  echo "  ✓  All machine-local files present."
fi

if [ "$OS" = "linux" ]; then
  echo
  echo "  ℹ  Konsole: set shell to $(which zsh 2>/dev/null || echo '/home/linuxbrew/.linuxbrew/bin/zsh')"
  echo "     Settings → Edit Current Profile → Command"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All done! Restart your shell."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
