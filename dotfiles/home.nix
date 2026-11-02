{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
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
    $DRY_RUN_CMD /opt/homebrew/bin/npm install -g vercel
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
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.JAVA_HOME = "/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home";
  # Homebrew's python@3.13 is keg-only; its `python`/`python3` symlinks live
  # here rather than /opt/homebrew/bin, so put this first in PATH to shadow
  # the macOS system python3 at /usr/bin.
  home.sessionPath = [
    "/opt/homebrew/opt/python@3.13/libexec/bin"
    "$HOME/.local/bin"
  ];


  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
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
