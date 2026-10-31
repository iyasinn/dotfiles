-- The background server has no GUI plugins or picker timers.
local wezterm = require("wezterm")
local persistent = require("plugins.persistent")
local config = wezterm.config_builder()
config.unix_domains = { { name = persistent.name, socket_path = persistent.socket } }
config.default_mux_server_domain = "local"
config.term = "xterm-256color"
config.scrollback_lines = 20000
config.check_for_updates = false
-- Do not pass an automation launcher's color-disable flag to interactive shells.
-- Keep WezTerm's default removals as well. Applied when the server starts.
config.mux_env_remove = { "SSH_AUTH_SOCK", "SSH_CLIENT", "SSH_CONNECTION", "NO_COLOR" }

wezterm.on("mux-startup", function()
  local ok, _, err = wezterm.run_child_process({ "mkdir", "-p", persistent.directory })
  assert(ok, err)
  local file = assert(io.open(persistent.instance_path .. ".tmp", "w"))
  file:write(tostring(wezterm.procinfo.pid()) .. ":" .. tostring(os.time()))
  file:close()
  assert(os.rename(persistent.instance_path .. ".tmp", persistent.instance_path))
end)

return config
