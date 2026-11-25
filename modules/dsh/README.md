# DeepSeek Harness + DSH Super Agent on this machine

Enabled on `biguy` via `modules/hosts/biguy.nix` (`dsh`, alongside `ollama`, `pi`).
Apply with `darwin-rebuild switch --flake .#biguy`.

## What is Nix-managed vs not

| Piece | How | Pinned by Nix? |
|---|---|---|
| node 24, pnpm, git-lfs, gh, tmux, python3 | nixpkgs, on the wrappers' PATH | yes |
| `dsh` CLI (`@deepseek-ai/dsh`) | `dsh` wrapper installs the pinned npm version into `~/.local/share/dsh/npm` on first run | version only |
| dsh-superagent bundle | git checkout `~/src/dsh-superagent`, `pnpm build`, linked into dsh profile `superagent` | no (dev checkout) |
| deepseek-harness source | optional git checkout `~/src/deepseek-harness` (`--with-harness-source`) | no (dev checkout) |
| Ollama model route | `~/.config/dsh/ollama.patch.yml` overlay; copied into the `superagent` profile once | yes |
| `~/.dsh` (profiles, sessions, `.credentials.yaml`) | unmanaged; the Web UI rewrites profile configs itself | no |

Upstream has no darwin Nix packaging (the harness is a pnpm monorepo with
native addons; `codeberg.org/melvi/dsh-flakes` is Linux-only), so the CLI is
version-pinned the same way pi extensions are. Bump: edit `dshVersion` in
`default.nix`; the wrapper reinstalls on the next run.

## Commands

* `dsh web` — Web UI on http://127.0.0.1:3080. `dsh-web` alias adds `--no-open --patch ~/.config/dsh/ollama.patch.yml`
  so the local Ollama models appear in the picker (uses `qwen3-coder:30b` for tool calling).
* `dsh-superagent-bootstrap [--with-harness-source]` — clone + build the super agent, create the
  `superagent` profile (port 3082, state in `~/.dsh/state/superagent`), link the bundle.
* `gh-agent` — `gh` with `GH_CONFIG_DIR=~/.config/gh-agent`: the agent's own GitHub account.
* `dsh-superagent start|stop|restart|status` — the checkout's service script (tmux session `dsh-superagent`).
* `nix develop .#dsh` — dev shell for both repos.

## First run

1. `ollama-pull-defaults` if not done (modules/ollama).
2. `dsh-web` → Settings → Models: pick `ollama / qwen3-coder:30b`, or add a DeepSeek API key.
3. `dsh-superagent-bootstrap`
4. `gh-agent auth login` as a dedicated agent GitHub account with write access to the target repo
   (never your own account: everything the agent writes appears under that name).
5. `dsh-superagent start`, open http://127.0.0.1:3082 → Superagent → Sources (repo + agent CLI
   path `$(command -v gh-agent)`), Policy (allowed logins), Execution (prepare command).
   Or let a coding agent drive it: "Read SETUP.md in ~/src/dsh-superagent and set up dsh-superagent with me."

## Development

```bash
nix develop .#dsh
cd ~/src/dsh-superagent && pnpm check        # tsc + vitest + tsdown
dsh-superagent restart                        # reload the linked bundle
cd ~/src/deepseek-harness && pnpm install && pnpm run build && make dev-web
```

Harness source needs Node ≥ 24.9 and pnpm 11.28.5 (pnpm self-switches via `packageManager`).
Both projects are in developer preview: expect breaking changes; `engines.dsh` in the
superagent `package.json` must match `dshVersion`.
