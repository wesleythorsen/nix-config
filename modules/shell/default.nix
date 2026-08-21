{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs) stdenv;

  activationCommand = if stdenv.isDarwin then "darwin-rebuild switch" else "home-manager switch";

  # Read all shell functions from the fns directory
  shellFunctions = builtins.listToAttrs (
    map (name: {
      name = name;
      value = builtins.readFile (./fns + "/${name}");
    }) (builtins.attrNames (builtins.readDir ./fns))
  );
in
{
  options.shell.functions = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Reusable shell functions available across modules";
  };

  config = {
    shell.functions = shellFunctions;

    home = {
      shell.enableShellIntegration = true;

      sessionVariables = {
        EDITOR = "hx";
        NIX_ACTIVE_CONFIG_DIR = "${config.home.homeDirectory}/nix";
      };

      sessionPath = [
        "${config.home.homeDirectory}/bin"
      ];

      shellAliases = {
        c = "clear";
        # l = "eza -la";
        # lt = "eza -laT -I=.git";
        v = "hx";
        na = "nix-activate ."; # see "bin/nix-activate" script below
      };

      file = {
        "nix" = {
          # symlink "~/nix" to physical repo location
          source = config.lib.file.mkOutOfStoreSymlink "${config.homeConfig.nixConfigPath}";
          recursive = true;
        };
        "bin/nix-activate" = {
          # usage:
          #   `nix-activate`                            - defaults to $NIX_ACTIVE_CONFIG_DIR if set, otherwise "~/nix"
          #   `nix-activate .`                          - uses current directory and auto-detects hostname/username
          #   `nix-activate ./nix/config/dir#host@user` - with path (hostname and username optional, default to current)
          executable = true;
          text = ''
            #!/usr/bin/env bash
            flakePath="''${1:-''${NIX_ACTIVE_CONFIG_DIR:-"${config.home.homeDirectory}/nix"}}"

            # If flakePath doesn't contain a fragment (#), auto-detect hostname and username
            if [[ "$flakePath" != *"#"* ]]; then
              hostname=$(hostname -s)
              username="${config.home.username}"
              
              # Check if username is configured and not empty
              if [[ -n "$username" && "$username" != "$(whoami)" ]]; then
                flakePath="$flakePath#$username@$hostname"
              else
                flakePath="$flakePath#$hostname"
              fi
            fi

            exec sudo ${activationCommand} --flake "$flakePath" --verbose
          '';
        };
      }
      // builtins.listToAttrs (
        map (name: {
          name = "bin/${name}";
          value = {
            source = "${./bin}/${name}";
            executable = true;
          };
        }) (builtins.attrNames (builtins.readDir ./bin))
      );
    };
  };
}
