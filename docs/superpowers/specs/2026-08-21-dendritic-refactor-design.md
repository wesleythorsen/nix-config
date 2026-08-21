# Dendritic refactor of nix-config — design spec

Date: 2026-08-21
Status: approved-in-chat, pending written review
Branch: `refactor/dendritic` (to be created)

## 1. Context and goals

The repo currently uses a hand-rolled flake: `flake.nix` builds two
`darwinConfigurations` (biguy, crackbookpro) inline, passes `overlays`/`inputs`
through `specialArgs`, and imports a monolithic `home/default.nix` that
hard-codes an `imports` list of ~30 per-tool home-manager modules. Two NixOS
hosts (`hosts/thinkpad`, `hosts/w530`) exist on disk but are not referenced by
the flake (dead code; w530 doesn't even evaluate — it reads lua files from a
path that no longer exists).

Goals, in priority order:

1. Easy to answer "where does X happen" — one file per feature, findable by name.
2. Easy to add/change a feature without touching central glue files.
3. 100% modern (Aug 2026) but boring: no fragile framework dependencies.
4. Resurrect thinkpad and w530 as real `nixosConfigurations`.
5. Behavior-preserving for the two Macs, proven by closure diff.

## 2. Decision and rationale

**Chosen architecture: pure dendritic pattern — flake-parts + import-tree +
flake-parts' `flakeModules.modules` extra.** User approved 2026-08-21 over two
alternatives (den framework; custom Cordis-inspired layer).

Research findings the decision rests on (all verified against live sources
2026-08-21; six-agent research workflow, ~130 fetches):

