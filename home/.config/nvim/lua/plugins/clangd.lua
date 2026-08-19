return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.servers = opts.servers or {}

    opts.servers.clangd = vim.tbl_deep_extend("force", opts.servers.clangd or {}, {
      cmd = {
        "/opt/homebrew/opt/llvm@20/bin/clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      },
    })
  end,
}
