DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPOFIX="true"
DISABLE_AUTO_UPDATE="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Homebrew completions — brew must be on PATH already (set in .zprofile)
if command -v brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Smarter completion initialization
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

# oh-my-zsh: user install in ~/.oh-my-zsh, or the distro package on Arch (oh-my-zsh-git)
if [ -z "$ZSH" ]; then
  if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    ZSH="$HOME/.oh-my-zsh"
  else
    ZSH="/usr/share/oh-my-zsh"
  fi
fi
export ZSH
# Stowed by the omz-custom package — always in $HOME, even when omz itself isn't
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

plugins=(
  git
  fzf
)
# zsh-autosuggestions: omz custom plugin if present, else the distro package (sourced below)
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && plugins+=(zsh-autosuggestions)

ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

source $ZSH/oh-my-zsh.sh

if (( ! ${plugins[(Ie)zsh-autosuggestions]} )) && \
   [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# GPG
export GPG_TTY=$(tty)

# Locale
export LC_CTYPE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Common PATH additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export OPENCODE_EXPERIMENTAL_LSP_TOOL=true
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# Machine-local config (not tracked in dotfiles)
[ -f "${ZDOTDIR:-$HOME}/.zshrc.local" ] && source "${ZDOTDIR:-$HOME}/.zshrc.local"

# Tool init — at the end so PATH is fully set
source <(fzf --zsh)
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
command -v fnox &>/dev/null && eval "$(fnox activate zsh)"
