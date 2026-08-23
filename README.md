# shekse-dev-setup

Declarative macOS system configuration, built with [nix-darwin](https://github.com/nix-darwin/nix-darwin) + [home-manager](https://github.com/nix-community/home-manager), with Homebrew managed underneath via [nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

The whole machine setup - system defaults, Homebrew packages, CLI tools, shell, editor and terminal config, Claude Code settings - is described in a handful of files in `dotfiles/` and applied with one command. Re-running that command always converges the machine back to exactly what's declared here (see "Warning: Homebrew cleanup" below).

## What's in here

```
dotfiles/
├── flake.nix          # entry point: wires nix-darwin + home-manager + nix-homebrew together
├── configuration.nix  # system-level config (macOS defaults, Homebrew packages/casks)
├── home.nix           # user-level config (CLI tools, zsh, starship, dotfile symlinks)
├── bootstrap.sh        # first-time setup: fixes the username in flake.nix, then calls rebuild.sh
├── rebuild.sh          # applies the config to the machine
├── AGENTS.md           # notes for coding agents working in this repo
└── home/               # actual dotfiles, symlinked into place by home.nix
    ├── AGENTS.md        # global agent instructions, symlinked to ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, ~/.config/opencode/AGENTS.md
    ├── .claude/
    │   ├── settings.json  # local-only, not tracked in git (see .gitignore)
    │   └── skills/         # Claude Code skills, symlinked to ~/.claude/skills
    └── .config/
        ├── wezterm/     # terminal config, symlinked to ~/.config/wezterm
        ├── nvim/        # editor config, symlinked to ~/.config/nvim
        └── herdr/       # symlinked to ~/.config/herdr (runtime files gitignored)
```

## What gets installed where

Running `rebuild.sh` will:

1. Symlink this repo to `~/.dotfiles`.
2. Apply `configuration.nix` (system level, via nix-darwin):
   - macOS defaults: dark mode, auto-hide menu bar, auto-hide dock, Finder list view with no desktop icons, tap-to-click trackpad.
   - Homebrew casks: `wezterm`, `claude-code`, `corretto@17`, `corretto@11`.
   - Homebrew formulas: `herdr`, `opencode`, `python@3.13`, `node`, `gh`, `docker`, `docker-compose`, `docker-buildx`, `colima`, `container`.
3. Apply `home.nix` (user level, via home-manager), installing via Nix (not Homebrew):
   - CLI tools: `ripgrep`, `fd`, `fzf`, `jq`, `lazygit`, `neovim`, `bun`.
   - Fonts: Hack Nerd Font.
   - zsh with autosuggestions + syntax highlighting, and starship prompt.
   - Symlinks (edit-in-place: the real files live in this repo, home-manager only points `~/.config`/`~/.claude`/etc. at them):
     - `~/.config/wezterm` → `dotfiles/home/.config/wezterm`
     - `~/.config/nvim` → `dotfiles/home/.config/nvim`
     - `~/.config/herdr` → `dotfiles/home/.config/herdr`
     - `~/.claude/settings.json` → `dotfiles/home/.claude/settings.json`
     - `~/.claude/skills` → `dotfiles/home/.claude/skills`
     - `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md` → `dotfiles/home/AGENTS.md`
   - Environment: `$EDITOR=nvim`, `$JAVA_HOME` set to the Corretto 17 JDK, `python`/`python3` from Homebrew's `python@3.13` and `~/.local/bin` put first on `$PATH`.

### ⚠️ Warning: Homebrew cleanup

`configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`. Every rebuild **uninstalls (zaps) any Homebrew formula or cask not listed in `configuration.nix`**, including its data/config. This is intentional - it keeps the machine reproducible by forcing every Homebrew package to be declared here instead of installed ad-hoc. Do not run `rebuild.sh` on a machine with Homebrew packages you care about that aren't listed above, unless you add them to `configuration.nix` first.

## Prerequisites

- A Mac on Apple Silicon (`aarch64-darwin`). For Intel, change `nixpkgs.hostPlatform` in `configuration.nix` to `x86_64-darwin`.
- The [Determinate Nix installer](https://github.com/DeterminateSystems/nix-installer):
  ```sh
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```
  (`configuration.nix` sets `nix.enable = false` because Determinate already manages the Nix daemon - don't let nix-darwin manage it too.)

## Installation

1. Clone this repo:
   ```sh
   git clone <this-repo-url> ~/shekse-dev-setup
   cd ~/shekse-dev-setup
   ```
2. Run:
   ```sh
   ./dotfiles/bootstrap.sh
   ```
   This checks whether `dotfiles/flake.nix`'s hardcoded `user = "shekhar";` matches your macOS username; if not, it offers to rewrite it for you. It then hands off to `rebuild.sh`, which symlinks the repo to `~/.dotfiles` and runs `sudo nix run nix-darwin -- switch --flake ~/.dotfiles#mac`, building and activating the whole configuration. You'll be prompted for your password (for `sudo`) and Nix will download and build everything it needs - the first run can take a while.
3. Restart your terminal (or open a new WezTerm window) so the new shell config takes effect.

   On any later machine or re-clone, you can skip straight to `./dotfiles/rebuild.sh` once `flake.nix` already has the right username.

## Making changes

- Edit `dotfiles/configuration.nix` or `dotfiles/home.nix` to add/remove packages or change system settings.
- Edit files under `dotfiles/home/` directly - they're symlinked in place, so most changes take effect immediately without a rebuild (new files/symlinks still need one).
- Re-run `./dotfiles/rebuild.sh` any time to apply changes or pick up updates.
- See `dotfiles/AGENTS.md` for repo-specific conventions that coding agents (and you) should follow when editing this repo.

## Committing and pushing

Once your changes work as expected:

```sh
git add -A
git commit -m "<describe your change>"
git push
```
