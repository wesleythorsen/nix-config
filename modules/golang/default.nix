{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.golang;
in
{
  options.golang = {
    enable = lib.mkEnableOption "Enable golang";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      go
      clang
      libtool
      makeWrapper
    ];
  };
}
