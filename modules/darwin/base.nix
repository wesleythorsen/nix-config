{
  flake.modules.darwin.base =
    { config, pkgs, ... }:
    {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          config.primaryUser
        ];
      };

      system.stateVersion = 5;
      system.primaryUser = config.primaryUser;

      users.users.${config.primaryUser} = {
        home = "/Users/${config.primaryUser}";
        shell = pkgs.zsh;
      };

      environment.shells = [ pkgs.zsh ];
      environment.systemPackages = with pkgs; [
        coreutils
        nixos-rebuild # for building NixOS configs
      ];
    };
}
