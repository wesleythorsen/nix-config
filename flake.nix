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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
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
      ...
    }@inputs:
    let
      inherit (self) outputs;
      overlays = [
        nix-vscode-extensions.overlays.default

        (
          final: prev:
          let
            unstable = import nixpkgs-unstable {
              inherit (prev) system;
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
            vscode = unstable.vscode;
            podman = unstable.podman;
            podman-desktop = unstable.podman-desktop;
            # zoom-us = unstable.zoom-us;
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
