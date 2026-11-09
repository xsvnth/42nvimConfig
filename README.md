# 42nvimConfig

LazyVim-based Neovim config for 42 students. On `:w`, C files get formatted the 42 way.

## Features

- 42 header added automatically to new `.c` and `.h` files (42header)
- Format on save for `.c` and `.h` files:
  - one declaration per line, a blank line, then the assignments
  - tabs, spaces and alignment (c_formatter_42)
  - `&&` / `||` spacing, and parentheses around `&&` groups mixed with `||`
  - long `if` / `while` conditions wrapped before `&&` / `||`
  - comma statements like `i++, n--;` split, with braces added under a braceless `if` / `while`
  - strings are never touched
- Tokyonight theme with a dark red palette

## Requirements

- Neovim 0.10+
- git
- Python 3 with pip
- `c_formatter_42`

## Install

```
git clone git@github.com:xsvnth/42nvimConfig.git ~/.config/nvim
python3 -m pip install --user c_formatter_42
```

Make sure `~/.local/bin` is in your PATH, then open `nvim` and let lazy.nvim install the plugins.

Set your login and email in `lua/config/options.lua`:

```lua
vim.g.user42 = "your_login"
vim.g.mail42 = "your_login@student.1337.ma"
```

## What it does not fix

The formatter handles layout only. You still fix these by hand: functions over 25 lines, more than 5 functions per file, more than 4 parameters, typedefs in `.c` files, global variables, and `for` loops.

## Files

- `lua/plugins/formatter.lua`: the formatter (conform.nvim + c_formatter_42)
- `lua/plugins/header.lua`: 42 header
