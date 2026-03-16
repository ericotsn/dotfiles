-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before loading
-- lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.textwidth = 70

vim.keymap.set({ "i", "n", "s" }, "<Esc>", function()
  vim.cmd("noh")
  return "<Esc>"
end, { expr = true, silent = true })

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      "saghen/blink.cmp",
      version = "1.*",
      opts = {
        appearance = { nerd_font_variant = "normal" },
      },
      opts_extend = { "sources.default" },
    },
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        require("catppuccin").setup()

        vim.cmd.colorscheme("catppuccin-latte")
      end,
      cond = vim.g.vscode or true,
    },
    {
      "folke/flash.nvim",
      event = "VeryLazy",
      -- stylua: ignore
      keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end },
      },
      cond = vim.g.vscode or true,
    },
    {
      "nvim-mini/mini.nvim",
      config = function()
        require("mini.ai").setup()

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
  },
  defaults = {
    -- stylua: ignore
    cond = function() return not vim.g.vscode end,
  },
})
