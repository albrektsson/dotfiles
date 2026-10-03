# dotfiles

Personal dotfiles for macOS and Bazzite, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Bootstrap a fresh machine

```bash
git clone git@github.com:albrektsson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

Skip individual steps if needed:

```bash
./bootstrap.sh --skip-packages --skip-omz --skip-vim --skip-mise --skip-fonts --skip-stow
```

## Picking what to install

Each top-level directory except `scripts/` and `packages/` is a stow package. Select them by name:

```bash
./bootstrap.sh --only vim              # just the vim files (+ the vim runtime)
./bootstrap.sh --only vim,zsh,starship
./bootstrap.sh --except opencode       # everything but opencode
```

Setup steps follow their package: oh-my-zsh runs for `zsh`/`omz-custom`, the vim runtime for `vim`,
mise tools for `mise`, fonts for `starship`. `--only` also skips system package installation
(pacman/Homebrew), so `stow` must already be installed.

To link or unlink a single package by hand, use stow directly:

```bash
cd ~/dotfiles
stow -vt ~ vim              # link
stow -vt ~ --restow vim     # re-link after adding/removing files
stow -vt ~ -D opencode      # unlink
stow -nvt ~ vim             # dry run — show what would happen
```

## Structure

```
dotfiles/
├── bootstrap.sh          # entry point
├── scripts/
│   ├── brew.sh           # install Homebrew + packages (macOS, Bazzite)
│   ├── pacman.sh         # install pacman packages (CachyOS / Arch-based)
│   ├── omz.sh            # install oh-my-zsh
│   ├── vim.sh            # clone/update amix/vimrc runtime
│   ├── mise.sh           # install mise + tools
│   ├── fonts.sh          # install FiraCode Nerd Font
│   ├── stow.sh           # link dotfiles
│   └── save-packages.sh  # snapshot installed packages
├── packages/
│   ├── Brewfile.common   # shared brew packages
│   ├── Brewfile.mac      # mac-only
│   ├── Brewfile.linux    # bazzite-only
│   └── pacman.txt        # cachyos-only, edited by hand
├── hooks/                # ~/.config/git/hooks/ (gitleaks pre-commit)
├── opencode/             # ~/.config/opencode/
├── starship/             # ~/.config/starship.toml
├── mise/                 # ~/.config/mise/
├── vim/                  # ~/.vimrc (loader for ~/.vim_runtime)
├── zsh/                  # ~/.zshrc (machine-local overrides written by hand, never committed)
├── mac/                  # mac-only dotfiles (optional)
└── bazzite/              # bazzite-only dotfiles (optional)
```

## Saving installed packages

When you install something new and want to persist it:

```bash
./scripts/save-packages.sh
git add packages/
git commit -m "packages: add <whatever>"
```

## Adding a new dotfile

```bash
# e.g. for ~/.config/bat/config
mkdir -p ~/dotfiles/bat/.config/bat
mv ~/.config/bat/config ~/dotfiles/bat/.config/bat/config
cd ~/dotfiles
stow -vt ~ bat
```
