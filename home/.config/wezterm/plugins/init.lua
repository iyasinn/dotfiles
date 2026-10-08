local M = {}

-- Set a plugin to false, then reload with Cmd+Shift+R, to disable it.
M.enabled = {
  smart_splits = true,
  sessionizer = true,
  resurrect = true,
  tabline = true,
  cmdpicker = true,
}

local plugins = {
  { name = "smart_splits", module = "plugins.smart_splits.init" },
  { name = "sessionizer", module = "plugins.sessionizer.init" },
  { name = "resurrect", module = "plugins.resurrect.init" },
  { name = "tabline", module = "plugins.tabline.init" },
  -- Keep Command Picker last so it discovers keys added by other plugins.
  { name = "cmdpicker", module = "plugins.cmdpicker.init" },
}

function M.apply(config)
  for _, entry in ipairs(plugins) do
    local plugin = require(entry.module)

    if M.enabled[entry.name] then
      plugin.apply(config, M.enabled)
    elseif plugin.fallback then
      plugin.fallback(config)
    end
  end
end

return M
