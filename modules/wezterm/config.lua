local act = wezterm.action
local gpus = wezterm.gui.enumerate_gpus()

return {
  enable_wayland = false,
  prefer_egl = true,
  front_end = "WebGpu",
  webgpu_preferred_adapter = gpus[2],
  -- color_scheme = 'Batman',
  -- color_scheme = 'Matrix (terminal.sexy)',
  -- color_scheme = 'Tango Adapted',
  -- color_scheme = 'Material (terminal.sexy)',
  color_scheme = 'tokyonight_night',
  -- color_scheme = 'Catppuccin Mocha',
  -- color_scheme = 'Catppuccin Macchiato',
  -- color_scheme = 'Catppuccin Frappe',
  -- color_scheme = 'Catppuccin Latte',
  -- disable contextual alternates, classic ligatures, and discretionary ligatures (will stop “!=” becoming “≠”):
  harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
  enable_tab_bar = true,
  inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.6,
  },
  -- enable_scroll_bar = true,
  -- background = {
  --   {
  --     source = {
  --       Color="#24273a"
  --     },
  --     height = "100%",
  --     width = "100%",
  --   },
  -- },
  font = wezterm.font_with_fallback({
		--"JetBrains Mono", -- <built-in>, wezterm default
		"JetBrainsMono Nerd Font Mono", -- custom, for missing glyphs: { Error: "", Warn: "", Hint: "", Info: "" }
		"Symbols Nerd Font Mono", -- <built-in>, wezterm default
		"Apple Color Emoji", -- <built-in>, wezterm default ❌❤️😀🎶⌘
		"Noto Color Emoji", -- <built-in>, wezterm default
	}),
  -- font_size = 13.0,
  -- use_cap_height_to_scale_fallback_fonts = true,
  launch_menu = {
    {
      args = { 'btop' },
    },
    {
      args = { 'cmatrix' },
    },
    {
      args = { 'pipes-rs' },
    },
  },
  keys = {
    {
      key = 'j',
      mods = 'CTRL|SHIFT',
      action = act.ScrollByPage(1)
    },
    {
      key = 'k',
      mods = 'CTRL|SHIFT',
      action = act.ScrollByPage(-1)
    },
    {
      key = 'g',
      mods = 'CTRL|SHIFT',
      action = act.ScrollToTop
    },
    {
      key = 'e',
      mods = 'CTRL|SHIFT',
      action = act.ScrollToBottom
    },
    {
      key = 'p',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.PaneSelect
    },
    {
      key = 'o',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.PaneSelect { mode = "SwapWithActive" }
    },
    {
      key = '%',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.SplitVertical { domain = 'CurrentPaneDomain' }
    },
    {
      key = '"',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' }
    },
    {
      key = 'LeftArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.AdjustPaneSize { 'Left', 1 }
    },
    {
      key = 'RightArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.AdjustPaneSize { 'Right', 1 }
    },
    {
      key = 'UpArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.AdjustPaneSize { 'Up', 1 }
    },
    {
      key = 'DownArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.AdjustPaneSize { 'Down', 1 }
    },
    {
      key = 'h',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.ActivatePaneDirection 'Left'
    },
    {
      key = 'l',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.ActivatePaneDirection 'Right'
    },
    {
      key = 'k',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.ActivatePaneDirection 'Up'
    },
    {
      key = 'j',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.ActivatePaneDirection 'Down'
    },
    {
      key = 'z',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.TogglePaneZoomState
    },
    {
      key = 'q',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.CloseCurrentPane { confirm = true }
    },
    {
      key = 'b',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.RotatePanes 'CounterClockwise'
    },
    {
      key = 'n',
      mods = 'CTRL|SHIFT|SUPER',
      action = act.RotatePanes 'Clockwise'
    },
    {
      key = 'd',
      mods = 'CTRL|SHIFT',
      action = act.ShowLauncher
    },
    {
      key = ':',
      mods = 'CTRL|SHIFT',
      action = act.ClearSelection
    },
    {
      key = 'Enter',
      mods = 'ALT',
      action = wezterm.action.DisableDefaultAssignment,
    },
    -- Rebind OPT-Left, OPT-Right as ALT-b, ALT-f respectively to match Terminal.app behavior
    {
      key = 'LeftArrow',
      mods = 'OPT',
      action = act.SendKey { key = 'b', mods = 'ALT' },
    },
    {
      key = 'RightArrow',
      mods = 'OPT',
      action = act.SendKey { key = 'f', mods = 'ALT' },
    },
  },
}
