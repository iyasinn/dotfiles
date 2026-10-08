local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function current_cwd(pane)
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri and cwd_uri.file_path then
    return cwd_uri.file_path
  end
  return wezterm.home_dir
end

local function switch_to_session(window, pane, name, cwd)
  window:perform_action(
    act.SwitchToWorkspace({
      name = name,
      spawn = {
        label = "Session: " .. name,
        cwd = cwd,
      },
    }),
    pane
  )
end

local function create_workspace_prompt()
  return act.PromptInputLine({
    description = "New session/workspace name:",
    action = wezterm.action_callback(function(window, pane, line)
      line = line and line:match("^%s*(.-)%s*$")
      if not line or line == "" then
        return
      end

      switch_to_session(window, pane, line, current_cwd(pane))
    end),
  })
end

local function shorten_home(path)
  if path:sub(1, #wezterm.home_dir + 1) == wezterm.home_dir .. "/" then
    return "~" .. path:sub(#wezterm.home_dir + 1)
  end
  return path
end

function M.apply(config, enabled)
  local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
  local resurrect_enabled = not enabled or enabled.resurrect ~= false
  local function delete_saved_state(window, pane)
    if not resurrect_enabled then
      return
    end
    local resurrect = require("plugins.resurrect.init").get()
    resurrect.fuzzy_loader.fuzzy_load(window, pane, function(state_id)
      resurrect.state_manager.delete_state(state_id)
    end, {
      title = "Delete Saved Session State",
      description = "Select saved state to delete. This does not close a live workspace.",
      fuzzy_description = "Delete saved state: ",
      is_fuzzy = true,
    })
  end

  local fd_path = "/opt/homebrew/bin/fd"

  local project_schema = {
    options = {
      title = "Create Session From Project",
      prompt = "Project: ",
      callback = function(window, pane, id)
        if not id or id == "" then
          return
        end

        local path = id:gsub("/+$", "")
        switch_to_session(window, pane, path, path)
      end,
    },

    -- FdSearch only lists git repositories, not every folder.
    sessionizer.FdSearch({ wezterm.home_dir .. "/anvil", fd_path = fd_path, max_depth = 5 }),
    sessionizer.FdSearch({ wezterm.home_dir .. "/go", fd_path = fd_path, max_depth = 5 }),
    sessionizer.FdSearch({ wezterm.home_dir .. "/Documents", fd_path = fd_path, max_depth = 5 }),

    processing = sessionizer.for_each_entry(function(entry)
      entry.label = shorten_home(entry.label)
    end),
  }

  local schema = {
    options = {
      title = "Sessions",
      prompt = "Session: ",
      callback = function(window, pane, id)
        if not id then
          return
        end
        if id == "__create__" then
          window:perform_action(create_workspace_prompt(), pane)
          return
        end

        if id == "__project__" then
          window:perform_action(sessionizer.show(project_schema), pane)
          return
        end

        if id == "__delete_saved__" then
          delete_saved_state(window, pane)
          return
        end

        if id == "__keys__" then
          window:perform_action(
            act.ShowLauncherArgs({ flags = "KEY_ASSIGNMENTS", title = "Key Bindings" }),
            pane
          )
          return
        end

        if id == wezterm.config_dir then
          switch_to_session(window, pane, id, id)
        else
          -- Workspace names are not filesystem paths (especially "default").
          switch_to_session(window, pane, id, wezterm.home_dir)
        end
      end,
    },

    { label = "+ create new session from current directory", id = "__create__" },
    { label = "+ create new session from project directory", id = "__project__" },
    { label = "? show key bindings", id = "__keys__" },
    sessionizer.DefaultWorkspace({ label_overwrite = "Default" }),
    sessionizer.AllActiveWorkspaces({ filter_current = false, filter_default = true }),
    { label = "WezTerm config", id = wezterm.config_dir },

    processing = sessionizer.for_each_entry(function(entry)
      entry.label = shorten_home(entry.label)
    end),
  }

  if resurrect_enabled then
    table.insert(schema, 3, { label = "- delete saved session state", id = "__delete_saved__" })
  end

  table.insert(config.keys, {
    key = "s",
    mods = "LEADER",
    action = sessionizer.show(schema),
    desc = resurrect_enabled and "Sessions: switch/create/delete/help" or "Sessions: switch/create/help",
  })

  table.insert(config.keys, {
    key = "c",
    mods = "LEADER",
    action = create_workspace_prompt(),
    desc = "Create session from current directory",
  })

  table.insert(config.keys, {
    key = "p",
    mods = "LEADER",
    action = sessionizer.show(project_schema),
    desc = "Create session from fuzzy project picker",
  })

  if resurrect_enabled then
    table.insert(config.keys, {
      key = "d",
      mods = "LEADER",
      action = wezterm.action_callback(delete_saved_state),
      desc = "Delete saved session state",
    })
  end

  table.insert(config.keys, {
    key = "?",
    mods = "LEADER|SHIFT",
    action = act.ShowLauncherArgs({ flags = "KEY_ASSIGNMENTS", title = "Key Bindings" }),
    desc = "Show key bindings",
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
