#!/usr/bin/env bash
# scripts/stow.sh — link dotfiles with GNU stow
set -euo pipefail

if ! command -v stow &>/dev/null; then
  echo "  stow not found — install it first (brew install stow)"
  exit 1
fi

cd "$DOTFILES_DIR"

# Packages stowed on all machines
COMMON=(
  git
  hooks
  opencode
  starship
  mise
  omz-custom
  vim
  zsh
)

# Machine-specific packages (directories must exist to be stowed)
case "$OS" in
  mac)   EXTRA=(mac) ;;
  linux) EXTRA=(bazzite) ;;
esac

PACKAGES=("${COMMON[@]}")
for pkg in "${EXTRA[@]}"; do
  [ -d "$DOTFILES_DIR/$pkg" ] && PACKAGES+=("$pkg")
done

echo "  Stowing: ${PACKAGES[*]}"

for pkg in "${PACKAGES[@]}"; do
  if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
    echo "  ⚠  Package '$pkg' not found, skipping"
    continue
  fi

  # --restow re-links cleanly if already stowed
  stow --restow -vt "$HOME" "$pkg" 2>&1 | sed 's/^/    /'
done

# Ensure hooks are executable
chmod +x "$HOME/.config/git/hooks/"* 2>/dev/null || true
