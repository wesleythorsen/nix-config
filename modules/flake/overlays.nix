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
