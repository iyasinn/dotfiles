-- Run with WezTerm's Lua runtime; the mux and filesystem state are isolated.
return function(real, directory)
  local recovery = require("plugins.sessions.recovery")
  local count = 0
  local function test(name, fn)
    fn()
    count = count + 1
    print("PASS " .. name)
  end
  local function snapshot(n)
    local tree = { cwd = "/tmp" }
    if n == 2 then tree.right = { cwd = "/tmp" } end
    return { workspace = "default", window_states = {
      { tabs = { { pane_tree = tree } }, size = { cols = 80, rows = 24 } },
    } }
  end
  local function state(n)
    return { version = 1, sessions = { default = { snapshot = snapshot(n) } } }
  end
  local windows = {}
  local function window(name, n, domain)
    local win = { name = name }
    function win:get_workspace() return self.name end
    function win:tabs()
      return { { panes = function() local panes = {}; for i = 1, n do panes[i] = { get_domain_name = function() return domain or "local" end } end; return panes end } }
    end
    return win
  end
  local wezterm = {
    GLOBAL = {}, json_parse = real.json_parse, json_encode = real.json_encode,
    run_child_process = real.run_child_process, log_warn = function() end,
    mux = {
      all_windows = function() return windows end,
      rename_workspace = function(old, new)
        for _, win in ipairs(windows) do if win.name == old then win.name = new end end
      end,
    },
  }
  test("startup preserves saved layout and running workspace", function()
    local saved = state(2)
    windows = { window("default", 1) }
    recovery.protect_startup(wezterm, saved)
    assert(windows[1].name == "default (current)")
    assert(saved.sessions.default.snapshot.window_states[1].tabs[1].pane_tree.right)
    recovery.protect_startup(wezterm, saved)
    assert(windows[1].name == "default (current)", "reload must not rename again")
  end)
  test("reconnecting to the same mux instance preserves workspace names", function()
    wezterm.GLOBAL.sessions_recovery_checked = {}
    local saved = state(2)
    saved.sessions.default.mux_instance = "server-1"
    windows = { window("default", 2, "unix") }
    recovery.protect_startup(wezterm, saved, { name = "unix", instance = "server-1" })
    assert(windows[1].name == "default")
  end)
  test("a restarted server cannot overwrite the previous layout", function()
    wezterm.GLOBAL.sessions_recovery_checked = {}
    local saved = state(2)
    saved.sessions.default.mux_instance = "server-1"
    windows = { window("default", 1, "unix") }
    recovery.protect_startup(wezterm, saved, { name = "unix", instance = "server-2" })
    assert(windows[1].name == "default (current)")
    assert(saved.sessions.default.snapshot.window_states[1].tabs[1].pane_tree.right)
  end)
  test("attaching after local startup still checks mux identity", function()
    wezterm.GLOBAL.sessions_recovery_checked = { ["local"] = true }
    local saved = state(2)
    windows = { window("default", 1, "unix") }
    recovery.protect_startup(wezterm, saved, { name = "unix", instance = "server-3" })
    assert(windows[1].name == "default (current)")
  end)
  test("partial restore remains excluded and original stays unchanged", function()
    local saved = state(2)
    local before = real.json_encode(saved)
    local engine = { workspace_state = { restore_workspace = function(s)
      windows[#windows + 1] = window(s.workspace, 1)
      s.window_states[1].tabs[1].pane_tree.pane = "engine mutation"
    end } }
    assert(not pcall(recovery.restore, wezterm, engine, saved, "default"))
    assert(wezterm.GLOBAL.sessions_excluded[windows[#windows].name])
    assert(real.json_encode(saved) == before)
  end)
  test("retry publishes only a complete restored workspace", function()
    local engine = { workspace_state = { restore_workspace = function(s)
      windows[#windows + 1] = window(s.workspace, 2)
    end } }
    recovery.restore(wezterm, engine, state(2), "default")
    assert(windows[#windows].name == "default")
    assert(not wezterm.GLOBAL.sessions_excluded.default)
  end)
  test("legacy local tab domains migrate to the server without changing the saved copy", function()
    local saved = state(2)
    saved.sessions.default.snapshot.window_states[1].tabs[1].pane_tree.domain = "local"
    local engine = { workspace_state = { restore_workspace = function(s)
      local tree = s.window_states[1].tabs[1].pane_tree
      assert(tree.domain == "unix" and tree.right.domain == "unix")
      windows[#windows + 1] = window(s.workspace, 2, "unix")
    end } }
    recovery.restore(wezterm, engine, saved, "default", "unix")
    assert(saved.sessions.default.snapshot.window_states[1].tabs[1].pane_tree.domain == "local")
  end)
  local path = directory .. "/index.json"
  local store = recovery.new(wezterm, path)
  test("saves round-trip", function()
    local saved = state(1); saved.marker = 7; store.persist(saved)
    assert(store.load().marker == 7)
  end)
  test("oversized writes preserve previous state", function()
    local saved = state(1); saved.large = string.rep("x", 2 * 1024 * 1024)
    assert(not pcall(store.persist, saved))
    assert(store.load().marker == 7)
  end)
  test("corrupt state fails instead of resetting", function()
    local bad = directory .. "/bad.json"
    local file = assert(io.open(bad, "w")); file:write("broken JSON"); file:close()
    assert(not pcall(recovery.new(wezterm, bad).load))
  end)
  print(tostring(count) .. " session recovery tests passed")
end
