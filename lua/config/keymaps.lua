-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>un", function()
  vim.opt.number = not vim.opt.number
end, { desc = "Toggle absolute line numbers" })

-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", {
  noremap = true,
  silent = true,
  desc = "Exit terminal mode",
})
