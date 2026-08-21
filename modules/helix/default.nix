{
  flake.modules.homeManager.helix = {
    programs.helix = {
      enable = true;
      defaultEditor = true;

      # extraPackages = [
      #   pkgs.marksman
      # ];

      settings = {
        theme = "tokyonight";
      };
    };
  };
}
