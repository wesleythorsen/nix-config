{
  pkgs,
  ...
}:

{
  programs.tmux = {
    enable = true;

    mouse = true;
    keyMode = "vi";

    plugins = [
      pkgs.tmuxPlugins.sensible
      pkgs.tmuxPlugins.tmux-fzf
    ];

    extraConfig = "";
  };
}
