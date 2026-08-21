{
  config,
  lib,
  ...
}:

{
  programs.thunderbird = {
    enable = true;

    # add all email profiles to thunderbird
    profiles = lib.listToAttrs (
      lib.mapAttrsToList (name: acc: {
        name = name;
        value = {
          isDefault = acc.primary; # set primary account as thunderbird default
        };
      }) config.accounts.email.accounts
    );
  };
}
