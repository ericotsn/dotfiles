return {
  "nvim-mini/mini.nvim",
  version = false,
  config = function()
    require("mini.ai").setup()
    require("mini.basics").setup()
    require("mini.comment").setup()
    require("mini.jump").setup()
    require("mini.move").setup()
    require("mini.pairs").setup()
    require("mini.surround").setup()
  end,
  cond = vim.g.vscode or true,
}
