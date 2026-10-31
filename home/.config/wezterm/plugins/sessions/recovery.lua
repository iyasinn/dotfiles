-- Persistence and restore guards, separate from the picker UI.
local M = {}
local MAX_BYTES = 2 * 1024 * 1024

function M.new(wezterm, path)
  local store = {}
  local function read(file)
    local handle, err, code = io.open(file, "rb")
    if not handle then
      assert(code == 2, err) -- Only a missing file is an empty state.
      return nil
    end
    local text = handle:read(MAX_BYTES + 1)
    handle:close()
    assert(#text <= MAX_BYTES, "Session state exceeds 2 MiB: " .. file)
    local state = wezterm.json_parse(text)
    assert(type(state) == "table" and state.version == 1 and type(state.sessions) == "table",
      "Unsupported session state: " .. file)
    for name, entry in pairs(state.sessions) do
      assert(type(name) == "string" and type(entry) == "table" and type(entry.snapshot) == "table"
        and type(entry.snapshot.window_states) == "table", "Invalid saved session: " .. tostring(name))
    end
    return state, text
  end
  local function write(file, text)
    local handle = assert(io.open(file .. ".tmp", "wb"))
    assert(handle:write(text))
    assert(handle:close())
    assert(os.rename(file .. ".tmp", file))
  end
  function store.load()
    -- A corrupt file stops loading rather than silently resetting to empty.
    return read(path) or { version = 1, sessions = {} }
  end
  function store.persist(state)
    local text = wezterm.json_encode(state)
    assert(#text <= MAX_BYTES, "Session state exceeds 2 MiB; previous save was kept")
    local ok, _, err = wezterm.run_child_process({ "mkdir", "-p", path:match("^(.*)/") })
    assert(ok, err)
    write(path, text)
  end
  return store
end

function M.unique_name(wezterm, state, base)
  local used = {}
  for name in pairs(state.sessions) do used[name] = true end
  for _, win in ipairs(wezterm.mux.all_windows()) do used[win:get_workspace()] = true end
  local name, i = base, 2
  while used[name] do name = base .. " " .. i; i = i + 1 end
  return name
end

function M.protect_startup(wezterm, state, persistent)
  local checked = wezterm.GLOBAL.sessions_recovery_checked or {}
  local groups, workspaces = {}, {}
  for _, win in ipairs(wezterm.mux.all_windows()) do
    local managed = false
    if persistent then
      for _, tab in ipairs(win:tabs()) do
        for _, pane in ipairs(tab:panes()) do
          if pane:get_domain_name() == persistent.name then managed = true end
        end
      end
    end
    workspaces[win:get_workspace()] = workspaces[win:get_workspace()] or managed
  end
  for name, managed in pairs(workspaces) do
    local key = managed and ("mux:" .. (persistent.instance or "unknown")) or "local"
    if not checked[key] then
      groups[key] = groups[key] or {}
      groups[key][name] = managed
    end
  end
  for key, names in pairs(groups) do
    for name, managed in pairs(names) do
      local saved = state.sessions[name]
      local reconnect = managed and persistent.instance and saved
        and saved.mux_instance == persistent.instance
      if saved and not reconnect then
        local replacement = M.unique_name(wezterm, state, name .. " (current)")
        wezterm.mux.rename_workspace(name, replacement)
        local contexts = wezterm.GLOBAL.session_pickers or {}
        for _, context in pairs(contexts) do
          if context.workspace == name then context.workspace = replacement end
        end
        wezterm.GLOBAL.session_pickers = contexts
      end
    end
    checked[key] = true
  end
  wezterm.GLOBAL.sessions_recovery_checked = checked
end

local function pane_count(tree)
  if not tree then return 0 end
  return 1 + pane_count(tree.right) + pane_count(tree.bottom)
end

function M.restore(wezterm, engine, state, name, domain)
  -- The engine mutates its input and swallows some errors. Restore a copy in
  -- a separate workspace; only publish it under the saved name after checking.
  local snapshot = wezterm.json_parse(wezterm.json_encode(state.sessions[name].snapshot))
  local temporary = M.unique_name(wezterm, state, name .. " (incomplete restore)")
  snapshot.workspace = temporary
  -- Old local layouts now restore into the background server. Splits inherit
  -- their parent's domain; tab roots need the same domain explicitly.
  local function migrate(tree)
    if not tree then return end
    if domain and (not tree.domain or tree.domain == "local" or tree.domain == "unix") then
      tree.domain = domain
    end
    migrate(tree.right)
    migrate(tree.bottom)
  end
  for _, window in ipairs(snapshot.window_states) do
    for _, tab in ipairs(window.tabs) do migrate(tab.pane_tree) end
  end
  local excluded = wezterm.GLOBAL.sessions_excluded or {}
  excluded[temporary] = true
  wezterm.GLOBAL.sessions_excluded = excluded
  local expected = {}
  for _, window in ipairs(snapshot.window_states) do
    local tabs = {}
    for _, tab in ipairs(window.tabs) do tabs[#tabs + 1] = pane_count(tab.pane_tree) end
    expected[#expected + 1] = table.concat(tabs, ",")
  end
  assert(#expected > 0, "Saved session has no windows")
  engine.workspace_state.restore_workspace(snapshot, { relative = true, switch_workspace = false })
  local actual = {}
  for _, win in ipairs(wezterm.mux.all_windows()) do
    if win:get_workspace() == temporary then
      local tabs = {}
      for _, tab in ipairs(win:tabs()) do tabs[#tabs + 1] = #tab:panes() end
      actual[#actual + 1] = table.concat(tabs, ",")
    end
  end
  table.sort(expected)
  table.sort(actual)
  assert(table.concat(expected, ";") == table.concat(actual, ";"),
    "Restore was incomplete; the original save is safe. Close the incomplete workspace and retry.")
  wezterm.mux.rename_workspace(temporary, name)
  excluded = wezterm.GLOBAL.sessions_excluded or {}
  excluded[temporary] = nil
  wezterm.GLOBAL.sessions_excluded = excluded
end

return M
