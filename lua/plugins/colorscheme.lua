return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night", -- or "storm" / "moon"
      on_colors = function(colors)
        -- Change the main background to dark red
        colors.bg = "#1a0b10"
        colors.bg_dark = "#14080c"
        colors.bg_float = "#14080c"
        colors.bg_sidebar = "#14080c"
        colors.bg_popup = "#14080c"
        colors.bg_statusline = "#241017"

        -- Keep statusline accent dark red
        colors.blue = "#a82a3e"
        colors.blue1 = "#c53b53"
        colors.blue2 = "#8b263e"
      end,
      on_highlights = function(hl, c)
        -- Dark red active line highlight
        hl.CursorLine = { bg = "#33121b" }
        hl.CursorLineNr = { fg = "#e05f65", bold = true }
        hl.LineNr = { fg = "#7a303e" }
        hl.LineNrAbove = { fg = "#7a303e" }
        hl.LineNrBelow = { fg = "#7a303e" }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
