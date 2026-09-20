{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = "shekhar";
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      #KeyRepeat = 2;          # fast key repeat
      #InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "git"
      "gitleaks"
      "herdr"
      "opencode"
      "python@3.13"
      "node"
      "gh"
      "docker"  # Docker CLI (client only, not Docker Desktop)
      "docker-compose"  # `docker compose` plugin
      "docker-buildx"  # `docker buildx` plugin (multi-arch image builds)
      "colima"  # Docker engine (Linux VM running dockerd) for the CLI
      "container"  # Apple's native container CLI (github.com/apple/container)
    ];
    casks = [
      "wezterm"
      "claude-code"
      "corretto@17"
      "corretto@11"
    ];
  };

}
