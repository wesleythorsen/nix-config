{
  ...
}:

{
  programs.eza = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    extraOptions = [
      "-a"
      "-I '.git'"
      "--group-directories-first"
    ];
  };

  home.shellAliases = {
    l = "eza -la";
    lt = "eza_dynamic";
  };

  programs.zsh = {
    enable = true;
    initContent = builtins.readFile ./eza_dynamic.sh;
  };
}
