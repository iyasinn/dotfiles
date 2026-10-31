local wezterm = require("wezterm")
local M = { name = "unix" }
M.directory = (os.getenv("XDG_STATE_HOME") or (wezterm.home_dir .. "/.local/state")) .. "/wezterm"
M.socket = M.directory .. "/mux.sock"
M.instance_path = M.directory .. "/mux-instance"

function M.instance()
  local file = io.open(M.instance_path, "r")
  if not file then return nil end
  local value = file:read("*a")
  file:close()
  return value ~= "" and value or nil
end

function M.domain()
  local domain = wezterm.mux.get_domain(M.name)
  assert(domain, "Persistent mux domain is not configured")
  if domain:state() ~= "Attached" then domain:attach() end
  return { DomainName = M.name }
end

function M.apply(config)
  config.unix_domains = {
    {
      name = M.name,
      socket_path = M.socket,
      serve_command = { wezterm.executable_dir .. "/wezterm-mux-server", "--config-file",
        wezterm.config_dir .. "/mux-server.lua", "--daemonize" },
    },
  }
  config.default_domain = M.name
  config.default_gui_startup_args = { "connect", M.name }
end

return M
