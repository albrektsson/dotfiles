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

# Detect distro + package manager. Arch-based distros (CachyOS) use pacman,
# everything else (macOS, Bazzite) uses Homebrew.
DISTRO=""
PKG_MANAGER="brew"
if [ "$OS" = "linux" ]; then
  [ -r /etc/os-release ] && DISTRO="$(. /etc/os-release && echo "${ID:-}")"
  command -v pacman &>/dev/null && PKG_MANAGER="pacman"
fi

export DOTFILES_DIR OS DISTRO PKG_MANAGER

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  dotfiles bootstrap — $OS${DISTRO:+ ($DISTRO)}, $PKG_MANAGER"
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

ONLY=""
EXCEPT=""

usage() {
  cat <<'HEREDOC'
Usage: bootstrap.sh [options]

Pick which dotfile packages to set up (comma-separated stow package names):
  --only vim,zsh       only these packages
  --except opencode    everything but these packages

Setup steps follow their package: oh-my-zsh (zsh, omz-custom), vim runtime (vim),
mise tools (mise), fonts (starship). --only also skips system package installation.

Skip individual steps:
  --skip-packages (alias: --skip-brew)  --skip-omz  --skip-vim  --skip-fonts
  --skip-linux-setup  --skip-stow  --skip-mise
HEREDOC
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-brew|--skip-packages) SKIP_BREW=true ;;
    --skip-stow)         SKIP_STOW=true ;;
    --skip-omz)          SKIP_OMZ=true ;;
    --skip-mise)         SKIP_MISE=true ;;
    --skip-vim)          SKIP_VIM=true ;;
    --skip-fonts)        SKIP_FONTS=true ;;
    --skip-linux-setup)  SKIP_LINUX_SETUP=true ;;
    --only=*)            ONLY="${1#*=}" ;;
    --except=*)          EXCEPT="${1#*=}" ;;
    --only|--except)
      [ $# -ge 2 ] || { echo "$1 needs a comma-separated list of packages"; exit 1; }
      [ "$1" = "--only" ] && ONLY="$2" || EXCEPT="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo
      usage
      exit 1
      ;;
  esac
  shift
done

# Every name given to --only/--except must be a stow package in this repo
for pkg in ${ONLY//,/ } ${EXCEPT//,/ }; do
  case "$pkg" in
    scripts|packages) valid=false ;;
    *) [ -d "$DOTFILES_DIR/$pkg" ] && valid=true || valid=false ;;
  esac
  if [ "$valid" = false ]; then
    echo "Unknown dotfile package: $pkg"
    exit 1
  fi
done

# Is dotfile package $1 selected by --only/--except?
wants() {
  case ",$EXCEPT," in *",$1,"*) return 1 ;; esac
  [ -z "$ONLY" ] && return 0
  case ",$ONLY," in *",$1,"*) return 0 ;; esac
  return 1
}

# Setup steps follow their dotfile package
[ -n "$ONLY" ] && SKIP_BREW=true
wants zsh || wants omz-custom || SKIP_OMZ=true
wants zsh      || SKIP_LINUX_SETUP=true
wants vim      || SKIP_VIM=true
wants mise     || SKIP_MISE=true
wants starship || SKIP_FONTS=true

export STOW_ONLY="$ONLY" STOW_EXCEPT="$EXCEPT"

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

if [ "$PKG_MANAGER" = "pacman" ]; then
  run_step "pacman packages"   "$SCRIPTS_DIR/pacman.sh" "$SKIP_BREW"
else
  run_step "Homebrew + packages" "$SCRIPTS_DIR/brew.sh" "$SKIP_BREW"
fi
run_step "oh-my-zsh"           "$SCRIPTS_DIR/omz.sh"    "$SKIP_OMZ"
run_step "vim runtime"         "$SCRIPTS_DIR/vim.sh"    "$SKIP_VIM"
run_step "fonts"               "$SCRIPTS_DIR/fonts.sh"  "$SKIP_FONTS"

# Homebrew-on-Linux (Bazzite) setup must run before stow so dirs exist.
# Not needed with pacman: zsh and all tools are already on the system PATH.
if [ "$OS" = "linux" ] && [ "$PKG_MANAGER" = "brew" ]; then
  run_step "linux setup" "$SCRIPTS_DIR/linux-setup.sh" "$SKIP_LINUX_SETUP"
fi

run_step "stow dotfiles" "$SCRIPTS_DIR/stow.sh" "$SKIP_STOW"

# mise runs after stow so ~/.config/mise/config.toml is linked on first run
run_step "mise"                "$SCRIPTS_DIR/mise.sh"   "$SKIP_MISE"

# ── Check for machine-local files ───────────────────────────────────────────
MISSING_LOCALS=false
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Checking machine-local config files..."
echo

if ! wants git; then
  :
elif [ ! -f "$HOME/.gitconfig.local" ]; then
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
      if [ "$PKG_MANAGER" = "pacman" ]; then
        cat <<'HEREDOC'
  [user]
      signingkey = <your-gpg-key-id>

  [gpg]
      program = /usr/bin/gpg

  [credential "https://github.com"]
      helper =
      helper = !/usr/bin/gh auth git-credential

  [credential "https://gist.github.com"]
      helper =
      helper = !/usr/bin/gh auth git-credential
HEREDOC
      else
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
      fi
      ;;
  esac
  echo
else
  echo "  ✓  ~/.gitconfig.local found"
fi

# zshrc.local lives in ZDOTDIR on Bazzite (brew), $HOME elsewhere
if [ "$OS" = "linux" ] && [ "$PKG_MANAGER" = "brew" ]; then
  ZSHRC_LOCAL="$HOME/.config/zsh/.zshrc.local"
else
  ZSHRC_LOCAL="$HOME/.zshrc.local"
fi

if ! wants zsh; then
  :
elif [ ! -f "$ZSHRC_LOCAL" ]; then
  MISSING_LOCALS=true
  echo "  ⚠  $ZSHRC_LOCAL not found!"
  echo "     Create it by hand for machine-specific shell config (never committed)."
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

if [ "$OS" = "linux" ] && [ "$PKG_MANAGER" = "brew" ]; then
  echo
  echo "  ℹ  Konsole: set shell to $(which zsh 2>/dev/null || echo '/home/linuxbrew/.linuxbrew/bin/zsh')"
  echo "     Settings → Edit Current Profile → Command"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All done! Restart your shell."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
