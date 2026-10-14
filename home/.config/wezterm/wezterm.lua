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
config.line_height = 1.0

-- Window
config.window_decorations = "RESIZE" -- Hidden title bar, with window resizing enabled.
config.window_close_confirmation = "AlwaysPrompt"
config.initial_cols = 110
config.initial_rows = 34
config.window_padding = {
	left = 10,
	right = 10,
	top = 8,
	bottom = 8,
}
-- Match Ghostty's glass effect.
config.window_background_opacity = 0.8
config.macos_window_background_blur = 30
-- Approximate Ghostty's unfocused split opacity with brightness (not alpha).
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 0.7,
}

-- Appearance
config.colors = require("colors.tron-legacy")
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
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
	{ key = "r", mods = "CMD|SHIFT", action = act.ReloadConfiguration, desc = "Reload WezTerm config" },
	{ key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain"), desc = "New tab" },
	{
		key = ",",
		mods = "CMD",
		action = act.PromptInputLine({
			description = "Rename tab (leave empty to reset)",
			action = wezterm.action_callback(function(window, _pane, line)
				if line ~= nil then
					window:active_tab():set_title(line)
				end
			end),
		}),
		desc = "Rename current tab",
	},
	{ key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = true }), desc = "Close current tab" },
	{ key = "n", mods = "CMD", action = act.SpawnWindow, desc = "New window" },
	{ key = "z", mods = "CMD", action = act.TogglePaneZoomState, desc = "Toggle pane zoom" },
	{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1), desc = "Previous tab" },
	{ key = "RightArrow", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1), desc = "Next tab" },

	-- Send a literal Ctrl+a with Ctrl+a, Ctrl+a.
	{
		key = "a",
		mods = "LEADER|CTRL",
		action = act.SendKey({ key = "a", mods = "CTRL" }),
		desc = "Send literal Ctrl-a",
	},

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
	{
		key = "\\",
		mods = "LEADER",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		desc = "Split pane horizontally",
	},
	{
		key = "-",
		mods = "LEADER",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		desc = "Split pane vertically",
	},
	{ key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 4 }), desc = "Resize pane left" },
	{ key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 4 }), desc = "Resize pane down" },
	{ key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 4 }), desc = "Resize pane up" },
	{ key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 4 }), desc = "Resize pane right" },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }), desc = "Close current pane" },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState, desc = "Toggle pane zoom" },

	-- Utilities
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode, desc = "Copy mode" },
	{ key = "q", mods = "LEADER", action = act.QuickSelect, desc = "Quick select" },
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
