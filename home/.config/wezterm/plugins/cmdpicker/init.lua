local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  local cmdpicker = wezterm.plugin.require("https://github.com/abidibo/wezterm-cmdpicker")
  cmdpicker.apply_to_config(config, {
    title = "Command Palette",
  })
end

return M
