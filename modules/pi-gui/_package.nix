{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-gui";
  version = "1.0.1";

  src = fetchurl {
    url = "https://github.com/minghinmatthewlam/pi-gui/releases/download/v${finalAttrs.version}/pi-gui-${finalAttrs.version}-arm64.dmg";
    hash = "sha256-D9Bro0AFg/ycXLhrc0rA8+rS0S2XF/Jx1yjReExVTqQ=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R pi-gui.app "$out/Applications/"
    runHook postInstall
  '';

  meta = {
    description = "Electron desktop client for the Pi coding agent (threads, worktrees, diffs, terminal)";
    homepage = "https://github.com/minghinmatthewlam/pi-gui";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
