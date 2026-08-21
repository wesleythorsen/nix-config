{
  flake.modules.homeManager.email = {
    imports = [
      ./_personal
      ./_take2
    ];

    accounts = {
      email = {
        maildirBasePath = "maildir";
        # certificatesFile       = "/etc/ssl/certs/ca-certificates.crt";
      };
    };
  };
}
