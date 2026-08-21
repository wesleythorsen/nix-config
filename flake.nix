{
  description = "nix config";

  inputs = {
    # nixpkgs = {
    #   url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    # };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    envd = {
      url = "github:wesleythorsen/envd/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs-unstable,
      home-manager,
      nix-vscode-extensions,
      nix-darwin,
      mac-app-util,
      envd,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      overlays = [
        nix-vscode-extensions.overlays.default

        envd.overlays.default

        (
          final: prev:
          let
            unstable = import nixpkgs-unstable {
              system = prev.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          in
          {
            brave = unstable.brave;
            dbeaver-bin = unstable.dbeaver-bin;
            docker = unstable.docker;
            postman = unstable.postman;
            slack = unstable.slack;
            thunderbird = unstable.thunderbird;
            # TODO: remove override once nixpkgs-unstable includes the fix for
            # the darwin ripgrep path in VS Code >= 1.129 (nixpkgs commit 0c209480)
            vscode = unstable.vscode.overrideAttrs (old: {
              postPatch = builtins.replaceStrings [
                "Contents/Resources/app/node_modules/@vscode/ripgrep-universal"
              ] [
                "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal"
              ] old.postPatch;
            });
            podman = unstable.podman;
            podman-desktop = unstable.podman-desktop;
            # zoom-us = unstable.zoom-us;
            perlPackages = prev.perlPackages // {
              DBDCSV = prev.perlPackages.DBDCSV.overrideAttrs (_: {
                doCheck = false;
              });
            };
            kubernetes-helm = prev.kubernetes-helm.overrideAttrs (_: {
              doCheck = false;
            });
          }
        )
      ];
    in
    {
      darwinConfigurations = {
        crackbookpro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          pkgs = import nixpkgs-unstable {
            system = "aarch64-darwin";
            overlays = overlays;
            config.allowUnfree = true;
          };

          specialArgs = { inherit inputs outputs overlays; };

          modules = [
            ./hosts/crackbookpro/darwin.nix

            mac-app-util.darwinModules.default

            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.wes = import ./hosts/crackbookpro/home.nix;
              home-manager.extraSpecialArgs = { inherit overlays inputs; };
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
            }
          ];
        };

        biguy = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          pkgs = import nixpkgs-unstable {
            system = "aarch64-darwin";
            overlays = overlays;
            config.allowUnfree = true;
          };

          specialArgs = { inherit inputs outputs overlays; };

          modules = [
            ./hosts/biguy/darwin.nix

            mac-app-util.darwinModules.default

            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.WThorsen = import ./hosts/biguy/home.nix;
              home-manager.extraSpecialArgs = { inherit overlays inputs; };
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
            }
          ];
        };
      };
    };
}
