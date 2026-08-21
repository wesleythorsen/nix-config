{
  config,
  ...
}:

{
  accounts.email.accounts.take2 = {
    address = "wesley@mytake2.org";
    realName = "Wesley Thorsen";
    userName = "wesley@mytake2.org";

    imap = {
      host = "imap.mytake2.org";
      port = 993;
      tls = {
        enable = true;
      };
    };
    smtp = {
      host = "smtp.mytake2.org";
      port = 587;
      tls = {
        enable = true;
        useStartTls = true;
      };
    };

    maildir = {
      path = "take2";
    };

    thunderbird = {
      enable = config.programs.thunderbird.enable;
    };
  };
}
