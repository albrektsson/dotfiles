#!/usr/bin/env bash
# scripts/save-packages.sh — snapshot currently installed brew packages
# Run this manually when you want to save your current state:
#   ./scripts/save-packages.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/packages"

case "$(uname -s)" in
  Darwin) OS="mac" ;;
  Linux)  OS="linux" ;;
  *)      echo "Unsupported OS"; exit 1 ;;
esac

if ! command -v brew &>/dev/null; then
  echo "Homebrew not found"
  exit 1
fi

OUTFILE="$PACKAGES_DIR/Brewfile.$OS"
TMPFILE="$(mktemp)"

echo "Saving installed packages to $OUTFILE..."

# brew bundle dump writes formulae, casks, taps — everything
brew bundle dump --force --file="$TMPFILE"

# Keep the header comment, then append the dump
{
  echo "# Brewfile.$OS — packages installed on $OS"
  echo "# Saved: $(date '+%Y-%m-%d %H:%M')"
  echo "# Update with: ./scripts/save-packages.sh"
  echo
  # Filter out the tap/formula/cask lines from the dump
  grep -E '^(tap|brew|cask|mas|vscode) ' "$TMPFILE" || true
} > "$OUTFILE"

rm "$TMPFILE"

echo "Done. Review the diff before committing:"
echo
git -C "$DOTFILES_DIR" diff packages/
