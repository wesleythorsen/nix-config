{
  # Pi coding agent (https://pi.dev) from nixpkgs, plus its extension set.
  #
  # ~/.pi/agent/{settings.json,models.json} are out-of-store symlinks into this
  # repo (same idiom as modules/claude-code) because pi rewrites settings.json
  # itself (/model Ctrl+S, /settings, package installs). auth.json and sessions
  # stay unmanaged in ~/.pi/agent.
  #
  # Declarative-ness caveat: the `packages` list in agent/settings.json pins
  # npm versions, but pi downloads and installs them itself on first start
  # (into its own npm dir), so extensions are *version-pinned*, not Nix-built.
  flake.modules.homeManager.pi =
    { config, pkgs, ... }:
    let
      assetsRoot = "${config.homeConfig.nixConfigPath}/modules/pi";
      link = path: config.lib.file.mkOutOfStoreSymlink "${assetsRoot}/${path}";
    in
    {
      home.packages = with pkgs; [
        pi-coding-agent
      ];

      home.file = {
        ".pi/agent/settings.json".source = link "agent/settings.json";
        ".pi/agent/models.json".source = link "agent/models.json";
      };
    };
}
