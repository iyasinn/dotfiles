local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  local cmdpicker = wezterm.plugin.require("https://github.com/abidibo/wezterm-cmdpicker")
  -- Auto-discovery drops desc, so register the annotated bindings explicitly.
  for _, binding in ipairs(config.keys) do
    if binding.desc then
      cmdpicker.register(binding)
    end
  end
  cmdpicker.apply_to_config(config, {
    title = "Command Palette",
  })
end

return M
