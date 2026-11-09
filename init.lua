-- bootstrap lazy.nvim, LazyVim and your plugins
-- ttom terminal with Ctrl + Space
require("config.lazy")

-- Toggle bottom terminal with Ctrl + Space
local term_win = nil
vim.o.shell = vim.fn.exepath("fish")
vim.keymap.set("n", "<F5>", function()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
    term_win = nil
  else
    vim.cmd("belowright 10split")
    vim.cmd("terminal")
    term_win = vim.api.nvim_get_current_win()
    vim.cmd("startinsert")
  end
end, { desc = "Toggle bottom terminal" })
