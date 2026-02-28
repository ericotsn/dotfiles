return {
  {
    "nvim-mini/mini.ai",
    version = false,
    config = function()
      require("mini.ai").setup()
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.basics",
    version = false,
    config = function()
      require("mini.basics").setup()
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.comment",
    version = false,
    config = function()
      require("mini.comment").setup()
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.move",
    version = false,
    config = function()
      require("mini.move").setup({
        mappings = {
          -- Move visual selection in Visual mode
          left = "<M-Left>",
          right = "<M-Right>",
          down = "<M-Down>",
          up = "<M-Up>",

          -- Move current line in Normal mode
          line_left = "<M-Left>",
          line_right = "<M-Right>",
          line_down = "<M-Down>",
          line_up = "<M-Up>",
        },
      })
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.pairs",
    version = false,
    config = function()
      require("mini.pairs").setup()
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.surround",
    version = false,
    config = function()
      require("mini.surround").setup({
        mappings = {
          add = "gsa", -- Add surrounding in Normal and Visual modes
          delete = "gsd", -- Delete surrounding
          find = "gsf", -- Find surrounding (to the right)
          find_left = "gsF", -- Find surrounding (to the left)
          highlight = "gsh", -- Highlight surrounding
          replace = "gsr", -- Replace surrounding
        },
      })
    end,
    cond = vim.g.vscode or true,
  },
}
