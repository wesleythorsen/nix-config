{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    home = {
      packages = with pkgs; [
        glow
        gum
        mods
      ];

      # symlink charm settings files so changes get saved in nix-config
      activation.linkCharmModsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        #!/usr/bin/env bash
        set -euo pipefail
        MODS_DIR="${config.home.homeDirectory}/Library/Application Support/mods"
        NIX_CONFIG_DIR="${config.homeConfig.nixConfigPath}/home/shell/charm"
        mkdir -p "$MODS_DIR"
        ln -sf "$NIX_CONFIG_DIR/mods.yml" "$MODS_DIR/mods.yml"
      '';
    };
  };
}
