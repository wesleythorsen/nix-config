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
  configurations.darwin.crackbookpro = {
    system = "aarch64-darwin";
    primaryUser = "wes";

    homeModules = sharedHomeModules ++ [
      {
        programs.git.settings = {
          user = {
            name = "wesleythorsen";
            email = "wesley.thorsen@gmail.com";
          };
          credential.helper = "osxkeychain";
        };
      }
    ];

    module =
      { lib, pkgs, ... }:
      {
        imports = with config.flake.modules.darwin; [
          base
          macos-defaults
        ];

        networking.hostName = "crackbookpro";

        nix.nixPath = lib.mkForce [ ]; # not needed for flake
        nixpkgs.config.checkByDefault = false;

        services.tailscale = {
          enable = true;
        };

        environment.systemPackages = with pkgs; [
          curl
          exiftool
          fastfetch
          git
          jq
          unzip
          wget
        ];
      };
  };
}
