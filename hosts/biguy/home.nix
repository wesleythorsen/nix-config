{
  ...
}:

{
  home.username = "WThorsen";
  home.homeDirectory = "/Users/WThorsen";

  programs = {
    git.settings = {
      user = {
        name = "wesleythorsen";
        email = "wesley.thorsen@gmail.com";
      };
      credential.helper = "osxkeychain";
    };

    ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
          addKeysToAgent = "yes";
          # useKeychain = true;
        };
      };
    };

    # ts-cli.enable = false;
  };

  imports = [
    ../../home
  ];
}
