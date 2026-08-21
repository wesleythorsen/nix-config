# Dendritic Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure this repo into the dendritic pattern: every `.nix` file under `modules/` is an auto-imported flake-parts module; one file per feature; hosts are one-file feature selections.

**Architecture:** flake-parts + import-tree + flake-parts' `flakeModules.modules` extra (`flake.modules.<class>.<name>`). A `configurations.{darwin,nixos}.<host>` option layer builds `darwinConfigurations`/`nixosConfigurations`, injecting home-manager/mac-app-util/nixpkgs plumbing once. No `specialArgs` anywhere.

**Tech Stack:** Nix flakes, flake-parts, import-tree (github:denful/import-tree), nix-darwin, home-manager, nixfmt-rfc-style.

**Spec:** `docs/superpowers/specs/2026-08-21-dendritic-refactor-design.md`

## Global Constraints

- Branch: `refactor/dendritic`. Never run `darwin-rebuild switch` / `nixos-rebuild switch`.
- Behavior-preserving for biguy + crackbookpro: `nix store diff-closures` vs baseline must be empty or item-by-item justified (spec §8).
- Only two new inputs: `flake-parts`, `import-tree`. Input `nixpkgs-unstable` is renamed `nixpkgs`.
- No `specialArgs` / `extraSpecialArgs`. Feature files close over flake-parts top-level args (`inputs`, `config`).
- import-tree imports every `*.nix` under `modules/` EXCEPT paths containing `/_`. Any `.nix` file that is NOT a flake-parts module (hardware configs, intra-feature submodules) MUST live at an underscore path (e.g. `_hardware-configuration.nix`, `_gcd/`).
- All migrated module BODIES are copied verbatim unless a step says otherwise. Format with `nixfmt` (on PATH).
- Nix "test" = evaluation/build. Each task ends with its stated verify command passing (except Task 4, which intentionally leaves the tree non-evaluating until Task 5).

---

### Task 1: Baseline closures (before touching any .nix file)

**Files:** none (artifacts in scratchpad dir).

- [ ] **Step 1:** Run (SCRATCH=the session scratchpad dir):
```bash
nix build .#darwinConfigurations.biguy.system        --out-link "$SCRATCH/baseline-biguy"
nix build .#darwinConfigurations.crackbookpro.system --out-link "$SCRATCH/baseline-crackbookpro"
```
- [ ] **Step 2:** Verify both symlinks exist: `ls -l "$SCRATCH"/baseline-*`. Record the two store paths in `$SCRATCH/baseline-paths.txt`.

### Task 2: New flake.nix + flake-parts scaffolding

**Files:**
- Modify: `flake.nix` (full replacement below)
- Create: `modules/flake/modules.nix`, `modules/flake/systems.nix`

**Interfaces — Produces:** flake-parts top level with `flake.modules.<class>.<name>` available to every later module; top-level args `inputs`, `config` available in all `modules/**/*.nix`.

- [ ] **Step 1:** Replace `flake.nix` entirely with:
```nix
{
  description = "nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NOTE: intentionally no `follows` (preserves its own pins), as today.
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    envd = {
      url = "github:wesleythorsen/envd/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
```
- [ ] **Step 2:** Create `modules/flake/modules.nix`:
```nix
{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];
}
```
- [ ] **Step 3:** Create `modules/flake/systems.nix`:
```nix
{
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];
}
```
- [ ] **Step 4:** `nix flake lock` (regenerates lock: rename + new inputs).
- [ ] **Step 5:** Verify: `nix flake show` succeeds (outputs empty-ish; old `home/` and `hosts/` are now unreferenced, which is fine).
- [ ] **Step 6:** Commit: `git add -A && git commit -m "refactor: dendritic scaffolding (flake-parts + import-tree)"`

### Task 3: Host-builder and overlays plumbing

**Files:**
- Create: `modules/flake/configurations.nix`, `modules/flake/overlays.nix`

