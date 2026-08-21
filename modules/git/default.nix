{
  flake.modules.homeManager.git = {
    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          side-by-side = true;
          line-numbers = true;
        };
      };

      git = {
        enable = true;
        ignores = [
          ".DS_Store"
        ];
        settings = {
          alias = {
            co = "checkout";
            loga = "log --oneline --graph --all"; # [l]og [o]ne-line [g]raph [a]ll
            logl = "log --oneline --graph --all"; # [l]og [o]ne-line [g]raph a[l]l
            logp = "log --oneline --graph --all --abbrev-commit --date=relative --pretty=format:'%C(auto)%h%Creset -%C(auto)%d%Creset %s %C(bold blue)<%an>%Creset %C(bold white)(%cr)'";
            pf = "push --force-with-lease"; # [p]ush [f]orce-with-lease
            aacane = "!git add -A && git commit --amend --no-edit"; # [a]dd [a]ll [c]ommit [a]mend [n]o-[e]dit
            bcu = "!f() { git branch -D \"$1\" && git branch -D --remote \"origin/$1\" && git push origin --delete \"$1\"; }; f"; # [b]ranch [c]lean [u]p
            fo = "!f() { git fetch origin --prune \${1:+\"$1:$1\"}; }; f";
          };
          user.signingkey = "FAE484F021AE49E5"; # FIXME: Use variable for Git GPG signing key
          commit.gpgsign = true;
          push = {
            autoSetupRemote = true;
          };
          core = {
            editor = "hx";
            repositoryformatversion = 0;
            filemode = true;
            bare = false;
            logallrefupdates = true;
            ignorecase = false;
            precomposeunicode = true;
          };
          credential = {
            "https://github.com/".useHttpPath = true;
          };
          merge = {
            conflictstyle = "zdiff3";
          };
        };
      };
    };
  };
}
