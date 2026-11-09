return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.sections.lualine_x = {
        {
          function()
            return "☣ xsvnth"
          end,
          color = { fg = "#ff5555", gui = "bold" },
        },
      }
    end,
  },
}
