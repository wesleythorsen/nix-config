{
  pkgs,
  ...
}:

# let
#   denoCompletions =
#     pkgs.runCommand "deno-completions"
#       {
#         buildInputs = [ pkgs.deno ];
#       }
#       ''
#         deno completions zsh > $out
#       '';
#   jwtCliCompletions =
#     pkgs.runCommand "jwt-cli-completions"
#       {
#         buildInputs = [ pkgs.jwt-cli ];
#       }
#       ''
#         mkdir -p $out/share/zsh/site-functions
#         jwt completion zsh > $out/share/zsh/site-functions/_jwt
#       '';
# in
{
  programs = {
    zsh = {
      enable = true;

      initExtra = ''
        setopt prompt_subst
        . ${./posh-git.zsh}
        PROMPT='%n@%m %1~$(git_prompt_info) » '

        autoload -U up-line-or-beginning-search
        autoload -U down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "^[[A" up-line-or-beginning-search
        bindkey "^[[B" down-line-or-beginning-search

        show_fastfetch () {
          # Only for interactive shells
          case "$-" in
            *i*) : ;;      # interactive
            *)   return ;; # non-interactive (e.g., ssh with a command)
          esac

          # Require a real terminal and skip "dumb"
          [ -t 1 ] || return
          [ "''${TERM:-}" = "dumb" ] && return

          if command -v fastfetch >/dev/null 2>&1; then
            fastfetch
          fi
        }

        show_fastfetch
      '';

      enableCompletion = true;

      autosuggestion = {
        enable = true;
        # highlight = "fg=#ff00ff,bg=cyan,bold,underline";
      };

      syntaxHighlighting = {
        enable = true;
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.file = {
    ".oh-my-zsh-custom/git-posh.zsh" = {
      source = pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/wesleythorsen/6d251331f8b0f6ede7ff32d38d7d4ba8/raw/3eea77779577c64e3a251754cae50e96a3e2841d/git-posh.zsh";
        sha256 = "sha256-77wsJUCO+55iwqqsfjBdX3htnscL9zz5YZClVwjVbxs=";
      };
    };

    ".oh-my-zsh-custom/plugins/git-open" = {
      source = pkgs.fetchFromGitHub {
        owner = "paulirish";
        repo = "git-open";
        rev = "2a66fcd7e3583bc934843bad4af430ac2ffcd859";
        sha256 = "sha256-t5ZmFHjIlmQc5F/4EkC6E9vvFVTF9xN2COgDXYR7V9o=";
      };
    };

    # ".oh-my-zsh-custom/plugins/deno/_deno" = {
    #   source = denoCompletions;
    # };
  };
}
