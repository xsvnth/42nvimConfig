return {
  "42Paris/42header",
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd("BufNewFile", {
      pattern = { "*.c", "*.h" },
      callback = function()
        vim.cmd("Stdheader")
      end,
    })
  end,
}
