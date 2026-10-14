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
      -- Use the installed Symbols Nerd Font for a restrained powerline shape.
      section_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thick,
        right = wezterm.nerdfonts.ple_left_half_circle_thick,
      },
      component_separators = {
        left = wezterm.nerdfonts.pl_right_soft_divider,
        right = wezterm.nerdfonts.pl_left_soft_divider,
      },
      tab_separators = {
        left = wezterm.nerdfonts.pl_right_hard_divider,
        right = wezterm.nerdfonts.pl_left_hard_divider,
      },
      theme_overrides = {
        normal_mode = {
          a = { fg = colors.background, bg = colors.ansi[5], bold = true },
          b = { fg = colors.brights[7], bg = colors.split },
          c = { fg = colors.foreground, bg = colors.background },
        },
        tab = {
          active = { fg = colors.brights[7], bg = colors.selection_bg, bold = true },
          inactive = { fg = colors.brights[7], bg = colors.ansi[1] },
          inactive_hover = { fg = colors.selection_fg, bg = colors.split },
        },
      },
    },
    sections = {
      tabline_a = { { "workspace", padding = { left = 1, right = 1 } } },
      tabline_b = {},
      tabline_c = { " " },
      tab_active = {
        "index",
        { "process", fmt = tab_label, padding = { left = 1, right = 2 } },
        "zoomed",
      },
      tab_inactive = {
        "index",
        { "process", fmt = tab_label, padding = { left = 1, right = 2 } },
      },
      tabline_x = {},
      tabline_y = { { "datetime", style = "%H:%M", padding = { left = 2, right = 1 } } },
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
