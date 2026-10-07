# dotfiles — Claude Context

This repo manages Emil's dotfiles for **macOS** (work machine) and **Bazzite** (home Linux gaming/dev machine), using GNU Stow. It was set up in a claude.ai session on 2026-07-17 and this file exists so Claude Code can pick up that context.

## Owner

- Emil Albrektsson — AppSec team, NAV (Norwegian Labour and Welfare Administration)
- GitHub: `albrektsson` / org: `navikt`
- Work email: emil.albrektsson@nav.no

## Machines

| Machine | OS | Terminal | Shell |
|---|---|---|---|
| Work laptop | macOS | Ghostty | zsh (system default) |
| Home machine | Bazzite (immutable Fedora) | Konsole | zsh via Homebrew (NOT chsh — see below) |
| Home machine | CachyOS (Arch-based) | Konsole / Alacritty | zsh (system, `/usr/bin/zsh`) |

**CachyOS note:** packages come from **pacman**, not Homebrew (`packages/pacman.txt`, `scripts/pacman.sh`).
Bootstrap picks pacman on any Linux machine that has it. No `~/.zshenv`/`ZDOTDIR` is used there — `~/.zshrc`
is stowed straight into `$HOME`. oh-my-zsh is the `oh-my-zsh-git` package in `/usr/share/oh-my-zsh`
(`.zshrc` falls back to it when `~/.oh-my-zsh/oh-my-zsh.sh` is missing, and always sets
`ZSH_CUSTOM=~/.oh-my-zsh/custom`); zsh-autosuggestions is sourced from `/usr/share/zsh/plugins`.

**Bazzite shell note:** Do NOT use `chsh` or modify `/etc/passwd` on Bazzite — it breaks KDE login. Instead set zsh as a custom command in Konsole: Settings → Edit Current Profile → Command → `/home/linuxbrew/.linuxbrew/bin/zsh`.

## Stow packages

Each directory is a GNU Stow package. Files inside replicate their path relative to `$HOME`.

| Package | Target | Notes |
|---|---|---|
| `git/` | `~/.gitconfig` | Shared git config. Machine-specific paths via `[include] ~/.gitconfig.local` |
| `hooks/` | `~/.config/git/hooks/` | pre-commit secret scan via gitleaks |
| `opencode/` | `~/.config/opencode/opencode.json` | Uses `{env:HOME}` instead of hardcoded path in `external_directory` |
| `starship/` | `~/.config/starship.toml` | Pure preset plus k8s context and exit status, left prompt only (no right prompt). Uses no Nerd Font glyphs; bootstrap still installs FiraCode Nerd Font |
| `mise/` | `~/.config/mise/config.toml` | Global mise tools: fnox, java |
| `omz-custom/` | `~/.oh-my-zsh/custom/aliases.zsh` | Shell aliases and functions. Zoom links intentionally excluded (in `.zshrc.local`) |
| `vim/` | `~/.vimrc` | Loader for amix/vimrc runtime at `~/.vim_runtime` |
| `zsh/` | `~/.zshrc` | Shared zshrc. Machine-local overrides via `~/.zshrc.local` (never committed, see below) |

### Machine-specific packages (optional, only stowed if dir exists)
| Package | Machine |
|---|---|
| `mac/` | macOS only |
| `bazzite/` | Bazzite only |
| `cachyos/` | CachyOS only (Linux packages are named after `ID` in `/etc/os-release`) |

## Machine-local files (NOT tracked in this repo)

These must be created manually on each machine after bootstrap. Bootstrap will warn if they're missing.

### `~/.gitconfig.local`
Contains machine-specific git settings that can't be shared:

**macOS:**
```ini
[gpg]
    program = /opt/homebrew/bin/gpg

[credential "https://github.com"]
    helper =
    helper = !/opt/homebrew/bin/gh auth git-credential

[credential "https://gist.github.com"]
    helper =
    helper = !/opt/homebrew/bin/gh auth git-credential
```

**CachyOS:** same as Bazzite but with `/usr/bin/gpg` and `/usr/bin/gh`, plus `[user] signingkey` for that machine's GPG key.

**Bazzite:**
```ini
[gpg]
    program = /home/linuxbrew/.linuxbrew/bin/gpg

[credential "https://github.com"]
    helper =
    helper = !/home/linuxbrew/.linuxbrew/bin/gh auth git-credential

[credential "https://gist.github.com"]
    helper =
    helper = !/home/linuxbrew/.linuxbrew/bin/gh auth git-credential
```

### `~/.zshrc.local`
Machine-specific shell config sourced at the end of `.zshrc`. Written by hand directly on each
machine — **never templated or committed in this repo**, since it may hold secrets (e.g. Zoom
meeting links, tokens). `.gitignore` blocks both the exact file and any `.zshrc.local.*` variant
to make sure a stray copy never gets committed accidentally.

