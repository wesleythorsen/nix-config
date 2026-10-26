{
  # Local LLM server (DeepSeek, Qwen, ...). Bound to localhost only.
  # home-manager runs it as a launchd agent on macOS / systemd user unit on Linux.
  # Model weights live in ~/.ollama and are pulled on demand: `ollama-pull-defaults`.
  flake.modules.homeManager.ollama =
    { pkgs, ... }:
    let
      defaultModels = [
        "deepseek-r1:14b"
        "deepseek-coder-v2:16b"
        "qwen2.5-coder:14b"
      ];
      pull = pkgs.writeShellScriptBin "ollama-pull-defaults" ''
        set -eu
        for m in ${toString defaultModels}; do
          echo "==> ollama pull $m"
          ${pkgs.ollama}/bin/ollama pull "$m"
        done
      '';
    in
    {
      services.ollama = {
        enable = true;
        host = "127.0.0.1";
        port = 11434;
      };

      home.packages = [ pull ];
    };
}
