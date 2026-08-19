if false then
  return {}
end

return {
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    opts = {
      extra_groups = {
        "NormalFloat",
        "NeoTreeNormal",
        "NeoTreeNormalNC",
      },
    },
    keys = {
      { "<leader>uo", "<cmd>TransparentToggle<cr>", desc = "Toggle Transparency" },
      -- or use a different one:
      -- { "<leader>ub", "<cmd>TransparentToggle<cr>", desc = "Toggle Background" },
    },
  },
}
