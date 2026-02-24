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
    "nvim-mini/mini.comment",
    version = false,
    config = function()
      require("mini.comment").setup()
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.jump",
    version = false,
    config = function()
      require("mini.jump").setup()
    end,
    cond = vim.g.vscode or true,
  },
  {
    "nvim-mini/mini.move",
    version = false,
    config = function()
      require("mini.move").setup({
        mappings = {
          left = "<C-h>",
          right = "<C-l>",
          down = "<C-j>",
          up = "<C-k>",

          line_left = "<C-h>",
          line_right = "<C-l>",
          line_down = "<C-j>",
          line_up = "<C-k>",
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
      require("mini.surround").setup()
    end,
    cond = vim.g.vscode or true,
  },
}
