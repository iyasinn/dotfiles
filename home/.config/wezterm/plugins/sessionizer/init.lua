local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
  local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
  local fd_path = "/opt/homebrew/bin/fd"
  local schema = {
    sessionizer.DefaultWorkspace({}),
    sessionizer.AllActiveWorkspaces({ filter_current = false }),
    { label = "WezTerm config", id = wezterm.config_dir },
    sessionizer.FdSearch({ wezterm.home_dir .. "/anvil", fd_path = fd_path, max_depth = 5 }),
    sessionizer.FdSearch({ wezterm.home_dir .. "/go", fd_path = fd_path, max_depth = 5 }),
    sessionizer.FdSearch({ wezterm.home_dir .. "/Documents", fd_path = fd_path, max_depth = 5 }),
    processing = sessionizer.for_each_entry(function(entry)
      entry.label = entry.label:gsub(wezterm.home_dir, "~")
    end),
  }

  table.insert(config.keys, {
    key = "s",
    mods = "LEADER",
    action = sessionizer.show(schema),
  })
end

function M.fallback(config)
  table.insert(config.keys, {
    key = "s",
    mods = "LEADER",
    action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Workspaces" }),
  })
end

return M
