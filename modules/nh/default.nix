{
  flake.modules.homeManager.nh =
    { config, ... }:
    {
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/repos/github.com/wesleythorsen/nix-config"; # sets NH_OS_FLAKE
        # clean.enable = true;
        # clean.extraArgs = "--keep-since 4d --keep 3";
      };

      # home = {
      #   packages = with pkgs; [
      #     pipenv
      #   ];

      #   shellAliases = {
      #     python = "python3";
      #   };
      # };
    };
}
