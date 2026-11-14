{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  # Activation scripts run with a minimal PATH; npm and rea are `#!/usr/bin/env node` scripts, so node must be findable.
  brewPath = "PATH=/opt/homebrew/bin:$PATH";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "25.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    bun       # JS runtime/package manager (homebrew's bottle install fails under nix-homebrew's patched brew)
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  # Vercel CLI has no Homebrew formula, so install it via npm (node comes from the brews list).
  home.activation.installVercelCli = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD env ${brewPath} /opt/homebrew/bin/npm install -g vercel
  '';
  # Paperclip (local project tracker) has no Homebrew formula either. Its data lives in ~/.paperclip
  # and survives reinstalls; run `paperclipai run` to start it at http://127.0.0.1:3100.
  home.activation.installPaperclip = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD env ${brewPath} /opt/homebrew/bin/npm install -g paperclipai
  '';
  # agent-desktop (drives native desktop apps via the OS accessibility tree) has no Homebrew formula.
  # Its skills are embedded in the binary; see skills/agent-desktop for the bootstrap skill.
  home.activation.installAgentDesktop = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD env ${brewPath} /opt/homebrew/bin/npm install -g agent-desktop
  '';
  # REA (reverse engineering MCP + skill) has no Homebrew formula. After installing the CLI, `rea setup`
  # idempotently registers the MCP server in ~/.claude.json and ~/.codex/config.toml and refreshes the
  # bundled reverse-engineer-anything skill (gitignored under skills/). Never fails the rebuild.
  home.activation.installRea = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD env ${brewPath} /opt/homebrew/bin/npm install -g rea-agents
    $DRY_RUN_CMD env ${brewPath} /opt/homebrew/bin/rea setup --client claude_code --client codex --yes \
      || echo "warning: rea setup failed"
  '';
  # REA's Android analysis needs the jadx-headless-mcp JAR, which REA does not install itself.
  # Pinned to the version and sha256 from REA's src/android/JadxRelease.ts; re-downloaded only if
  # missing or corrupt. Selected via REA_JADX_MCP_JAR below. Never fails the rebuild.
  home.activation.installReaJadx = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    jar="$HOME/.local/share/rea/android/jadx-headless-mcp-0.7.1-all.jar"
    sha=6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75
    if ! echo "$sha  $jar" | /usr/bin/shasum -a 256 -c - >/dev/null 2>&1; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$jar")"
      $DRY_RUN_CMD /usr/bin/curl -fsSL -o "$jar" https://github.com/1013503897/jadx-headless-mcp/releases/download/v0.7.1/jadx-headless-mcp-0.7.1-all.jar \
        && echo "$sha  $jar" | /usr/bin/shasum -a 256 -c - >/dev/null \
        || { echo "warning: could not install the jadx-headless-mcp JAR for REA"; rm -f "$jar"; }
    fi
  '';
  # shekse-finance-skill (private repo): clone/update it, then link it into the tracked skills dir
  # so ~/.claude/skills/shekse-finance-skill/{SKILL.md,bin/sfin} resolve. Never fails the rebuild
  # (e.g. no ssh access yet on a fresh machine); the link is gitignored.
  home.activation.installShekseFinanceSkill = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    dir="$HOME/.local/share/shekse-finance-skill"
    git=/opt/homebrew/bin/git
    if [ -d "$dir/.git" ]; then
      $DRY_RUN_CMD $git -C "$dir" pull --ff-only || echo "warning: could not update shekse-finance-skill"
    else
      $DRY_RUN_CMD mkdir -p "$(dirname "$dir")"
      $DRY_RUN_CMD $git clone git@github.com:seemantshekhar43/shekse-finance-skill.git "$dir" \
        || echo "warning: could not clone shekse-finance-skill (needs ssh access to the private repo)"
    fi
    if [ -d "$dir" ]; then
      $DRY_RUN_CMD ln -sfn "$dir" "${dotfiles}/home/.claude/skills/shekse-finance-skill"
    fi
  '';
  # Rust (cargo, rustc, clippy, rustfmt) comes from rustup, which is not packaged the way the repo needs
  # (FigLock pins toolchains per repo). Installed once with the official installer; --no-modify-path because
  # PATH is declared below in home.sessionPath, and ~/.zshenv is a read-only Nix symlink anyway. Later
  # rebuilds leave the toolchain alone (`rustup update` is the upgrade path). The cargo tools below are
  # installed only if missing. Never fails the rebuild.
  home.activation.installRust = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    cargo_bin="$HOME/.cargo/bin"
    if [ ! -x "$cargo_bin/rustup" ]; then
      $DRY_RUN_CMD /bin/sh -c "/usr/bin/curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | /bin/sh -s -- -y --no-modify-path" \
        || echo "warning: could not install rustup"
    fi
    for tool in cargo-deny cargo-fuzz; do
      if [ -x "$cargo_bin/cargo" ] && [ ! -x "$cargo_bin/$tool" ]; then
        $DRY_RUN_CMD "$cargo_bin/cargo" install --locked "$tool" || echo "warning: could not install $tool"
      fi
    done
  '';
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.PAPERCLIP_TELEMETRY_DISABLED = "1";
  home.sessionVariables.REA_JADX_MCP_JAR = "${config.home.homeDirectory}/.local/share/rea/android/jadx-headless-mcp-0.7.1-all.jar";
  home.sessionVariables.JAVA_HOME = "/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home";
  # Homebrew's python@3.13 is keg-only; its `python`/`python3` symlinks live
  # here rather than /opt/homebrew/bin, so put this first in PATH to shadow
  # the macOS system python3 at /usr/bin.
  home.sessionPath = [
    "/opt/homebrew/opt/python@3.13/libexec/bin"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"  # rustup's cargo, rustc and the cargo-installed tools
  ];


  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      eval "$(/opt/homebrew/bin/mise activate zsh)"
      bindkey '^f' autosuggest-accept
      bindkey "^[[F" end-of-line
      bindkey "^[[H" beginning-of-line
      bindkey "^[[4~" delete-char
    '';
    shellAliases = {
 #     ".." = "cd ..";
 #     add = "git add .";
 #     push = "git push";
 #     pull = "git pull";
 #     m = "git switch main";
 #    cc = "claude --dangerously-skip-permissions";
 #     co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
 home.file.".config/herdr".source =
   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
 home.file.".claude/settings.json".source =
   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
 home.file.".claude/skills".source =
   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills";

 home.file.".claude/CLAUDE.md".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
 home.file.".codex/AGENTS.md".source =
   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
 home.file.".config/opencode/AGENTS.md".source =
   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
