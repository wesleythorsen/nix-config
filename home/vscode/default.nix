{
  config,
  pkgs,
  lib,
  inputs,
  overlays,
  ...
}:

let
  overlayedPkgs = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    overlays = overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
in
{
  # symlink vscode settings files so changes get saved in nix-config
  home.activation.linkVSCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #!/usr/bin/env bash
    set -euo pipefail
    CODE_DIR="${config.home.homeDirectory}/Library/Application Support/Code/User"
    NIX_CONFIG_DIR="${config.homeConfig.nixConfigPath}/home/vscode"
    mkdir -p "$CODE_DIR"
    ln -sf "$NIX_CONFIG_DIR/settings.json" "$CODE_DIR/settings.json"
    ln -sf "$NIX_CONFIG_DIR/keybindings.json" "$CODE_DIR/keybindings.json"
  '';

  programs.vscode = {
    enable = true;

    profiles.default = {
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = true;

      # extensions = with pkgs.nix-vscode-extensions.vscode-marketplace; [
      extensions = with overlayedPkgs.vscode-marketplace; [
        # 42crunch.vscode-openapi # check "vscode-utils.extensionsFromVscodeMarketplace" https://www.reddit.com/r/NixOS/comments/115s2gi/how_do_i_reference_a_package_name_that_begins/
        alefragnani.bookmarks
        amih90.to
        augment.vscode-augment
        # aws-scripting-guy.cform
        bbenoist.nix
        # continue.continue
        dbaeumer.vscode-eslint
        denoland.vscode-deno
        # dotjoshjohnson.xml
        # eamodio.gitlens
        esbenp.prettier-vscode
        # golang.go
        gruntfuggly.todo-tree
        heaths.vscode-guid
        jnoortheen.nix-ide
        johnpapa.winteriscoming
        jsynowiec.vscode-insertdatestring
        # mhutchie.git-graph
        mohsen1.prettify-json
        # mongodb.mongodb-vscode
        # ms-azuretools.vscode-docker
        # ms-dotnettools.csdevkit
        # ms-dotnettools.csharp
        # ms-dotnettools.vscode-dotnet-runtime
        # ms-kubernetes-tools.vscode-kubernetes-tools
        # ms-python.debugpy
        # ms-python.isort
        # ms-python.python
        # ms-python.vscode-pylance
        # ms-vscode-remote.remote-containers
        naumovs.color-highlight
        orta.vscode-jest
        oven.bun-vscode
        # redhat.java
        # redhat.vscode-xml
        redhat.vscode-yaml
        rvest.vs-code-prettier-eslint
        shd101wyy.markdown-preview-enhanced
        streetsidesoftware.code-spell-checker
        # threadheap.serverless-ide-vscode
        visualstudioexptteam.intellicode-api-usage-examples
        visualstudioexptteam.vscodeintellicode
        # vscjava.vscode-gradle
        # vscjava.vscode-java-debug
        # vscjava.vscode-java-dependency
        # vscjava.vscode-java-pack
        # vscjava.vscode-java-test
        # vscjava.vscode-maven
      ];
    };
  };
}
