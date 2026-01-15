{
  ...
}:

{
  programs.obsidian = {
    enable = true;

    vaults = {
      tetra = {
        enable = true;
        target = "tetra/notes";
        # settings = {
        #   communityPlugins = [
        #     {
        #       pkg = "confluence-integration";
        #       enable = true;
        #       # settings = { };
        #     }
        #   ];
        # };
      };
    };
  };

  # ensure ~/tetra/notes exists
  # home.file."tetra/notes" = {
  #   directory = true;
  # };
  home.file."tetra/notes/.keep".text = "";
}
