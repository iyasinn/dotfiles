-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--#region

-- escape module

vim.keymap.set("i", "kj", "<Esc>", { noremap = true })
vim.keymap.set("i", "jk", "<Esc>", { noremap = true })
vim.keymap.set("i", "jj", "<Esc>", { noremap = true })

-- window keymaps

vim.keymap.set("n", "<A-h>", "<cmd>vertical resize -5<cr>", { desc = "Decrease width" })
vim.keymap.set("n", "<A-l>", "<cmd>vertical resize +5<cr>", { desc = "Increase width" })
vim.keymap.set("n", "<A-k>", "<cmd>resize +5<cr>", { desc = "Increase height" })
vim.keymap.set("n", "<A-j>", "<cmd>resize -5<cr>", { desc = "Decrease height" })

-- markdown toggle
vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")

-- Smart-splits
local ss = require("smart-splits")
vim.keymap.set("n", "<C-h>", ss.move_cursor_left)
vim.keymap.set("n", "<C-j>", ss.move_cursor_down)
vim.keymap.set("n", "<C-k>", ss.move_cursor_up)
vim.keymap.set("n", "<C-l>", ss.move_cursor_right)
vim.keymap.set("n", "<A-h>", ss.resize_left)
vim.keymap.set("n", "<A-j>", ss.resize_down)
vim.keymap.set("n", "<A-k>", ss.resize_up)
vim.keymap.set("n", "<A-l>", ss.resize_right)
