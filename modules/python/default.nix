{
  flake.modules.homeManager.python =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      pyenvRoot = "${config.home.homeDirectory}/.local/share/pyenv";
      pyenvShimLock = "${pyenvRoot}/shims/.pyenv-shim";
      pyenvBin = "${pkgs.pyenv}/bin/pyenv";
    in
    {
      programs = {
        pyenv = {
          enable = true;
          enableBashIntegration = false;
          enableZshIntegration = false;
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
        activation.clearPyenvShimLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # pyenv uses .pyenv-shim as a lock during rehash. If a prior rehash was
          # interrupted, the stale lock blocks every new shell for 60 seconds.
          rm -f ${lib.escapeShellArg pyenvShimLock}
        '';

        sessionVariables = {
          PYENV_ROOT = pyenvRoot;
        };

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

      programs.bash.bashrcExtra = lib.mkAfter ''
        eval "$(${pyenvBin} init - --no-rehash bash)"
      '';

      programs.zsh.initContent = lib.mkAfter ''
        eval "$(${pyenvBin} init - --no-rehash zsh)"
      '';
    };
}
