{
  pkgs,
  ...
}:

let
  pythonWithPip = pkgs.python3.withPackages (
    ps: with ps; [
      pip
      setuptools
      wheel
      uv
    ]
  );
in
{
  home = {
    packages = [
      pythonWithPip
    ];

    shellAliases = {
      python = "python3";
      pip = "pip3";
    };
  };
}
