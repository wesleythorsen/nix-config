# Repository Guidelines

## Project Structure & Module Organization (dendritic pattern)

- `flake.nix` declares inputs only; outputs are
  `flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules)`.
- Every `.nix` file under `modules/` is an auto-imported flake-parts module.
  Paths containing `/_` are ignored by import-tree (used for plain modules a
  feature imports relatively, e.g. hardware configs, `modules/gh/_gcd/`).
- One feature per file/dir: `modules/<tool>/default.nix` publishes
  `flake.modules.homeManager.<tool>` (and/or `.darwin.<tool>` /
  `.nixos.<tool>`), with assets alongside.
- `modules/hosts/<host>` declares `configurations.{darwin,nixos}.<host>`
  (`system`, `primaryUser`, `homeModules` feature list, system `module`).
  The builder in `modules/flake/configurations.nix` wires home-manager
  (useGlobalPkgs), mac-app-util, overlays, and allowUnfree once for all hosts.
  No `specialArgs` anywhere — close over flake-parts top-level `inputs`/`config`.
- Shared baselines: `modules/darwin/base.nix` + `macos-defaults.nix`,
  `modules/nixos/base.nix`, `modules/home/base.nix` (packages, stateVersion).
  Overlays: `modules/flake/overlays.nix`.

## Build, Test, and Development Commands

- `nix flake check` — sanity check that all outputs evaluate.
- `nix build .#darwinConfigurations.<biguy|crackbookpro>.system` — build a Mac
  closure without applying.
- `darwin-rebuild switch --flake .#<biguy|crackbookpro>` — apply macOS config
  (home-manager rides along via the nix-darwin module).
- `sudo nixos-rebuild switch --flake .#<thinkpad|w530>` — apply NixOS hosts.
  NOTE: these are only evaluation-tested from macOS
  (`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`);
  prefer `nixos-rebuild test`/`--dry-run` on the machine before switching.

## Coding Style & Naming Conventions

- Nix files use 2-space indentation and `nixfmt` (nixfmt-rfc-style, on PATH).
- Feature dirs are lowercase; host names match `modules/hosts/<host>` outputs.
- New home-manager feature: create `modules/<tool>/default.nix` publishing
  `flake.modules.homeManager.<tool>`, then add `<tool>` to a host's
  `homeModules` list. Never add cross-feature relative imports.
- Scripts in `modules/shell/bin` use short, kebab-case names; prefer POSIX sh.

## Testing Guidelines

- Run `nix flake check` before pushing; add `--show-trace` when troubleshooting.
- For behavior-preserving refactors, compare closures:
  `nix build .#darwinConfigurations.<host>.system --out-link new` then
  `nix store diff-closures <old> ./new`.

## Commit & Pull Request Guidelines

- Follow conventional commits (`feat:`, `fix:`, `refactor:`) as seen in
  history; include the host or module touched when relevant.
- In PRs, summarize scope, note which hosts were rebuilt, and paste key command
  outputs (`nix flake check`, builds/diffs). Mention any `flake.lock` updates
  or new unfree dependencies.
- Avoid committing secrets (SSH/GPG keys, tokens). Leverage platform
  keychains/agent settings already in `modules/git` and host configs.
