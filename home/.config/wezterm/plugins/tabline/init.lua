local wezterm = require("wezterm")

local M = {}

local function tab_label(process, tab)
  return tab.tab_title and tab.tab_title ~= "" and tab.tab_title or process
end

function M.apply(config)
  local colors = config.colors
  local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
  tabline.setup({
    options = {
      icons_enabled = false,
      theme = colors,
      tabs_enabled = true,
      section_separators = "",
      component_separators = "",
      tab_separators = "",
      theme_overrides = {
        normal_mode = {
          a = { fg = colors.ansi[5], bg = colors.ansi[1] },
          b = { fg = colors.foreground, bg = colors.ansi[1] },
          c = { fg = colors.foreground, bg = colors.background },
        },
        tab = {
          active = { fg = colors.ansi[5], bg = colors.selection_bg },
          inactive = { fg = colors.brights[1], bg = colors.background },
          inactive_hover = { fg = colors.selection_fg, bg = colors.ansi[1] },
        },
      },
    },
    sections = {
      tabline_a = { "workspace" },
      tabline_b = {},
      tabline_c = { " " },
      tab_active = { "index", { "process", fmt = tab_label, padding = { left = 0, right = 1 } }, "zoomed" },
      tab_inactive = { "index", { "process", fmt = tab_label, padding = { left = 0, right = 1 } } },
      tabline_x = {},
      tabline_y = { { "datetime", style = "%H:%M" } },
      tabline_z = {},
    },
    extensions = {},
  })
  local padding = {}
  for side, value in pairs(config.window_padding) do
    padding[side] = value
  end
  local tab_max_width = config.tab_max_width
  tabline.apply_to_config(config)
  -- Tabline also applies layout defaults; keep the main config's geometry.
  config.window_padding = padding
  config.tab_max_width = tab_max_width
end

function M.fallback(_config)
  wezterm.on("update-right-status", function(window)
    local leader = window:leader_is_active() and "LEADER  " or ""
    local status = leader .. window:active_workspace() .. "  " .. wezterm.strftime("%H:%M")
    window:set_right_status(" " .. status .. " ")
  end)
end

return M
