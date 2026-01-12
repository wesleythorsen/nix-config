{
  pkgs,
  overlays,
  ...
}:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "WThorsen"
      ];
    };
  };
  nixpkgs = {
    config.checkByDefault = false;
    overlays = overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  networking.hostName = "KK9V4TQ0J0";

  system = {
    stateVersion = 5;

    primaryUser = "WThorsen";

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true; # Show file extensions
        AppleShowAllFiles = true; # Show hidden folders in finder
        InitialKeyRepeat = 15; # default 25
        KeyRepeat = 2;
      };

      dock = {
        autohide = true; # Auto-hide the Dock
        orientation = "right";
        mru-spaces = false; # Don’t “Automatically rearrange Spaces based on most recent use”
      };

      WindowManager = {
        GloballyEnabled = true; # Enable "Stage Manager"
      };
    };

    keyboard = {
      enableKeyMapping = true; # Turn on nix-darwin’s key-mapping support
    };
  };

  users.users = {
    WThorsen = {
      home = "/Users/WThorsen";
      shell = pkgs.zsh;
    };
  };

  environment = {
    shells = [ pkgs.zsh ];

    systemPackages = with pkgs; [
      coreutils
      nixos-rebuild # for building NixOS configs
    ];
  };
}