**Interfaces — Produces:**
- Options `configurations.darwin.<name>` and `configurations.nixos.<name>` with fields `system : str`, `primaryUser : str`, `module : deferredModule`, `homeModules : listOf deferredModule` (empty ⇒ no home-manager user wired).
- Inside built systems: option `primaryUser : str` (read-only value of the host's primaryUser).
- `flake.overlays.default`.

- [ ] **Step 1:** Create `modules/flake/configurations.nix`:
```nix
{
  config,
  inputs,
  lib,
  ...
}:
let
  hostSubmodule = {
    options = {
      system = lib.mkOption { type = lib.types.str; };
      primaryUser = lib.mkOption { type = lib.types.str; };
      module = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
      };
      homeModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [ ];
        description = "home-manager modules for the primary user; empty list = no home-manager";
      };
    };
  };

  overlaysList = [
    inputs.nix-vscode-extensions.overlays.default
    inputs.envd.overlays.default
    config.flake.overlays.default
  ];

  primaryUserModule = user: {
    options.primaryUser = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "The main user account on this machine.";
    };
    config.primaryUser = user;
  };

  commonModules = host: [
    host.module
    (primaryUserModule host.primaryUser)
    {
      nixpkgs = {
        hostPlatform = host.system;
        overlays = overlaysList;
        config.allowUnfree = true;
        config.allowUnfreePredicate = _: true;
      };
    }
  ];

  homeManagerModule = host: homeDirPrefix: hmSharedModules: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      sharedModules = hmSharedModules;
      users.${host.primaryUser} = {
        imports = host.homeModules;
        home.username = host.primaryUser;
        home.homeDirectory = "${homeDirPrefix}/${host.primaryUser}";
      };
    };
  };
in
{
  options.configurations = {
    darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule hostSubmodule);
      default = { };
    };
    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule hostSubmodule);
      default = { };
    };
  };

  config.flake = {
    darwinConfigurations = lib.mapAttrs (
      _name: host:
      inputs.nix-darwin.lib.darwinSystem {
        modules =
          commonModules host
          ++ [
            inputs.mac-app-util.darwinModules.default
            inputs.home-manager.darwinModules.home-manager
          ]
          ++ lib.optional (host.homeModules != [ ]) (
            homeManagerModule host "/Users" [ inputs.mac-app-util.homeManagerModules.default ]
          );
      }
    ) config.configurations.darwin;

    nixosConfigurations = lib.mapAttrs (
      _name: host:
      inputs.nixpkgs.lib.nixosSystem {
        modules =
          commonModules host
          ++ lib.optionals (host.homeModules != [ ]) [
            inputs.home-manager.nixosModules.home-manager
            (homeManagerModule host "/home" [ ])
          ];
      }
    ) config.configurations.nixos;
  };
}
```
- [ ] **Step 2:** Create `modules/flake/overlays.nix` (content lifted verbatim from old `flake.nix` lines 51–87, MINUS the unstable re-import block per spec §6):
```nix
{
  flake.overlays.default = _final: prev: {
    # TODO: remove override once nixpkgs-unstable includes the fix for
    # the darwin ripgrep path in VS Code >= 1.129 (nixpkgs commit 0c209480)
    vscode = prev.vscode.overrideAttrs (old: {
      postPatch =
        builtins.replaceStrings
          [ "Contents/Resources/app/node_modules/@vscode/ripgrep-universal" ]
          [ "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal" ]
          old.postPatch;
    });
    perlPackages = prev.perlPackages // {
      DBDCSV = prev.perlPackages.DBDCSV.overrideAttrs (_: {
        doCheck = false;
      });
    };
    kubernetes-helm = prev.kubernetes-helm.overrideAttrs (_: {
      doCheck = false;
    });
  };
}
```
- [ ] **Step 3:** Verify: `nix flake show` succeeds and lists `overlays.default` (no configurations yet — empty attrsets).
- [ ] **Step 4:** Commit: `git commit -am "refactor: add configurations builder and overlays module"`

### Task 4: Move feature files into modules/ (git mv only, no edits)

**Files:** every `home/*` path moves to `modules/*`. NOTE: after this commit the flake does NOT evaluate until Task 5 completes — intentional, isolated to this branch.

- [ ] **Step 1:** From repo root run exactly:
```bash
git mv home/accounts/email modules/email
git mv modules/email/personal modules/email/_personal
git mv modules/email/take2 modules/email/_take2
rmdir home/accounts
for t in bash charm chromium codex dotnet eza fabric-ai fd fzf gh git golang helix hyprland nh nodejs nushell nvim obsidian open-faas openai podman python python3 shell slack starship tetrascience thunderbird tmux tree vscode waybar wezterm zsh; do
  git mv "home/$t" "modules/$t"
done
git mv modules/gh/gcd modules/gh/_gcd
git mv modules/gh/ghq modules/gh/_ghq
mkdir -p modules/home
git mv home/default.nix modules/home/base.nix
rmdir home
```
- [ ] **Step 2:** Guard — every remaining non-underscore `.nix` under `modules/` must be a to-be-wrapped feature file. Run and eyeball:
```bash
find modules -name '*.nix' | grep -v '/_' | sort
```
Expected: `modules/flake/*.nix`, `modules/home/base.nix`, one `default.nix` per feature dir, and nothing else.
- [ ] **Step 3:** Commit: `git commit -am "refactor: move home/* features to modules/ (no content changes)"`

### Task 5: Rewrite every feature file to dendritic form

**Files:** Modify every `modules/<feature>/default.nix` + `modules/email/default.nix` + `modules/home/base.nix`.

**Transformation contract (applies to every feature file unless a special case below overrides):**

Old file shape:
```nix
{ pkgs, config, ... }:            # (whatever args it takes)
{ <BODY> }
```
New shape — wrap verbatim as a `flake.modules.homeManager.<feature>` value:
```nix
{
  flake.modules.homeManager.<feature> =
    { pkgs, config, ... }:        # same args as before; drop the arg list entirely if BODY uses none
    {
      <BODY unchanged>
    };
}
```
Rules:
1. `<feature>` = directory name (`modules/eza` → `eza`; `modules/email` → `email`).
2. Relative asset references (`./config.toml`, `./bin`, `./vimium.css`, …) keep working — assets moved with the dir. Do not touch them.
3. Files defining custom options (gh, golang, shell, …): options stay inside the wrapped HM module, unchanged.
4. Any `imports = [ ./sub ]` of intra-feature parts must point at the underscore names (`./gcd` → `./_gcd`, `./personal` → `./_personal`, `./take2` → `./_take2`). Underscore-path files themselves are NOT wrapped (they stay plain HM modules).
5. Delete any `nixpkgs.*` lines inside HM module bodies (builder owns nixpkgs config now). Known instance: `modules/home/base.nix`.
6. Run `nixfmt <file>` after editing.
7. Parse-check: `nix-instantiate --parse <file> >/dev/null`.

**Special case A — `modules/home/base.nix`** (from old `home/default.nix`): wrap as `flake.modules.homeManager.base`; DELETE the `nixpkgs` block, the `imports` list (hosts now select features), and the `golang.enable`/`gh = {…}` blocks (they move into their features, below). Keep: `homeConfig.nixConfigPath` option, `systemd.user.startServices`, `fonts.fontconfig.enable`, `programs.home-manager.enable`, `programs.yazi.enable`, `home.stateVersion = "25.11"`, the full `home.packages` list.

**Special case B — `modules/golang/default.nix`**: after wrapping, add to the module body:
```nix
config.golang.enable = lib.mkDefault true;
```
(merge into the existing `config = lib.mkIf cfg.enable {…}` structure by converting to `config = lib.mkMerge [ { golang.enable = lib.mkDefault true; } (lib.mkIf cfg.enable {…original…}) ];`). Selecting the feature = enabling it; the option remains overridable.

**Special case C — `modules/gh/default.nix`**: same mkMerge treatment, adding (values verbatim from old `home/default.nix` lines 124–150):
```nix
{
  gh = {
    enable = lib.mkDefault true;
    settings = {
      git_protocol = "https";
      editor = "code --wait";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
    };
    aliases = {
      prco = "pr checkout";
      prv = "pr view";
      prc = "pr create";
    };
    ghq = {
      enable = true;
      root = "${config.home.homeDirectory}/repos";
      useEnvVar = true;
    };
    gcd = {
      enable = true;
      addCodeHelper = true;
    };
  };
}
```

**Special case D — `modules/email/default.nix`**: wrapped module's body gains `imports = [ ./_personal ./_take2 ];` (old `home/default.nix` imported all three paths; folding them keeps one `email` feature).

- [ ] **Step 1:** Apply the contract to ALL feature files. Parallelizable: fan out in batches (each worker gets the contract text + its file list; workers use Write/Edit only, never git).
- [ ] **Step 2:** Verify every file parses: `find modules -name '*.nix' -exec nix-instantiate --parse {} \; >/dev/null` (exit 0).
- [ ] **Step 3:** Verify flake evaluates again: `nix flake show`.
- [ ] **Step 4:** Commit: `git commit -am "refactor: dendritic-wrap all home-manager features"`

### Task 6: Darwin shared modules + darwin hosts

**Files:**
- Create: `modules/darwin/base.nix`, `modules/darwin/macos-defaults.nix`, `modules/hosts/biguy.nix`, `modules/hosts/crackbookpro/default.nix`
- Move: `git mv hosts/crackbookpro/etc modules/hosts/crackbookpro/etc`
- Delete: `hosts/biguy/`, remaining `hosts/crackbookpro/` files

**Interfaces — Consumes:** `configurations.darwin.*` (Task 3), `flake.modules.homeManager.*` (Task 5), `config.primaryUser` (Task 3).

- [ ] **Step 1:** Create `modules/darwin/base.nix` (shared lines of the two old `darwin.nix` files):
```nix
{
  flake.modules.darwin.base =
    { config, pkgs, ... }:
    {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          config.primaryUser
        ];
      };

      system.stateVersion = 5;
      system.primaryUser = config.primaryUser;

      users.users.${config.primaryUser} = {
        home = "/Users/${config.primaryUser}";
        shell = pkgs.zsh;
      };

      environment.shells = [ pkgs.zsh ];
      environment.systemPackages = with pkgs; [
        coreutils
        nixos-rebuild # for building NixOS configs
      ];
    };
}
```
- [ ] **Step 2:** Create `modules/darwin/macos-defaults.nix` (identical on both Macs today):
```nix
{
  flake.modules.darwin.macos-defaults = {
    system = {
      defaults = {
        NSGlobalDomain = {
          AppleShowAllExtensions = true; # Show file extensions
          AppleShowAllFiles = true; # Show hidden folders in finder
          InitialKeyRepeat = 15; # default 25
          KeyRepeat = 2;
        };

        dock = {
          autohide = true; # Auto-hide the Dock
          orientation = "right";
          mru-spaces = false; # Don’t “Automatically rearrange Spaces based on most recent use”
        };

        WindowManager = {
          GloballyEnabled = true; # Enable "Stage Manager"
        };
      };

      keyboard = {
        enableKeyMapping = true; # Turn on nix-darwin’s key-mapping support
      };
    };
  };
}
```
- [ ] **Step 3:** Create `modules/hosts/biguy.nix`. `sharedHomeModules` is the exact old `home/default.nix` import list:
```nix
{ config, ... }:
let
  sharedHomeModules = with config.flake.modules.homeManager; [
    base
    email
    bash
    charm
    chromium
    codex
    eza
    fd
    fzf
    gh
    git
    golang
    helix
    nh
    nodejs
    nushell
    obsidian
    open-faas
    openai
    shell
    slack
    tmux
    tree
    vscode
    wezterm
    zsh
  ];
in
{
  configurations.darwin.biguy = {
    system = "aarch64-darwin";
    primaryUser = "WThorsen";

    homeModules = sharedHomeModules ++ [
      {
        programs.git.settings = {
          user = {
            name = "wesleythorsen";
            email = "wesley.thorsen@gmail.com";
          };
          credential.helper = "osxkeychain";
        };

        programs.ssh = {
          enable = true;
          matchBlocks."github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
            addKeysToAgent = "yes";
          };
        };
      }
    ];

    module = {
      imports = with config.flake.modules.darwin; [
        base
        macos-defaults
      ];

      networking.hostName = "KK9V4TQ0J0";
      nixpkgs.config.checkByDefault = false;
    };
  };
}
```
- [ ] **Step 4:** Create `modules/hosts/crackbookpro/default.nix` — same shape; differences from biguy, all verbatim from old files: `primaryUser = "wes"`; hostname `"crackbookpro"`; module extras: `nix.nixPath = lib.mkForce [ ];`, `services.tailscale.enable = true;`, `environment.systemPackages = with pkgs; [ curl exiftool fastfetch git jq unzip wget ];` (coreutils/nixos-rebuild come from base), `nixpkgs.config.checkByDefault = false;`; homeModules extra block: git identity (same) + `credential.helper = "osxkeychain"` but NO ssh block (old crackbookpro home.nix had none). Copy the old `hosts/crackbookpro/etc/` dir alongside (`git mv`).
- [ ] **Step 5:** Delete old darwin host files: `git rm -r hosts/biguy hosts/crackbookpro` (etc/ already moved).
- [ ] **Step 6:** Verify: `nix flake show` lists both darwinConfigurations; then `nix build .#darwinConfigurations.biguy.system --out-link "$SCRATCH/result-biguy"`.
- [ ] **Step 7:** Commit: `git commit -am "refactor: dendritic darwin modules and hosts"`

### Task 7: NixOS base + thinkpad + w530

**Files:**
- Create: `modules/nixos/base.nix`, `modules/hosts/thinkpad/default.nix`, `modules/hosts/w530/default.nix`
- Move: `git mv hosts/thinkpad/hardware-configuration.nix modules/hosts/thinkpad/_hardware-configuration.nix` (same for w530), `git mv hosts/thinkpad/nvidia.nix modules/hosts/thinkpad/_nvidia.nix`
- Delete: remaining `hosts/` files, then the `hosts/` dir itself

**Interfaces — Consumes:** same as Task 6 plus `configurations.nixos.*`.

- [ ] **Step 1:** Create `modules/nixos/base.nix` with ONLY the blocks where old thinkpad and w530 configuration.nix agree verbatim (spec §7 — no behavior invention):
```nix
{
  flake.modules.nixos.base =
    { config, pkgs, ... }:
    {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          config.primaryUser
        ];
      };

      networking.networkmanager.enable = true;
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };

      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";
      console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
      };

      boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };

      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PubkeyAuthentication = true;
          UseDns = false;
          UsePAM = true;
        };
      };

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish.enable = true;
        publish.addresses = true;
        publish.domain = true;
      };

      services.resolved.enable = true;
      services.acpid.enable = true;

      programs.zsh.enable = true;
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      system.stateVersion = "25.11";
    };
}
```
- [ ] **Step 2:** Create `modules/hosts/thinkpad/default.nix`: `configurations.nixos.thinkpad` with `system = "x86_64-linux"`, `primaryUser = "wes"`, `module.imports = [ ./_hardware-configuration.nix config.flake.modules.nixos.base ]`, and the REST of old `hosts/thinkpad/configuration.nix` verbatim minus what base now provides, minus the `nixpkgs`/`overlays` block (builder owns it), minus `nix.nixPath` (keep — thinkpad-specific, base has none: keep `nix.nixPath = lib.mkForce [ ];` in host module). Includes: hostname, sddm/xfce/xserver, pipewire+pulseaudio-off, users.users.wes (groups/keys/shell), sudo extraRules, printing, pcscd, hyprland mkForce-off, tmux, cachix substituters, `environment.etc."nix-config".source = inputs.self.outPath` (file header takes `{ config, inputs, ... }:`), systemPackages. `homeModules` = same `sharedHomeModules` list as the Macs (declare the same `let` block; old file imported `../../home`) plus a verbatim block from old `hosts/thinkpad/home.nix`: git identity, `credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager"` (as a `{ pkgs, ... }:` module), `home.packages = with pkgs; [ vlc wl-clipboard wofi ]`.
- [ ] **Step 3:** Create `modules/hosts/w530/default.nix`: `configurations.nixos.w530`, `primaryUser = "wes"`, `homeModules = [ ]` (system-only today), module = old `configuration.nix` verbatim minus base-covered blocks and the `nixpkgs` block, with these REQUIRED fixes:
  - `builtins.readFile ../../home/shell/nvim/config/settings.lua` → `builtins.readFile ../../nvim/config/settings.lua` (5 occurrences total across `config/` and `plugins/` — resolve against the migrated `modules/nvim/` layout).
  - `environment.etc."nix-config".source = self.outPath` → `inputs.self.outPath` (both occurrences: main + dev-shell specialisation).
  - Keep verbatim: tailscale + fetch-tailscale-key systemd unit, iperf3, specialisation.dev-shell (with its zsh/git/tmux/neovim/yazi/fzf blocks), sudo `wheelNeedsPassword = false`.
- [ ] **Step 4:** `git rm -r hosts` (everything left: thinkpad/configuration.nix, home.nix, w530/configuration.nix — content now lives in modules/hosts).
- [ ] **Step 5:** Verify eval:
```bash
nix eval .#nixosConfigurations.thinkpad.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.w530.config.system.build.toplevel.drvPath
```
- [ ] **Step 6:** Commit: `git commit -am "refactor: port thinkpad and w530 as dendritic nixos hosts"`

### Task 8: Docs

**Files:** Modify `AGENTS.md` (structure + commands sections), Create/extend `README.md`.

- [ ] **Step 1:** README.md: ~20-line "How this repo works" — every `.nix` under `modules/` is auto-imported (import-tree); features publish `flake.modules.<class>.<name>`; hosts live in `modules/hosts/` and are the ONLY files listing what runs where; underscore paths are opt-outs; add-a-tool recipe (create `modules/<tool>.nix`, add its name to a host's list).
- [ ] **Step 2:** AGENTS.md: update Project Structure section to the modules/ layout; commands section: `darwin-rebuild switch --flake .#{biguy,crackbookpro}`, `nixos-rebuild` for `.#{thinkpad,w530}` (note: eval-tested only, not build/boot-tested from macOS); keep style/commit sections.
- [ ] **Step 3:** Commit: `git commit -am "docs: describe dendritic layout"`

### Task 9: Verification gate (spec §8)

- [ ] **Step 1:** `nixfmt` every .nix file; `git diff --stat` review; commit if changes.
- [ ] **Step 2:** `nix flake check` passes.
- [ ] **Step 3:** Build both Macs (`--out-link "$SCRATCH/result-<host>"`), then:
```bash
nix store diff-closures "$SCRATCH/baseline-biguy" "$SCRATCH/result-biguy"
nix store diff-closures "$SCRATCH/baseline-crackbookpro" "$SCRATCH/result-crackbookpro"
```
Success bar: empty output, or every line traced to a spec-sanctioned cause (§6 overlay removal must be a no-op; investigate anything else — likely suspects: useGlobalPkgs flip, gh/golang default moves). Fix and rebuild until clean/justified.
- [ ] **Step 4:** Re-run both nixos toplevel evals (Task 7 Step 5 commands).
- [ ] **Step 5:** Final commit + summary of any justified diff lines in the commit message.
