{ config, inputs, ... }:
let
  # the shared feature set (same as the Macs; the old home.nix imported ../../home)
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
  configurations.nixos.thinkpad = {
    system = "x86_64-linux";
    primaryUser = "wes";

    homeModules = sharedHomeModules ++ [
      (
        { pkgs, ... }:
        {
          programs.git.settings = {
            user = {
              name = "wesleythorsen";
              email = "wesley.thorsen@gmail.com";
            };
            credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
          };

          home.packages = with pkgs; [
            # googleearth-pro
            vlc
            wl-clipboard
            wofi
          ];
        }
      )
    ];

    module =
      { lib, pkgs, ... }:
      {
        imports = [
          ./_hardware-configuration.nix
          # ./_nvidia.nix
          config.flake.modules.nixos.base
        ];

        networking.hostName = "thinkpad";

        services.displayManager = {
          sddm.enable = true;

          # Boot into XFCE for stability
          defaultSession = "xfce";
        };

        services.xserver = {
          enable = true;
          # Use Intel iGPU for now; comment out if you want NVIDIA PRIME later
          videoDrivers = [ "modesetting" ];

          displayManager = {
            # Explicitly disable LightDM
            lightdm.enable = false;
          };

          desktopManager.xfce.enable = true;
        };

        # Enable sound
        services.pulseaudio.enable = false;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };

        # User accounts
        users.users.wes = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
          ];
          shell = pkgs.zsh;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2Mwvc/ia3Gtu0RQ6WmkoPVI1E+EKAd1akze0SJqA8c wes@crackbookpro" # id_thinkpad
          ];
        };

        security.sudo.extraRules = [
          {
            users = [ "wes" ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        services.printing.enable = true;
        services.pcscd.enable = true;

        environment.etc."nix-config".source = inputs.self.outPath;

        # Packages
        environment.systemPackages = with pkgs; [
          exiftool
          nftables
          # vim
          # git
          wget
          traceroute
          # firefox
          xfce.thunar
          xfce.mousepad
        ];

        programs = {
          # Disable Hyprland for now to avoid crashes
          hyprland.enable = lib.mkForce false;

          tmux = {
            enable = true;
            keyMode = "vi";
            # TODO: update all tmux configs to use common config file
          };
        };

        nix = {
          settings = {
            substituters = [ "https://hyprland.cachix.org" ];
            trusted-public-keys = [
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            ];
          };
          nixPath = lib.mkForce [ ]; # not needed for flake
        };
      };
  };
}
