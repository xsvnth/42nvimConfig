-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 0
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.number = true
vim.opt.relativenumber = true
vim.api.nvim_create_autocmd("CmdlineEnter", {
  pattern = ":",
  callback = function()
    vim.opt.number = true
    vim.opt.relativenumber = false
  end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  pattern = ":",
  callback = function()
    vim.opt.number = true
    vim.opt.relativenumber = true
  end,
})

vim.g.user42 = "ahmelamr"
vim.g.mail42 = "ahmelamr@student.1337.ma"
