local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
  tabline.setup({
    options = {
      icons_enabled = false,
      theme = "Tokyo Night",
      tabs_enabled = true,
      section_separators = "",
      component_separators = "",
      tab_separators = "",
      theme_overrides = {
        normal_mode = {
          a = { fg = "#c084fc", bg = "#111827" },
          b = { fg = "#9ca3af", bg = "#111827" },
          c = { fg = "#9ca3af", bg = "#080b12" },
        },
        tab = {
          active = { fg = "#e6edf3", bg = "#1f2937" },
          inactive = { fg = "#6b7280", bg = "#080b12" },
          inactive_hover = { fg = "#e6edf3", bg = "#111827" },
        },
      },
    },
    sections = {
      tabline_a = { "workspace" },
      tabline_b = {},
      tabline_c = { " " },
      tab_active = { "index", { "process", padding = { left = 0, right = 1 } }, "zoomed" },
      tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
      tabline_x = {},
      tabline_y = { { "datetime", style = "%H:%M" } },
      tabline_z = {},
    },
    extensions = {},
  })
  tabline.apply_to_config(config)
end

function M.fallback(_config)
  wezterm.on("update-right-status", function(window)
    local leader = window:leader_is_active() and "LEADER  " or ""
    local status = leader .. window:active_workspace() .. "  " .. wezterm.strftime("%H:%M")
    window:set_right_status(" " .. status .. " ")
  end)
end

return M
