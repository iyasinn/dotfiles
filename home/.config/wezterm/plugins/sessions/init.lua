local wezterm = require("wezterm")
local M = {}
local root = wezterm.config_dir .. "/plugins/sessions"
local art = require("plugins.sessions.art")
local state_dir = (os.getenv("XDG_STATE_HOME") or (wezterm.home_dir .. "/.local/state")) .. "/wezterm/sessions"
local state_path = state_dir .. "/index.json"
local engine

local function read_json(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local text = file:read("*a")
  file:close()
  return wezterm.json_parse(text)
end

local function write_json(path, value)
  local file = assert(io.open(path .. ".tmp", "w"))
  assert(file:write(wezterm.json_encode(value)))
  assert(file:close())
  assert(os.rename(path .. ".tmp", path))
end

local function load()
  local state = read_json(state_path) or { version = 1, sessions = {} }
  assert(state.version == 1 and type(state.sessions) == "table", "Unsupported session state file")
  return state
end

local function persist(state)
  local ok, _, err = wezterm.run_child_process({ "mkdir", "-p", state_dir })
  assert(ok, err)
  write_json(state_path, state)
end

local function valid_name(name)
  assert(type(name) == "string", "Session name must be text")
  name = name:match("^%s*(.-)%s*$")
  assert(#name > 0 and #name <= 120 and not name:find("[%c]"), "Use a name of 1–120 bytes, without control characters")
  return name
end

local function pickers()
  return wezterm.GLOBAL.session_pickers or {}
end

local function live()
  local names = {}
  for _, win in ipairs(wezterm.mux.all_windows()) do
    names[win:get_workspace()] = true
  end
  return names
end

local function is_picker(tab)
  local contexts = pickers()
  for _, pane in ipairs(tab:panes()) do
    if contexts[tostring(pane:pane_id())] then return contexts[tostring(pane:pane_id())] end
  end
  return nil
end

local function cleanup_pickers()
  local contexts = pickers()
  for id, context in pairs(contexts) do
    local found, pane = pcall(wezterm.mux.get_pane, context.picker_pane)
    if not found or not pane then
      if context.origin_pane then
        local exists, origin = pcall(wezterm.mux.get_pane, context.origin_pane)
        if exists and origin then
          origin:activate()
          origin:tab():set_zoomed(context.was_zoomed or false)
        end
      end
      contexts[id] = nil
    end
  end
  wezterm.GLOBAL.session_pickers = contexts
end

local function watch_picker(id)
  wezterm.time.call_after(0.15, function()
    cleanup_pickers()
    if pickers()[id] then watch_picker(id) end
  end)
end

local function clean_tree(tree)
  if not tree then return end
  -- Save layout and directories only; restoring never re-executes commands.
  tree.text, tree.process = nil, nil
  if not tree.cwd or tree.cwd == "" then tree.cwd = wezterm.home_dir end
  clean_tree(tree.right)
  clean_tree(tree.bottom)
end

local function capture(state)
  local snapshots = {}
  for _, win in ipairs(wezterm.mux.all_windows()) do
    local name = win:get_workspace()
    local snapshot = snapshots[name] or { workspace = name, window_states = {} }
    local window_state = { title = win:get_title(), tabs = {} }
    for _, info in ipairs(win:tabs_with_info()) do
      local context = is_picker(info.tab)
      if not context or context.original_tab_state then
        -- Keep the pre-picker layout while the temporary pane is present.
        local tab = context and wezterm.json_parse(wezterm.json_encode(context.original_tab_state))
          or engine.tab_state.get_tab_state(info.tab)
        tab.is_active = info.is_active
        clean_tree(tab.pane_tree)
        table.insert(window_state.tabs, tab)
        window_state.size = context and context.original_tab_size or info.tab:get_size()
      end
    end
    if #window_state.tabs > 0 then
      -- Also support an old temporary-tab picker still open during a reload.
      for _, context in pairs(pickers()) do
        if context.window_id == win:window_id() and not context.origin_pane then
          local index = 0
          for _, info in ipairs(win:tabs_with_info()) do
            if not is_picker(info.tab) then
              index = index + 1
              window_state.tabs[index].is_active = info.tab:tab_id() == context.origin_tab
            end
          end
        end
      end
      table.insert(snapshot.window_states, window_state)
      snapshots[name] = snapshot
    end
  end
  for name, snapshot in pairs(snapshots) do
    state.sessions[name] = { snapshot = snapshot }
  end
  return state
end

local function entries(state, current)
  local running, rows = live(), {}
  local names = {}
  for name in pairs(state.sessions) do names[name] = true end
  for name in pairs(running) do names[name] = true end
  for name in pairs(names) do
    table.insert(rows, {
      name = name,
      status = name == current and "active" or (running[name] and "running" or "saved"),
      snapshot = state.sessions[name] and state.sessions[name].snapshot or nil,
    })
  end
  local rank = { active = 1, running = 2, saved = 3 }
  table.sort(rows, function(a, b)
    if rank[a.status] ~= rank[b.status] then return rank[a.status] < rank[b.status] end
    return a.name:lower() < b.name:lower()
  end)
  return rows
end

local function origin_tab(context)
  local ok, tab = pcall(wezterm.mux.get_tab, context.origin_tab)
  if ok and tab then tab:activate() end
end

local function switch(name, cwd, state)
  if not live()[name] then
    local saved = state.sessions[name]
    if saved and saved.snapshot and #saved.snapshot.window_states > 0 then
      engine.workspace_state.restore_workspace(saved.snapshot, { relative = true, switch_workspace = false })
      assert(live()[name], "Could not restore session; its saved layout has been kept")
    else
      wezterm.mux.spawn_window({ workspace = name, cwd = cwd })
    end
  end
  wezterm.mux.set_active_workspace(name)
end

local function delete_session(name, context, state, socket)
  local terminals = {}
  for _, win in ipairs(wezterm.mux.all_windows()) do
    if win:get_workspace() == name then
      for _, tab in ipairs(win:tabs()) do
        for _, pane in ipairs(tab:panes()) do
          if pane:pane_id() ~= context.picker_pane then
            table.insert(terminals, pane:pane_id())
          end
        end
      end
    end
  end
  local closes_picker = context.workspace == name
  if closes_picker then
    local fallback
    for other in pairs(live()) do
      if other ~= name then fallback = other; break end
    end
    if not fallback then
      fallback = name == "default" and "scratch" or "default"
      -- A saved fallback should be restored rather than silently replaced.
      switch(fallback, wezterm.home_dir, state)
    else
      wezterm.mux.set_active_workspace(fallback)
    end
  end
  if #terminals > 0 then
    assert(type(socket) == "string" and socket ~= "", "The picker has no WezTerm socket; terminals were not closed")
  end
  for _, id in ipairs(terminals) do
    -- GUI CloseCurrentPane follows focus, even when given another pane. The
    -- picker inherits the exact mux socket, so the CLI can target IDs safely.
    local ok, _, err = wezterm.run_child_process({ "env", "WEZTERM_UNIX_SOCKET=" .. socket,
      wezterm.executable_dir .. "/wezterm", "cli", "--no-auto-start", "kill-pane", "--pane-id", tostring(id) })
    assert(ok, "Could not close a terminal: " .. err)
  end
  state.sessions[name] = nil
  persist(state)
  return closes_picker
end

local function handle(window, pane, value)
  local context = pickers()[tostring(pane:pane_id())]
  if not context then return end -- Ignore OSC requests from ordinary terminals.
  local request = wezterm.json_parse(value)
  assert(type(request.id) == "string", "Missing request ID")
  local response = { id = request.id }
  local ok, err = pcall(function()
    local state = load()
    if request.action == "cancel" then
      origin_tab(context)
    elseif request.action == "open" then
      local name = valid_name(request.name)
      capture(state)
      persist(state)
      origin_tab(context)
      switch(name, context.cwd, state)
      capture(state)
      persist(state)
    elseif request.action == "rename" then
      local name, new_name = valid_name(request.name), valid_name(request.new_name)
      if name ~= new_name then
        capture(state)
        assert(not state.sessions[new_name] and not live()[new_name], "A session with that name already exists")
        assert(state.sessions[name] or live()[name], "That session no longer exists")
        if live()[name] then wezterm.mux.rename_workspace(name, new_name) end
        state.sessions[new_name] = state.sessions[name]
        if state.sessions[new_name] then state.sessions[new_name].snapshot.workspace = new_name end
        state.sessions[name] = nil
        local contexts = pickers()
        for id, item in pairs(contexts) do
          if item.workspace == name then item.workspace = new_name; contexts[id] = item end
        end
        wezterm.GLOBAL.session_pickers = contexts
        context = contexts[tostring(pane:pane_id())]
        persist(state)
      end
    elseif request.action == "delete" then
      local name = valid_name(request.name)
      response.close = delete_session(name, context, state, request.socket)
    else
      error("Unknown session action")
    end
    write_json(context.directory .. "/sessions.json", entries(state, context.workspace))
  end)
  if not ok then response.error = tostring(err); wezterm.log_error(err) end
  write_json(context.directory .. "/reply.json", response)
end

local function executable(name)
  local ok, out = wezterm.run_child_process({ "/bin/sh", "-c", "command -v " .. name })
  if ok and out:match("%S") then return out:gsub("%s+$", "") end
  for _, prefix in ipairs({ "/opt/homebrew/bin/", "/usr/local/bin/", "/usr/bin/" }) do
    local file = io.open(prefix .. name, "r")
    if file then file:close(); return prefix .. name end
  end
  error("Install " .. name .. " to use the session picker")
end

function M.open(window, pane)
  local ok, err = pcall(function()
    cleanup_pickers()
    -- One picker at a time avoids conflicting edits and deleting another picker.
    local contexts = pickers()
    for id, context in pairs(contexts) do
      local found, picker_pane = pcall(wezterm.mux.get_pane, context.picker_pane)
      if found and picker_pane then
        wezterm.mux.set_active_workspace(context.workspace)
        picker_pane:tab():activate()
        picker_pane:activate()
        if context.origin_pane then picker_pane:tab():set_zoomed(true) end
        return
      end
      contexts[id] = nil
    end
    wezterm.GLOBAL.session_pickers = contexts
    local python, fzf = executable("python3"), executable("fzf")
    local state = capture(load())
    persist(state)
    local success, directory = wezterm.run_child_process({ "mktemp", "-d", "/tmp/wezterm-sessions.XXXXXXXX" })
    assert(success, "Could not create picker directory")
    directory = directory:gsub("%s+$", "")
    local cwd_url = pane:get_current_working_dir()
    local cwd = cwd_url and cwd_url.file_path or wezterm.home_dir
    -- A remote pane's path may not exist on this machine; the picker runs locally.
    if pane:get_domain_name() ~= "local" then cwd = wezterm.home_dir end
    local context = { directory = directory, cwd = cwd, workspace = window:active_workspace(),
      origin_tab = pane:tab():tab_id(), origin_pane = pane:pane_id(), window_id = window:window_id() }
    write_json(directory .. "/sessions.json", entries(state, context.workspace))
    local tab = pane:tab()
    context.original_tab_state = engine.tab_state.get_tab_state(tab)
    clean_tree(context.original_tab_state.pane_tree)
    context.original_tab_size = tab:get_size()
    context.was_zoomed = context.original_tab_state.is_zoomed
    tab:set_zoomed(false)
    local picker_env = art.environment()
    picker_env.SESSION_WEZTERM = wezterm.executable_dir .. "/wezterm"
    picker_env.SESSION_ORIGIN_PANE = tostring(context.origin_pane)
    local spawned, picker_pane = pcall(function() return pane:split({
      args = { python, root .. "/picker.py", "picker", directory, fzf },
      set_environment_variables = picker_env,
      cwd = cwd, domain = { DomainName = "local" },
      -- A top-level split corrupts subsequent split geometry on WezTerm
      -- 20240203 (wezterm/wezterm#4984). Split only the originating pane;
      -- zoom still makes the picker fill the whole tab.
      direction = "Bottom", size = 0.5,
    }) end)
    if not spawned then
      pane:activate()
      tab:set_zoomed(context.was_zoomed)
      error(picker_pane)
    end
    context.picker_pane, context.picker_tab = picker_pane:pane_id(), tab:tab_id()
    contexts[tostring(picker_pane:pane_id())] = context
    wezterm.GLOBAL.session_pickers = contexts
    picker_pane:activate()
    tab:set_zoomed(true)
    watch_picker(tostring(picker_pane:pane_id()))
  end)
  if not ok then
    wezterm.log_error(err)
    window:toast_notification("Sessions", tostring(err), nil, 8000)
  end
end

function M.apply(config)
  engine = require("plugins.resurrect.init").get()
  engine.pane_tree.max_nlines = 1
  wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "SESSION_MANAGER" then
      local ok, err = pcall(handle, window, pane, value)
      if not ok then wezterm.log_error("Sessions: " .. tostring(err)) end
    end
  end)
  wezterm.on("update-status", function()
    cleanup_pickers()
    local now = os.time()
    if now < (wezterm.GLOBAL.sessions_next_save or 0) then return end
    wezterm.GLOBAL.sessions_next_save = now + 15
    local ok, err = pcall(function() persist(capture(load())) end)
    if not ok then wezterm.log_error("Sessions autosave: " .. tostring(err)) end
  end)
  table.insert(config.keys, { key = "s", mods = "LEADER", action = wezterm.action_callback(M.open), desc = "Open session picker" })
end

return M
