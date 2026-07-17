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
./bootstrap.sh --skip-omz --skip-mise
```

## Structure

```
dotfiles/
├── bootstrap.sh          # entry point
├── scripts/
│   ├── brew.sh           # install Homebrew + packages
│   ├── omz.sh            # install oh-my-zsh
│   ├── mise.sh           # install mise + tools
│   ├── stow.sh           # link dotfiles
│   └── save-packages.sh  # snapshot installed packages
├── packages/
│   ├── Brewfile.common   # shared brew packages
│   ├── Brewfile.mac      # mac-only
│   └── Brewfile.linux    # bazzite-only
├── opencode/             # ~/.config/opencode/
├── starship/             # ~/.config/starship.toml
├── mise/                 # ~/.config/mise/
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
