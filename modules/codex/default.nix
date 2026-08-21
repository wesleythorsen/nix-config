{
  flake.modules.homeManager.codex =
    {
      pkgs,
      ...
    }:
    {
      home = {
        packages = with pkgs; [
          codex
        ];
      };
    };
}
