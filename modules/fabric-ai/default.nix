{
  ...
}:

{
  programs.fabric-ai = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    # "${FABRIC_ALIAS_PREFIX}${pattern_name}"
    enablePatternsAliases = true;

    # adds `yt` command that downloads youtube transcripts
    enableYtAlias = false;
  };

  # used by enablePatternsAliases above
  home.sessionVariables.FABRIC_ALIAS_PREFIX = "fab-";
}
