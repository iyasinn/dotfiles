local wezterm = require("wezterm")

-- Session-picker artwork lives here; the session manager only forwards it.
local M = {
  enabled = true,
  path = wezterm.config_dir .. "/plugins/sessions/art/floating-island.gif",
  height = 10, -- Terminal rows reserved above the search field.
  min_rows = 26,
  min_columns = 30,
}

function M.environment()
  return {
    SESSION_ART_PATH = M.enabled and M.path or "",
    SESSION_ART_HEIGHT = tostring(M.height),
    SESSION_ART_MIN_ROWS = tostring(M.min_rows),
    SESSION_ART_MIN_COLUMNS = tostring(M.min_columns),
  }
end

return M
