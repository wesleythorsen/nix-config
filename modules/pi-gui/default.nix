{
  # pi-gui: signed+notarized upstream .dmg, unpacked into the store.
  # mac-app-util (wired in modules/flake/configurations.nix) links it into
  # ~/Applications/Home Manager Apps so Spotlight/Launchpad find it.
  # Shares ~/.pi/agent settings, auth and sessions with the pi CLI.
  flake.modules.homeManager.pi-gui =
    { pkgs, ... }:
    {
      home.packages = [ (pkgs.callPackage ./_package.nix { }) ];
    };
}
