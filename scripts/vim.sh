#!/usr/bin/env bash
# scripts/vim.sh — install amix/vimrc (the ultimate vimrc) to ~/.vim_runtime
set -euo pipefail

VIM_RUNTIME="$HOME/.vim_runtime"

if [ -d "$VIM_RUNTIME" ]; then
  echo "  Updating existing $VIM_RUNTIME..."
  git -C "$VIM_RUNTIME" pull --ff-only
else
  echo "  Cloning amix/vimrc to $VIM_RUNTIME..."
  git clone --depth=1 https://github.com/amix/vimrc.git "$VIM_RUNTIME"
  sh "$VIM_RUNTIME/install_awesome_vimrc.sh"
fi
