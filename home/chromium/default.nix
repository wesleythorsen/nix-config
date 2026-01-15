{
  pkgs,
  ...
}:

{
  programs.brave = {
    enable = true;

    package = pkgs.brave;

    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
      { id = "cnjifjpddelmedmihgijeibhnjfabmlf"; } # obsidian web clipper
    ];

    commandLineArgs = [
      "--disable-component-update"
      "--disable-features=WebRtcAllowInputVolumeAdjustment"
    ];
  };
}
