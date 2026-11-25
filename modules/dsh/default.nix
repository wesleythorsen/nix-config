{
  # DeepSeek Harness (dsh) + the DSH Super Agent prototype.
  #
  # What is Nix-managed vs not (see README.md):
  #   * tool chain (node 24, pnpm, git-lfs, gh, tmux, python3) -- nixpkgs
  #   * `dsh` CLI -- version-pinned npm install into ~/.local/share/dsh
  #     (same idiom as pi extensions: pinned, not Nix-built; upstream is a
  #     pnpm monorepo with native addons and no darwin Nix packaging yet)
  #   * dsh-superagent -- a git checkout under ~/src (it is a dev project,
  #     not a release), built with pnpm and linked into a dedicated dsh
  #     profile by `dsh-superagent-bootstrap`
  #   * Ollama model route -- a Cordis patch overlay (`dsh web --patch`),
  #     so the UI-owned profiles/web/cordis.patch.yml stays untouched
  flake.modules.homeManager.dsh =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # Public rc that satisfies dsh-superagent's engines.dsh (^0.2.1-alpha.2).
      dshVersion = "0.2.1-rc.5";
      superagentRepo = "https://github.com/deepseek-ai/dsh-superagent-prototype.git";
      harnessRepo = "https://github.com/deepseek-ai/deepseek-harness.git";

      home = config.home.homeDirectory;
      npmPrefix = "${home}/.local/share/dsh/npm";
      srcRoot = "${home}/src";

      node = pkgs.nodejs_24;

      # Lazy, version-pinned install: nothing touches the network at
      # darwin-rebuild time; the first `dsh` run (or a version bump here)
      # installs @deepseek-ai/dsh@${dshVersion} into ${npmPrefix}.
      dsh = pkgs.writeShellScriptBin "dsh" ''
        set -eu
        prefix="${npmPrefix}"
        want="${dshVersion}"
        have=$(cat "$prefix/.dsh-version" 2>/dev/null || true)
        if [ "$have" != "$want" ] || [ ! -x "$prefix/bin/dsh" ]; then
          echo "dsh: installing @deepseek-ai/dsh@$want into $prefix" >&2
          mkdir -p "$prefix"
          ${node}/bin/npm install -g --prefix "$prefix" "@deepseek-ai/dsh@$want" >&2
          printf '%s\n' "$want" > "$prefix/.dsh-version"
        fi
        # Ollama ignores the key but dsh's provider schema wants a credential ref.
        export OLLAMA_API_KEY="''${OLLAMA_API_KEY:-ollama}"
        export PATH="${
          lib.makeBinPath [
            node
            pkgs.pnpm
            pkgs.git
            pkgs.git-lfs
            pkgs.gh
            pkgs.ripgrep
            pkgs.python3
          ]
        }:$PATH"
        exec "$prefix/bin/dsh" "$@"
      '';

      # GitHub CLI bound to a separate config dir: the agent's own account
      # (docs/006-deployment.md). `gh-agent auth login` once by hand.
      ghAgent = pkgs.writeShellScriptBin "gh-agent" ''
        GH_CONFIG_DIR="$HOME/.config/gh-agent" exec ${pkgs.gh}/bin/gh "$@"
      '';

      # Thin wrapper around the checkout's service script (python3 + tmux on PATH).
      superagentCtl = pkgs.writeShellScriptBin "dsh-superagent" ''
        set -eu
        script="${srcRoot}/dsh-superagent/scripts/dsh-superagent"
        [ -x "$script" ] || { echo "dsh-superagent: $script missing; run dsh-superagent-bootstrap" >&2; exit 1; }
        export PATH="${
          lib.makeBinPath [
            pkgs.python3
            pkgs.tmux
            dsh
            node
            pkgs.pnpm
            pkgs.git
            pkgs.gh
          ]
        }:$PATH"
        exec "$script" "$@"
      '';

      superagentPatch = pkgs.replaceVars ./_superagent/profile.cordis.patch.yml {
        stateDir = "${home}/.dsh/state/superagent";
      };

      bootstrap = pkgs.writeShellScriptBin "dsh-superagent-bootstrap" ''
                set -eu
                export PATH="${
                  lib.makeBinPath [
                    dsh
                    node
                    pkgs.pnpm
                    pkgs.git
                    pkgs.git-lfs
                    pkgs.gh
                    pkgs.python3
                    pkgs.tmux
                  ]
                }:$PATH"
                DSH_HOME="''${DSH_HOME:-$HOME/.dsh}"
                src="${srcRoot}"
                mkdir -p "$src"

                echo "==> dsh $(dsh --version)"

                if [ ! -d "$src/dsh-superagent/.git" ]; then
                  echo "==> clone dsh-superagent -> $src/dsh-superagent"
                  git clone "${superagentRepo}" "$src/dsh-superagent"
                fi
                if [ "''${1:-}" = "--with-harness-source" ] && [ ! -d "$src/deepseek-harness/.git" ]; then
                  echo "==> clone deepseek-harness (large) -> $src/deepseek-harness"
                  git clone "${harnessRepo}" "$src/deepseek-harness"
                fi

                echo "==> pnpm install && pnpm build (dsh-superagent)"
                ( cd "$src/dsh-superagent" && pnpm install && pnpm build )

                profile="$DSH_HOME/profiles/superagent"
                if [ ! -d "$profile" ]; then
                  echo "==> create dsh profile 'superagent' from the web template"
                  dsh superagent --from-default-profile web --dump-config > /dev/null
                  echo "==> write $profile/cordis.patch.yml (stateDir, port 3082, ollama route)"
                  install -m 0644 "${superagentPatch}" "$profile/cordis.patch.yml"
                  echo "==> link the bundle into the profile"
                  ( cd "$src/dsh-superagent" && dsh plugin --profile superagent add "link:$PWD" )
                else
                  echo "==> profile 'superagent' exists; leaving cordis.patch.yml alone (see Upgrade in docs/006-deployment.md)"
                fi
                mkdir -p "$DSH_HOME/state/superagent"

                cat <<MSG

        Done. Next, by hand:
          1. gh-agent auth login            # sign in as the agent's own GitHub account
          2. dsh-superagent start           # tmux session dsh-superagent, panel http://127.0.0.1:3082
          3. open the panel -> Superagent -> Sources/Policy/Execution (or follow SETUP.md with a coding agent)
        MSG
      '';
    in
    {
      home.packages = [
        dsh
        ghAgent
        superagentCtl
        bootstrap
        node
        pkgs.pnpm
        pkgs.git-lfs
      ];

      # `dsh web --patch ~/.config/dsh/ollama.patch.yml` adds the local Ollama
      # route without touching the UI-owned profile config.
      home.file.".config/dsh/ollama.patch.yml".source = ./ollama.patch.yml;

      home.shellAliases = {
        dsh-web = "dsh web --no-open --patch ~/.config/dsh/ollama.patch.yml";
      };
    };

  # Dev shell for hacking on the harness monorepo and the superagent bundle:
  #   nix develop .#dsh
  perSystem =
    { pkgs, ... }:
    {
      devShells.dsh = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_24
          pnpm
          typescript
          gnumake
          git
          git-lfs
          gh
          tmux
          python3
          jq
        ];
        shellHook = ''
          echo "dsh dev shell: node $(node --version), pnpm $(pnpm --version)"
          echo "  superagent: ~/src/dsh-superagent   (pnpm check = typecheck + vitest + tsdown build)"
          echo "  harness:    ~/src/deepseek-harness (pnpm install && pnpm run build; make help)"
        '';
      };
    };
}
