{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.homeConfig = {
    nixConfigPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to your flake-based Nix config directory (e.g. ~/repos/github.com/wesleythorsen/nix-config)";
      default = "${config.home.homeDirectory}/repos/github.com/wesleythorsen/nix-config";
    };
  };

  imports = [
    ./accounts/email
    ./accounts/email/personal
    ./accounts/email/take2

    ./bash
    ./charm
    ./chromium
    ./codex
    # ./dotnet
    ./eza
    ./fabric-ai
    ./fd
    ./fzf
    ./gh
    ./git
    ./golang
    ./helix
    ./nodejs
    ./nushell
    ./nvim
    ./open-faas
    ./openai
    ./python3
    ./shell
    ./tmux
    ./tree
    ./vscode
    ./wezterm
    ./zsh
  ];

  config = {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = _: true;

    systemd.user.startServices = "sd-switch";

    fonts.fontconfig.enable = true;

    programs = {
      home-manager.enable = true;

      yazi = {
        enable = true;
      };
    };

    home = {
      stateVersion = "25.05";

      packages = with pkgs; [
        android-tools
        auth0-cli
        awscli2
        bat
        btop
        bws
        claude-code
        dbeaver-bin
        deno
        docker
        fastfetch
        ffmpeg_6-headless
        fontconfig
        getoptions
        gnupg
        jq
        jwt-cli
        kubernetes-helm
        litecli
        miller
        mysql80
        nerd-fonts.jetbrains-mono
        ngrok
        nix-tree
        nixd
        nixfmt-rfc-style
        nmap
        pipes-rs
        pnpm
        postman
        ripgrep
        rsclock
        sd
        watch
        wget
        yank
        zip
        zstd
      ];
    };

    golang.enable = true;

    gh = {
      enable = true;

      settings = {
        git_protocol = "https";
        editor = "code --wait";
        prompt = "enabled";
        prefer_editor_prompt = "disabled";
      };

      aliases = {
        prco = "pr checkout";
        prv = "pr view";
        prc = "pr create";
      };

      ghq = {
        enable = true;
        root = "${config.home.homeDirectory}/repos";
        useEnvVar = true;
      };

      gcd = {
        enable = true;
        addCodeHelper = true;
      };
    };
  };
}