- The dendritic pattern ([mightyiam/dendritic](https://github.com/mightyiam/dendritic),
  603★) remains the mainstream modern layout for personal configs in Aug 2026.
  Snowfall-lib is unmaintained; std/hive are quiet; clan targets fleet
  management; nix-grove is weeks old.
- [import-tree](https://github.com/denful/import-tree) (322★, stable) and
  [flake-parts](https://github.com/hercules-ci/flake-parts) (1.4k★, healthy)
  are the only two dependencies added. `flake.modules.<class>.<name>` comes
  from flake-parts' opt-in extra (`inputs.flake-parts.flakeModules.modules`),
  the dominant community spelling.
- The `denful` org is real (Victor Borja / vic). [den](https://github.com/denful/den)
  (562★) is effectively "Cordis for Nix": aspects are context-driven plugins of
  `{host, user}`, with `provides.to-hosts/to-users` service injection. It was
  **not** chosen because it is pre-1.0 with monthly breaking changes and
  concept-heavy for a 4-host config. The dendritic layout chosen here is
  den-compatible (den has a "From Flake to Den" migration guide) if the aspect
  model becomes attractive later.
- dendrix is dormant (no commits since 2026-01); flake-file is optional magic
  (generates flake.nix from module-declared inputs) — both explicitly skipped.
- Cordis assessment (user asked): [cordiverse/cordis](https://github.com/cordiverse/cordis)
  is real and does power DeepSeek Harness (launched 2026-08-13). Its two halves
  map onto Nix as follows: the *spatial* half (service injection, contextual
  plugins, reactive activation) is already provided by the module system
  (option merging, `mkIf`, deferredModule) and, in richer form, by den; the
  *temporal* half (lifecycle, disposers, hot-unload rollback) is provided by
  pure evaluation + system generations — removing a module and rebuilding IS
  the clean unload. A bespoke "nix-cordis" layer would re-implement den with a
  user base of one and was rejected.

## 3. Target layout

```
flake.nix                      # inputs + mkFlake + import-tree only (~25 lines)
modules/
  flake/
    modules.nix                # imports inputs.flake-parts.flakeModules.modules
    configurations.nix         # host-builder options + darwin/nixos wiring (§4)
    overlays.nix               # flake.overlays.default (§6)
  hosts/
    biguy.nix                  # aarch64-darwin, user WThorsen
    crackbookpro/              # aarch64-darwin, user wes (+ etc/ assets)
    thinkpad/                  # x86_64-linux, user wes (+ hardware-configuration.nix)
    w530/                      # x86_64-linux, user wes (+ hardware-configuration.nix)
  darwin/
    base.nix                   # shared nix settings, zsh shell, users pattern
    macos-defaults.nix         # dock, NSGlobalDomain, keyboard, Stage Manager
  nixos/
    base.nix                   # shared NixOS baseline (locale, ssh, avahi, sudo…)
  home/
    base.nix                   # HM baseline: stateVersion, fonts, yazi, shared packages
  git.nix  gh/  vscode/  wezterm/  zsh/  tmux/ ...   # one file/dir per feature
```

Conventions:

- Every `.nix` file under `modules/` is a flake-parts module, auto-imported by
  import-tree. No `imports = [ ./relative/path ]` anywhere.
- A feature publishes to `flake.modules.homeManager.<name>` and/or
  `flake.modules.darwin.<name>` / `flake.modules.nixos.<name>`. One feature
  spanning several classes lives in ONE file.
- Non-nix assets (lua, css, sh, toml, mobileconfig) live beside their feature;
  import-tree only imports `.nix` files. Paths containing `/_` are ignored by
  import-tree (escape hatch for scratch files).
- No `specialArgs`. Feature files close over the flake-parts top-level args
  (`inputs`, `config`) when they need e.g. `inputs.self.outPath`.

## 4. Host plumbing (`modules/flake/configurations.nix`)

Declares options:

- `configurations.darwin.<name>`: `{ system, primaryUser, module (deferredModule) }`
- `configurations.nixos.<name>`: same shape.

And wires `flake.darwinConfigurations`/`flake.nixosConfigurations` from them:

- darwin builder injects, once for all hosts: `home-manager.darwinModules.home-manager`
  (with `useUserPackages = true`, `backupFileExtension = "backup"`,
  `sharedModules = [ mac-app-util.homeManagerModules.default ]`),
  `mac-app-util.darwinModules.default`, nixpkgs config (overlays + allowUnfree).
- nixos builder injects `home-manager.nixosModules.home-manager` analogously
  (thinkpad attaches user `wes`; w530 currently has no HM user — system only).
- A shared `primaryUser` option (declared once, consumed by darwin/nixos/HM
  modules) replaces today's duplicated `users.users.<name>` +
  `home-manager.users.<name>` + `home.username`/`homeDirectory` blocks.
  Host files set it in one line (`biguy: WThorsen`, others: `wes`).
- HM switches from `useGlobalPkgs = false` (separate nixpkgs instance fed
  overlays via `extraSpecialArgs`) to `useGlobalPkgs = true`. Same nixpkgs rev,
  same overlays, same allowUnfree ⇒ identical packages, minus a whole layer of
  plumbing. Parity is checked by the closure diff (§7); revert to
  per-HM nixpkgs if the diff disagrees.

A host file then looks like:

```nix
{ config, ... }:
{
  configurations.darwin.biguy = {
    system = "aarch64-darwin";
    primaryUser = "WThorsen";
    module = {
      imports = with config.flake.modules; [
        darwin.base darwin.macos-defaults ...
      ];
      networking.hostName = "KK9V4TQ0J0";
      # host-only quirks stay here (e.g. crackbookpro: services.tailscale)
    };
  };
}
```

Home feature selection: the host file closes over the flake-parts top-level
`config`, so inside its darwin/nixos module it can write
`home-manager.users.<user>.imports = with config.flake.modules.homeManager;
[ base git vscode ... ];` — the host file is the single place listing both its
system features and its home features. Per-host git identity/ssh blocks
(currently in `hosts/*/home.nix`) move into the host file's module.

## 5. Feature migration inventory

Every `home/<tool>` becomes `modules/<tool>` publishing
`flake.modules.homeManager.<tool>`, assets carried alongside. Custom options
(`gh.gcd`, `gh.ghq`, `golang.enable`, `homeConfig.nixConfigPath`) carry over
unchanged.

- **Imported today (migrate + keep referenced by both Macs):** accounts/email
  (+personal, take2), bash, charm, chromium, codex, eza, fd, fzf, gh (+gcd,
  ghq), git, golang, helix, nh, nodejs, nushell, obsidian, open-faas, openai,
  shell (bin/ + fns/), slack, tmux, tree, vscode, wezterm, zsh.
- **Commented-out today (migrate as unreferenced features — inert until a host
  lists them, no comment noise):** dotnet, fabric-ai, nvim, python, python3,
  tetrascience.
- **Orphaned today (migrate as unreferenced):** podman, starship, thunderbird,
  hyprland, waybar (last two are Linux-only; thinkpad may re-adopt later).
- **`home/default.nix` splits into:** `modules/home/base.nix` (stateVersion,
  fonts.fontconfig, yazi, home-manager.enable, shared `home.packages` list,
  gh/golang settings, `homeConfig.nixConfigPath` option) — nixpkgs plumbing in
  it disappears (handled by builder, §4).
- **`hosts/*/darwin.nix` split into:** `modules/darwin/base.nix` (nix settings,
  trusted-users via primaryUser, zsh, users pattern, nixos-rebuild pkg) +
  `modules/darwin/macos-defaults.nix` (dock, NSGlobalDomain, keyboard,
  Stage Manager — currently identical on both Macs); host files keep only
  deltas (crackbookpro: tailscale, extra systemPackages, `checkByDefault`;
  biguy: hostname).
- crackbookpro's `etc/` assets (posh-git.zsh, tcc-pppc.mobileconfig) move with
  the host dir; verify during implementation whether anything references them
  or they're manually-installed artifacts (document whichever is true).

## 6. Overlays and inputs

`modules/flake/overlays.nix` publishes `flake.overlays.default` containing:

- vscode ripgrep postPatch fix (kept until nixpkgs 0c209480 reaches unstable),
- `perlPackages.DBDCSV` and `kubernetes-helm` `doCheck = false`,
- plus external overlays applied in the builder: `nix-vscode-extensions.overlays.default`,
  `envd.overlays.default`.

**Dropped as dead weight:** the overlay re-importing `nixpkgs-unstable` for
brave/dbeaver/docker/postman/slack/thunderbird/podman/podman-desktop — base
nixpkgs already IS nixpkgs-unstable, so it resolves to identical packages.

Inputs: rename `nixpkgs-unstable` → `nixpkgs` (it is the only nixpkgs);
add `flake-parts`, `import-tree`; keep home-manager, nix-darwin, mac-app-util,
nix-vscode-extensions, envd. `mac-app-util`'s missing `follows` stays as-is
(intentional in current config, preserves its own pins).

## 7. NixOS resurrection details

- thinkpad: port configuration.nix + hardware-configuration.nix + nvidia.nix
  (kept commented/unreferenced as today) into `modules/hosts/thinkpad/`;
  shared candidates (locale/console, openssh hardening, avahi, pipewire...)
  extracted to `modules/nixos/base.nix` only where thinkpad and w530 agree
  today — no behavior invention. HM user `wes` wired with the same feature set
  as before (`../../home` ≙ the Mac feature list minus darwin-only bits) plus
  its extra packages (vlc, wl-clipboard, wofi) and git-credential-manager.
- w530: system-only (no HM today — preserved). **Must-fix:** neovim runtime
  paths reference `home/shell/nvim/…`; the real files are `home/nvim/…` →
  point at the migrated `modules/nvim/` assets. `specialisation.dev-shell`
  carried over verbatim.
- `environment.etc."nix-config".source = self.outPath` re-expressed by closing
  over `inputs.self` in the feature file (no specialArgs).
- Verification is evaluation-only (`nix eval …toplevel.drvPath`); no Linux
  builds on this Mac.

## 8. Verification plan

1. **Baseline (before any changes, on `main`):**
   `nix build .#darwinConfigurations.{biguy,crackbookpro}.system --out-link baseline-<host>`.
2. After refactor: same builds → `nix store diff-closures baseline-<host> ./result-<host>`.
   Success bar: empty or explainably-trivial diff (the §6 overlay drop and §4
   `useGlobalPkgs` change must produce no package-set change; any diff traced
   and justified or reverted).
3. `nix flake check` passes.
4. `nix eval .#nixosConfigurations.{thinkpad,w530}.config.system.build.toplevel.drvPath`
   succeeds.
5. `nixfmt` clean on all files.
6. Nothing is `switch`ed; applying configs stays a manual user action.

## 9. Out of scope

- Adopting den/dendrix/flake-file (revisit if den hits 1.0).
- devShells, treefmt, CI, secrets management (sops/agenix) — none exist today,
  none added.
- Behavior changes of any kind beyond §6's no-op overlay removal; feature
  redesigns (e.g. unifying tmux configs, the TODOs in w530) are noted but not
  done.
- `gemini-convo-temp.md` is untracked scratch; left alone (delete at will).

## 10. Docs

- README section (or new README.md) explaining the pattern in ~20 lines:
  "every file under modules/ is a flake-parts module; to add a tool, add one
  file; to see what a host runs, read its file in modules/hosts/".
- AGENTS.md updated to the new layout, build commands unchanged in spirit
  (`darwin-rebuild switch --flake .#crackbookpro` still works; add
  `.#biguy`, `.#thinkpad`, `.#w530`).

## 11. Risks

- **Eval-time/debuggability:** dendritic adds module-system indirection; stack
  traces get longer (community-documented). Mitigated by small repo size and
  the README explainer.
- **`useGlobalPkgs` flip:** could surface subtle HM package differences —
  caught by §8 closure diff; fallback documented in §4.
- **w530/thinkpad hardware:** cannot be build- or boot-tested from this
  machine; eval-only guarantee, flagged in AGENTS.md.
- **import-tree ignores `/_` paths:** don't name feature dirs with a leading
  underscore.
