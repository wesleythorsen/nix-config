{
  lib,
  overlays,
  pkgs,
  self,
  ...
}:

{
  nixpkgs = {
    overlays = overlays; # unify pkgs at the system level too
    config.allowUnfree = true; # Allow unfree packages (for NVIDIA if you later want it)
  };

  imports = [
    ./hardware-configuration.nix
    # ./nvidia.nix
  ];

  # # Bootloader - Basic system settings
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # # old, delete if not needed:
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "thinkpad"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

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
  # sound.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
    publish.domain = true;
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

  # Misc services
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;

      UseDns = false;
      UsePAM = true;
    };
  };
  services.printing.enable = true;
  services.pcscd.enable = true;

  # Optional: get rid of those noisy dbus/acpid errors
  services.resolved.enable = true;
  services.acpid.enable = true;

  environment.etc."nix-config".source = self.outPath;

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
    zsh.enable = true;

    # Disable Hyprland for now to avoid crashes
    hyprland.enable = lib.mkForce false;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    tmux = {
      enable = true;
      keyMode = "vi";
      # TODO: update all tmux configs to use common config file
    };
  };

  system.stateVersion = "25.11"; # Did you read the comment?

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "wes"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    nixPath = lib.mkForce [ ]; # not needed for flake
  };
}
