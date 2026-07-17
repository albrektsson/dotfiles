#!/usr/bin/env bash
# scripts/mise.sh — install mise and trust the global config
set -euo pipefail

if ! command -v mise &>/dev/null; then
  echo "  Installing mise..."
  curl https://mise.run | sh

  # Add to PATH for the rest of this script
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "  mise already installed: $(mise --version)"
fi

# Trust the global config (mise requires explicit trust)
MISE_CONFIG="$HOME/.config/mise/config.toml"
if [ -f "$MISE_CONFIG" ]; then
  echo "  Trusting $MISE_CONFIG..."
  mise trust "$MISE_CONFIG"
  echo "  Installing mise tools..."
  mise install
else
  echo "  No mise config found at $MISE_CONFIG (will be linked by stow later)"
fi
