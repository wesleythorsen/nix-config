{
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = [
        ",preferred,auto,1,mirror,LVDS-2"
        "LVDS-2,1600x900@60.22200,0x0,1"
        "DP-1,1920x1080@60.00000,1600x0,1"
      ];

      exec-once = [
        "waybar"
      ];

      general = {
        allow_tearing = true;
      };

      # input = {
      #   kb_options = "caps:swapescape";
      # };

      "$mod" = "SUPER";
      "$mods" = "SUPERSHIFT";
      bind = [
        "$mod, Space, exec, wofi --show drun"
        # "$mod, Return, exec, ${pkgs.${vars.terminal}}/bin/${vars.terminal}"
        "$mod, Q, killactive, "
        "$mod, Escape, exit, "
        "$mod, S, exec, ${pkgs.systemd}/bin/systemctl suspend"
        "$mod, F, togglefloating, "
        ", F11, fullscreen"
        "$mod, R, forcerendererreload"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, h, movewindow, d"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        # "$mod ALT, left, workspace, l"
        # "$mod ALT, right, workspace, r"
        "$mod ALT, h, exec, hyprctl dispatch workspace $(expr $(hyprctl activeworkspace -j | jq '.id' -r) - 1)"
        "$mod ALT, l, exec, hyprctl dispatch workspace $(expr $(hyprctl activeworkspace -j | jq '.id' -r) + 1)"
        "$mod ALT, left, exec, hyprctl dispatch workspace $(expr $(hyprctl activeworkspace -j | jq '.id' -r) - 1)"
        "$mod ALT, right, exec, hyprctl dispatch workspace $(expr $(hyprctl activeworkspace -j | jq '.id' -r) + 1)"
        "$mod, Return, exec, wezterm"
        # "$mod, T, exec, kitty"
        "$mod, B, exec, brave"
        ", Print, exec, grimblast copy area"
      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          ) 9
        )
      );
    };
  };
}
