{
  flake.modules.homeManager.golang =
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

      config = lib.mkMerge [
        # selecting this feature enables it (overridable per host)
        { golang.enable = lib.mkDefault true; }

        (lib.mkIf cfg.enable {
          home.packages = with pkgs; [
            go
            clang
            libtool
            makeWrapper
          ];
        })
      ];
    };
}
