{ config, ... }:
let
  # the shared feature set both Macs used via the old home/default.nix
  sharedHomeModules = with config.flake.modules.homeManager; [
    base
    email
    bash
    charm
    chromium
    codex
    eza
    fd
    fzf
    gh
    git
    golang
    helix
    nh
    nodejs
    nushell
    obsidian
    open-faas
    openai
    shell
    slack
    tmux
    tree
    vscode
    wezterm
    zsh
  ];
in
{
  configurations.darwin.biguy = {
    system = "aarch64-darwin";
    primaryUser = "WThorsen";

    homeModules = sharedHomeModules ++ [
      {
        programs.git.settings = {
          user = {
            name = "wesleythorsen";
            email = "wesley.thorsen@gmail.com";
          };
          credential.helper = "osxkeychain";
        };

        programs.ssh = {
          enable = true;
          matchBlocks."github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
            addKeysToAgent = "yes";
          };
        };
      }
    ];

    module = {
      imports = with config.flake.modules.darwin; [
        base
        macos-defaults
      ];

      networking.hostName = "KK9V4TQ0J0";
      nixpkgs.config.checkByDefault = false;
    };
  };
}
