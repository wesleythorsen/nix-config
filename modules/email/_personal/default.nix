{
  config,
  ...
}:

{
  accounts.email.accounts.personal = {
    primary = true;
    address = "wesley.thorsen@gmail.com";
    realName = "Wesley Thorsen";
    userName = "wesley.thorsen@gmail.com";
    flavor = "gmail.com";
    passwordCommand = "pass show mail/gmail"; # if you want oauth2, configure these or use a passwordCommand

    maildir.path = "personal"; # relative to maildirBasePath

    thunderbird = {
      enable = config.programs.thunderbird.enable;
      # profiles       = [ "default" ]; # optional: only for profile "default"
    };
  };
}
