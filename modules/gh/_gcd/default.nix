{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.gcd;
  fzfOpts = lib.concatStringsSep " " cfg.fzfOptions;
in
{
  options.gcd = {
    enable = lib.mkEnableOption "ghq + fzf picker (gcd + Ctrl+g)";
    key = lib.mkOption {
      type = lib.types.str;
      default = "^g"; # Ctrl+g
      description = "Zsh keybinding for the gcd picker";
    };
    fzfOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--height=50%"
        "--reverse"
        "--border"
      ];
      description = "Extra flags passed to fzf";
    };
    addCodeHelper = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Also add gcode (pick repo → open in VS Code).";
    };
  };

  config = lib.mkIf cfg.enable {
    # We only add fzf here; ghq should come from the ghq module.
    home.packages = [ pkgs.fzf ];

    programs.zsh = {
      enable = true;
      initContent = ''
        # gcd = "ghq cd": fuzzy-pick a repo, then cd
        gcd() {
          local dir
          dir="$(ghq list -p | fzf ${fzfOpts} --prompt='repos> ')" || return
          builtin cd -- "$dir"
        }

        ${lib.optionalString cfg.addCodeHelper ''
          # gcode: pick a repo and open in VS Code (requires 'code' on PATH)
          gcode() {
            local dir
            dir="$(ghq list -p | fzf ${fzfOpts} --prompt='code> ')" || return
            command -v code >/dev/null 2>&1 && code "$dir" || {
              echo "VS Code ('code') not found on PATH" >&2
              return 127
            }
          }
        ''}

        # ZLE widget bound to ${cfg.key}
        __gcd_widget() {
          local dir
          dir="$(ghq list -p | fzf ${fzfOpts} --prompt='repos> ')" || return
          builtin cd -- "$dir"
          zle reset-prompt
        }
        zle -N __gcd_widget
        bindkey '${cfg.key}' __gcd_widget
      '';
    };
  };
}
