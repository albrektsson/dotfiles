#!/usr/bin/env bash
# scripts/stow.sh — link dotfiles with GNU stow
set -euo pipefail

if ! command -v stow &>/dev/null; then
  echo "  stow not found — install it first (brew install stow / pacman -S stow)"
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
  linux) EXTRA=("${DISTRO:-bazzite}") ;;
esac

# Narrowed by bootstrap.sh --only / --except (comma-separated package names)
selected() {
  case ",${STOW_EXCEPT:-}," in *",$1,"*) return 1 ;; esac
  [ -z "${STOW_ONLY:-}" ] && return 0
  case ",$STOW_ONLY," in *",$1,"*) return 0 ;; esac
  return 1
}

PACKAGES=()
for pkg in "${COMMON[@]}"; do
  selected "$pkg" && PACKAGES+=("$pkg")
done
for pkg in "${EXTRA[@]}"; do
  [ -d "$DOTFILES_DIR/$pkg" ] && selected "$pkg" && PACKAGES+=("$pkg")
done

if [ "${#PACKAGES[@]}" -eq 0 ]; then
  echo "  Nothing selected to stow"
  exit 0
fi

echo "  Stowing: ${PACKAGES[*]}"

# Move pre-existing real files out of the way so stow doesn't abort on conflicts
# (e.g. distro default ~/.zshrc, ~/.vimrc written by the amix installer).
backup_conflicts() {
  local pkg="$1" src target
  while IFS= read -r -d '' src; do
    target="$HOME/${src#"$pkg"/}"
    [ -e "$target" ] || continue
    [ -L "$target" ] && continue
    # Already ours via a symlinked parent dir
    [ "$(realpath "$target")" = "$(realpath "$src")" ] && continue
    echo "    Backing up existing $target → $target.pre-dotfiles"
    mv "$target" "$target.pre-dotfiles"
  done < <(find "$pkg" -type f -print0)
}

for pkg in "${PACKAGES[@]}"; do
  if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
    echo "  ⚠  Package '$pkg' not found, skipping"
    continue
  fi

  backup_conflicts "$pkg"

  # --restow re-links cleanly if already stowed
  stow --restow -vt "$HOME" "$pkg" 2>&1 | sed 's/^/    /'
done

# Ensure hooks are executable
chmod +x "$HOME/.config/git/hooks/"* 2>/dev/null || true
