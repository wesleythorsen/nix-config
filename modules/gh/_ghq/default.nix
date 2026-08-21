{
  lib,
  config,
  pkgs,
  ...
}:

# get all repos for org
# gh repo list bussin-io -L 500 --json nameWithOwner --jq '.[].nameWithOwner' | xargs -n1 ghq get

let
  cfg = config.ghq;
in
{
  options.ghq = {
    enable = lib.mkEnableOption "Configure ghq (root, package)";
    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/repos";
      description = "ghq root: real checkouts live under <root>/<host>/<org>/<repo>";
    };
    useEnvVar = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set GHQ_ROOT env var (overrides git config if set). Prefer false.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ghq ];

    # Prefer Git config for ghq.root
    programs.git = {
      enable = true;
      settings.ghq.root = cfg.root;
    };

    # Optional: set GHQ_ROOT (note it overrides ghq.root if present)
    home.sessionVariables = lib.mkIf cfg.useEnvVar {
      GHQ_ROOT = cfg.root;
    };

    # Make sure the directory exists (safe if it already does)
    home.activation.ensureGhqRoot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${lib.escapeShellArg cfg.root}
    '';
  };
}
