local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  local resurrect = wezterm.plugin.require("https://github.com/StephenGemin/resurrect.wezterm")
  resurrect.setup(config, {
    status_bar = false,
  })
end

return M