On macOS it typically includes: gcloud SDK, `CLOUDSDK_PYTHON`, `USE_GKE_GCLOUD_AUTH_PLUGIN`,
openssl PATH, kubectl aliases, Zoom link aliases.

## Intentionally NOT stowed

| Item | Reason |
|---|---|
| `~/.oh-my-zsh/` | git clone of framework, self-updates. Installed by bootstrap via installer script |
| `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/` | git clone, installed via `brew install zsh-autosuggestions` |
| `~/.oh-my-zsh/custom/example.zsh` | Installer placeholder, no personal content |
| `~/.oh-my-zsh/custom/pnpm.zsh` | Auto-generated. Regenerate with: `pnpm completion >> ~/.oh-my-zsh/custom/pnpm.zsh` |
| `~/.vim_runtime/` | git clone of amix/vimrc. Installed by bootstrap |
| `~/.ssh/` | Security — never commit SSH keys |
| `~/.gitconfig.local` | Machine-specific, see above |
| `~/.zshrc.local` | Machine-specific, see above |

## Bootstrap

```bash
git clone https://github.com/albrektsson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

### Steps (in order)
1. **packages** — pacman machines: installs missing packages from `packages/pacman.txt` (needs sudo). Otherwise: installs Homebrew if missing, then `Brewfile.common` + `Brewfile.<os>`
2. **omz** — installs oh-my-zsh if missing (`--unattended`, doesn't switch shell). pacman: provided by `oh-my-zsh-git`
3. **vim** — clones amix/vimrc to `~/.vim_runtime`, runs installer. On re-run: `git pull`
4. **fonts** — installs FiraCode Nerd Font (cask on mac, `ttf-firacode-nerd` on pacman, tarball download on Bazzite)
5. **linux-setup** — Bazzite only: `~/.zshenv` with Homebrew init + `ZDOTDIR`
6. **stow** — stows all packages with `--restow`. Pre-existing real files in the way are moved to `<file>.pre-dotfiles` first
7. **mise** — installs mise if missing, trusts and runs `mise install` on `~/.config/mise/config.toml` (after stow, so the config is linked)

### Skip flags
```bash
./bootstrap.sh --skip-packages --skip-omz --skip-vim --skip-mise --skip-fonts --skip-stow
```

### Selecting packages
```bash
./bootstrap.sh --only vim,zsh        # only these stow packages
./bootstrap.sh --except opencode     # everything but these
```
Setup steps follow their package (omz ↔ `zsh`/`omz-custom`, vim runtime ↔ `vim`, mise ↔ `mise`,
fonts ↔ `starship`, linux-setup ↔ `zsh`). `--only` also skips the system packages step.
Single package by hand: `stow -vt ~ <package>` (unlink with `-D`).

## Package management

Brewfiles live in `packages/`. Save current state with:
```bash
./scripts/save-packages.sh   # overwrites Brewfile.<os> with currently installed packages
git diff packages/            # review before committing
```

`Brewfile.common` — shared across all machines
`Brewfile.mac` — macOS only (taps, casks, NAV-specific tooling)
`Brewfile.linux` — Bazzite only (includes `zsh` since it's not bundled)
`pacman.txt` — CachyOS only, edited by hand (`save-packages.sh` does not snapshot pacman)

## Pre-commit hook

`hooks/.config/git/hooks/pre-commit` runs `gitleaks protect --staged --redact` before every commit.
Requires `brew install gitleaks`.
Bypass (use sparingly): `git commit --no-verify`

The hook must be executable. Bootstrap handles this via `chmod +x` at the end of `stow.sh`.

## Git authentication

- **GitHub remote:** HTTPS (`https://github.com/albrektsson/dotfiles.git`) using `gh auth git-credential`
- **Commit signing:** GPG key `EA22039549037368`
- **SSH key** (`~/.ssh/id_ed25519`) exists but GitHub SSH keys page may not have it registered — use HTTPS

To persist SSH key in macOS Keychain (if needed):
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## Key tools in use

| Tool | Purpose |
|---|---|
| `mise` | Runtime version manager (replaces nvm, rbenv, etc.) |
| `fnox` | Secret manager by jdx (same author as mise). Activated via `eval "$(fnox activate zsh)"` in `.zshrc` |
| `starship` | Cross-shell prompt |
| `gitleaks` | Secret scanning in pre-commit hook |
| `kubecolor` | `kubectl` is aliased to `kubecolor` in `aliases.zsh` |
| `gh` | GitHub CLI, used for git credential auth |

## Adding a new dotfile

```bash
mkdir -p ~/dotfiles/<package>/<path/relative/to/home>
mv ~/.<config> ~/dotfiles/<package>/.<config>
cd ~/dotfiles
stow -vt ~ <package>
# Add <package> to COMMON in scripts/stow.sh
git add . && git commit -m "feat: add <package> dotfiles"
```
