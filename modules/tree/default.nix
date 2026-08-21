{
  flake.modules.homeManager.tree =
    {
      pkgs,
      ...
    }:

    {
      home = {
        packages = with pkgs; [
          tree
        ];

        shellAliases.tree = "tree -a -I '.git'";
      };
    };
}
