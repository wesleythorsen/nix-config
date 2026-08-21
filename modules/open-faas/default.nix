{
  flake.modules.homeManager.open-faas =
    {
      pkgs,
      ...
    }:

    {
      home = {
        packages = with pkgs; [
          faas-cli
        ];

        shellAliases = {
          faas = "faas-cli";
        };
      };
    };
}
