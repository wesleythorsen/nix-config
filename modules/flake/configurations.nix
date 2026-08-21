{
  config,
  inputs,
  lib,
  ...
}:
let
  hostSubmodule = {
    options = {
      system = lib.mkOption { type = lib.types.str; };
      primaryUser = lib.mkOption { type = lib.types.str; };
      module = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
      };
      homeModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [ ];
        description = "home-manager modules for the primary user; empty list = no home-manager";
      };
    };
  };

  overlaysList = [
    inputs.nix-vscode-extensions.overlays.default
    inputs.envd.overlays.default
    config.flake.overlays.default
  ];

  primaryUserModule = user: {
    options.primaryUser = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "The main user account on this machine.";
    };
    config.primaryUser = user;
  };

  commonModules = host: [
    host.module
    (primaryUserModule host.primaryUser)
    {
      nixpkgs = {
        hostPlatform = host.system;
        overlays = overlaysList;
        config.allowUnfree = true;
        config.allowUnfreePredicate = _: true;
      };
    }
  ];

  homeManagerModule = host: homeDirPrefix: hmSharedModules: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      sharedModules = hmSharedModules;
      users.${host.primaryUser} = {
        imports = host.homeModules;
        home.username = host.primaryUser;
        home.homeDirectory = "${homeDirPrefix}/${host.primaryUser}";
      };
    };
  };
in
{
  options.configurations = {
    darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule hostSubmodule);
      default = { };
    };
    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule hostSubmodule);
      default = { };
    };
  };

  config.flake = {
    darwinConfigurations = lib.mapAttrs (
      _name: host:
      inputs.nix-darwin.lib.darwinSystem {
        modules =
          commonModules host
          ++ [
            inputs.mac-app-util.darwinModules.default
            inputs.home-manager.darwinModules.home-manager
          ]
          ++ lib.optional (host.homeModules != [ ]) (
            homeManagerModule host "/Users" [ inputs.mac-app-util.homeManagerModules.default ]
          );
      }
    ) config.configurations.darwin;

    nixosConfigurations = lib.mapAttrs (
      _name: host:
      inputs.nixpkgs.lib.nixosSystem {
        modules =
          commonModules host
          ++ lib.optionals (host.homeModules != [ ]) [
            inputs.home-manager.nixosModules.home-manager
            (homeManagerModule host "/home" [ ])
          ];
      }
    ) config.configurations.nixos;
  };
}
