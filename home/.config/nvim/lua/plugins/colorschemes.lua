-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {
  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
  },
  { "RRethy/base16-nvim", lazy = false, priority = 1000 },
  {
    "rose-pine/neovim",
    name = "rose-pine",
  },
  {
    "jpwol/thorn.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
    },
  },
}
