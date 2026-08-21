{
  ...
}:

{
  home.shell.enableNushellIntegration = true;

  programs = {
    nushell = {
      enable = true;
      shellAliases = {
        c = "clear";
        l = "eza -la";
        lt = "eza_dynamic";
      };
    };

    intelli-shell.enableNushellIntegration = true;
    yazi.enableNushellIntegration = true;
  };
}
