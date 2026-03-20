{
  pkgs,
  ...
}:

{
  programs = {
    pyenv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    poetry = {
      enable = true;
      settings = {
        virtualenvs.create = true;
        virtualenvs."in-project" = true;
        repositories.ts_pypi_virtual.url = "https://tetrascience.jfrog.io/artifactory/api/pypi/ts-pypi-virtual/simple";
        # http-basic.ts_pypi_virtual."wthorsen@tetrascience.com" = "<reference token>";
      };
    };
  };

  home = {
    packages = with pkgs; [
      pipenv
      pipx
      black
    ];

    shellAliases = {
      python = "python3";
      pip = "pip3";
    };
  };
}
