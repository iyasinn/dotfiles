local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
  local smart_splits = wezterm.plugin.require("https://github.com/smart-splits-nvim/smart-splits.nvim")
  smart_splits.apply_to_config(config, {
    direction_keys = { "h", "j", "k", "l" },
    modifiers = {
      move = "CTRL",
      resize = { wezterm = "SUPER", neovim = "ALT" },
    },
  })
end

function M.fallback(config)
  table.insert(config.keys, { key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") })
  table.insert(config.keys, { key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") })
  table.insert(config.keys, { key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") })
  table.insert(config.keys, { key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") })
end

return M
