#!/usr/bin/env bash
# scripts/pacman.sh — install packages with pacman (Arch-based distros, e.g. CachyOS)
set -euo pipefail

PACFILE="$DOTFILES_DIR/packages/pacman.txt"

if [ ! -f "$PACFILE" ]; then
  echo "  No $(basename "$PACFILE") found, skipping"
  exit 0
fi

# Strip comments and blank lines
mapfile -t PKGS < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$PACFILE")

# pacman -T prints the packages that are not installed yet — only sudo if needed
mapfile -t MISSING < <(pacman -T "${PKGS[@]}" || true)

if [ "${#MISSING[@]}" -eq 0 ]; then
  echo "  All ${#PKGS[@]} packages from $(basename "$PACFILE") already installed"
  exit 0
fi

echo "  Installing: ${MISSING[*]}"
sudo pacman -S --needed "${MISSING[@]}"
