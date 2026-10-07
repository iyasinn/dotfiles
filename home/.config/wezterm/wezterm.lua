local wezterm = require("wezterm")
local act = wezterm.action
local plugins = require("plugins.init")

local config = wezterm.config_builder()

-- Basics
config.term = "xterm-256color"
config.check_for_updates = false
config.scrollback_lines = 20000
config.audible_bell = "Disabled"

-- Font
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Symbols Nerd Font Mono",
})
config.font_size = 14
config.line_height = 1.08

-- Window
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.initial_cols = 120
config.initial_rows = 36
config.window_padding = {
	left = 12,
	right = 12,
	top = 10,
	bottom = 8,
}
-- config.window_background_opacity = 0.86
config.window_background_opacity = 1
config.macos_window_background_blur = 24
config.inactive_pane_hsb = {
	saturation = 0.85,
	brightness = 0.60,
}

-- Appearance
config.color_scheme = "Tokyo Night"
config.colors = {
	cursor_bg = "#c084fc",
	cursor_fg = "#080b12",
	cursor_border = "#c084fc",
	selection_fg = "#080b12",
	selection_bg = "#c7d2fe",
	split = "#30363d",
}
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 28

-- Ctrl+a starts a terminal command sequence.
config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

config.keys = {
	-- Reload and native macOS controls
	{ key = "r", mods = "CMD|SHIFT", action = act.ReloadConfiguration },
	{ key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "n", mods = "CMD", action = act.SpawnWindow },
	{ key = "z", mods = "CMD", action = act.TogglePaneZoomState },
	{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },

	-- Send a literal Ctrl+a with Ctrl+a, Ctrl+a.
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Tabs
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },
	-- Splits
	{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 4 }) },
	{ key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 4 }) },
	{ key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 4 }) },
	{ key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 4 }) },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- Utilities
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "o", mods = "LEADER", action = act.QuickSelect },
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = act.OpenLinkAtMouseCursor,
	},
}

plugins.apply(config)

return config
