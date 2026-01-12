{
  ...
}:

{
  programs = {
    bash = {
      enable = true;

      bashrcExtra = ''
        case "$-" in *i*) ;; *) return ;; esac

        . ${./posh-git.zsh}
        __posh_prompt_prefix="\u@\h \W "
        __posh_prompt_suffix=" » "
        PROMPT_COMMAND='__posh_git_ps1 "$__posh_prompt_prefix" "$__posh_prompt_suffix"'

        bind '"\e[A": history-search-backward'
        bind '"\e[B": history-search-forward'
      '';
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
