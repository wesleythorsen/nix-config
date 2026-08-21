# nix-config

Personal Nix configuration for 2 Macs (nix-darwin + home-manager) and 2 NixOS
machines, structured with the [dendritic pattern](https://github.com/mightyiam/dendritic):
[flake-parts](https://github.com/hercules-ci/flake-parts) +
[import-tree](https://github.com/denful/import-tree).

## How this repo works

- **Every `.nix` file under `modules/` is a flake-parts module**, auto-imported
  by import-tree. There are no `imports = [ ./some/path.nix ]` lists between
  features and no `specialArgs` — files can be moved or renamed freely.
- **One file (or directory) per feature.** A feature publishes modules under
  `flake.modules.<class>.<name>`, where class is `homeManager`, `darwin`, or
  `nixos`. A single file may publish to several classes at once.
- **Hosts live in `modules/hosts/`** and are the only files that decide what
  runs where: each declares `configurations.{darwin,nixos}.<name>` with a
  `primaryUser`, a list of `homeModules` (home-manager features), and a system
  `module`. The builder in `modules/flake/configurations.nix` turns those into
  `darwinConfigurations` / `nixosConfigurations`, wiring home-manager,
  mac-app-util, overlays, and nixpkgs config once for all hosts.
- **Underscore paths are opt-outs**: any path containing `/_` (e.g.
  `modules/hosts/w530/_hardware-configuration.nix`, `modules/gh/_gcd/`) is
  ignored by import-tree — used for plain (non-flake-parts) modules that a
  feature imports relatively.
- Non-Nix assets (lua, css, scripts, …) live beside the feature that uses them.

## Add a tool

1. Create `modules/<tool>/default.nix`:

```nix
{
  flake.modules.homeManager.<tool> =
    { pkgs, ... }:
    {
      programs.<tool>.enable = true;
    };
}
```

2. Add `<tool>` to the feature list of any host in `modules/hosts/`.

## Where does X happen?

- A tool's config: `modules/<tool>/`
- What a host runs: `modules/hosts/<host>` (the one and only list)
- macOS defaults / shared darwin config: `modules/darwin/`
- Shared NixOS baseline: `modules/nixos/base.nix`
- Shared home-manager baseline (packages, fonts, stateVersion): `modules/home/base.nix`
- Overlays: `modules/flake/overlays.nix`
- Flake inputs: `flake.nix` (the only non-module file)

## Apply

```sh
darwin-rebuild switch --flake .#biguy          # work Mac (WThorsen)
darwin-rebuild switch --flake .#crackbookpro   # personal Mac (wes)
sudo nixos-rebuild switch --flake .#thinkpad   # NixOS (eval-tested only from macOS)
sudo nixos-rebuild switch --flake .#w530       # NixOS (eval-tested only from macOS)
```
