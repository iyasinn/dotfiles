local wezterm = require("wezterm")

local M = {}

local plugin_url = "https://github.com/StephenGemin/resurrect.wezterm"
local instance

function M.get()
  if instance then
    return instance
  end

  -- The fork's loader selects the first plugin URL containing "resurrect".
  -- Resolve its modules from this exact checkout when the old fork is installed too.
  for _, plugin in ipairs(wezterm.plugin.list()) do
    if plugin.url == plugin_url then
      local module_root = plugin.plugin_dir .. "/plugin/"
      table.insert(package.searchers, 2, function(name)
        if name:match("^resurrect%.") then
          return assert(loadfile(module_root .. name:gsub("%.", "/") .. ".lua"))
        end
      end)
      break
    end
  end

  instance = wezterm.plugin.require(plugin_url)
  return instance
end

function M.apply(config)
  local resurrect = M.get()
  resurrect.setup(config, {
    status_bar = false,
  })
end

return M
