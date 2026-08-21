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
}
