if false then
  return {}
end

return {
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
  },
  -- {
  --   "MeanderingProgrammer/render-markdown.nvim",
  --   ft = { "markdown" },
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  -- },
}
