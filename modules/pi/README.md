# Pi agents on this machine

Enabled on `biguy` via `modules/hosts/biguy.nix` (`ollama`, `pi`, `pi-gui`).
Apply with `darwin-rebuild switch --flake .#biguy`.

## What is Nix-managed vs not

| Piece | How | Pinned by Nix? |
|---|---|---|
| `pi` CLI | nixpkgs `pi-coding-agent` (1.3.0) | yes |
| pi-gui.app | upstream signed `.dmg`, hashed (`modules/pi-gui/_package.nix`) | yes |
| Ollama server | nixpkgs `ollama`, launchd agent on `127.0.0.1:11434` | yes |
| Pi extensions | version-pinned in `agent/settings.json`; **pi downloads them from npm on first start** | version only |
| Ollama model weights | `ollama-pull-defaults` (writes `~/.ollama`) | no |
| Pi Durable SDK | `nix develop .#pi-durable` + starter in `modules/pi-durable/_starter` (lockfile pinned) | lockfile |

`~/.pi/agent/settings.json` and `models.json` are out-of-store symlinks into
this repo, so edits pi makes (e.g. `/model` then Ctrl+S) show up as a git diff
here. `auth.json` and sessions stay in `~/.pi/agent`, unmanaged.

## First run

1. `ollama-pull-defaults` (Qwen3 Coder 30b, DeepSeek R1 14b, DeepSeek Coder V2 16b, Qwen2.5 Coder 14b; ~46 GB).
2. `pi` — first start installs the pinned extensions, then `/model` and pick an `ollama/...` model.
   Use `ollama/qwen3-coder:30b` for agent work: it is the only pulled model whose
   Ollama template returns structured tool calls (verified). Ollama rejects tool
   requests for the DeepSeek models (`does not support tools`) and Qwen2.5-coder
   emits the call as plain text, so use those with `pi --no-tools` for chat.
   Known limit: with all five extensions loaded, qwen3-coder gets ~20 tools and
   starts writing tool calls as text. `pi --no-extensions` works end-to-end
   (verified: bash tool ran `echo pong`). For extension-heavy sessions (kanban,
   pi-agents) use a hosted model via `/login`, or trim `packages` in settings.json.
3. For hosted providers: `/login` inside pi (credentials go to `~/.pi/agent/auth.json`).

## Extensions installed

* `pi-kanban` — browser board on `127.0.0.1:3460`. In pi: `/kanban open`. Standalone: `npx pi-kanban`.
* `pi-subagents` — `subagent` tool; sessions show under the parent in kanban.
* `@juicesharp/rpiv-todo` — todo overlay, rendered as kanban columns.
* `pi-agents` — durable background agents on Pi Durable: `agent_spawn/send/wait/status/stop`, `/agents`, `/messages`.
  Built-in tools only (no MCP). Tool names do not collide with `pi-subagents`; both are enabled.
* `@ricoyudog/pi-debug-dashboard` — `/dashboard start`, then http://localhost:9848 (Gantt tool timeline).

## pi-gui

Launch "pi-gui" from Spotlight (linked into `~/Applications/Home Manager Apps`).
Settings → Providers → custom endpoint `http://127.0.0.1:11434/v1` for Ollama,
or it reuses the CLI's `auth.json`. Upstream only ships Apple Silicon macOS, so
the module is aarch64-darwin only. Bump: edit `version` + `hash` in
`modules/pi-gui/_package.nix` (`nix store prefetch-file <dmg url>`).

## Pi Durable starter

```bash
nix develop .#pi-durable
cp -r modules/pi-durable/_starter ~/src/my-agent && cd ~/src/my-agent
npm ci
npm start -- "summarize this repo"   # uses ollama/deepseek-r1:14b, state in ./agent.sqlite
```

Re-running resumes unfinished work via `harness.resume()`. Side-effecting
tools are not exactly-once after a crash; design them idempotent.

## Not done yet

* Event-triggered durable agent (Slack / email / Jira / GitHub review events) — next step, builds on the starter above.
* `pi-app`, PI Dashboard: not packaged (Electron source builds); pi-gui chosen instead.
