if vim.g.vscode then
  return
end

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

--stylua: ignore start
-- OPTIONS ==========================================================
vim.g.mapleader = " " -- Use <Space> as the leader key

vim.o.mouse    = "a"  -- Enable mouse support
vim.o.undofile = true -- Persist undo history across sessions

vim.o.breakindent = true   -- Indent wrapped lines to match line start
vim.o.cursorline  = true   -- Highlight the current cursor line
vim.o.linebreak   = true   -- Wrap lines at 'breakat' (if 'wrap' is set)
vim.o.number      = true   -- Show line numbers
vim.o.rnu         = true   -- Show relative line numbers
vim.o.winborder   = "bold" -- Show borders around floating windows
vim.o.wrap        = false  -- Don't visually wrap lines (toggle with \w)

vim.o.listchars = "tab:» ,trail:⋅,nbsp:␣"

vim.o.expandtab  = true    -- Use spaces instead of <Tab> characters
vim.o.ignorecase = true    -- Ignore case in search patterns
vim.o.inccommand = "split" -- Preview substitutions, including partial off-screen results
vim.o.shiftwidth = 2       -- Indent width for >>, <<, and 'autoindent'
vim.o.smartcase  = true    -- Override 'ignorecase' if search has capitals
vim.o.tabstop    = 4       -- Number of spaces that a <Tab> counts for
--stylua: ignore end

-- STATUSCOLUMN =====================================================
vim.o.statuscolumn = "%!v:lua.StatusColumn()"

function _G.StatusColumn()
  local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local row = vim.v.lnum - 1 -- extmark uses 0-based line indices
  local sign, git = "  ", "  "
  local marks = vim.api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, { details = true, type = "sign" })

  for _, mark in ipairs(marks) do
    local details = mark[4]
    local hl_group = details.sign_hl_group or ""
    local text = details.sign_text or "  "

    if hl_group:find("GitSign") then
      git = "%#" .. hl_group .. "#" .. text .. "%*"
    elseif hl_group ~= "" then
      sign = "%#" .. hl_group .. "#" .. text .. "%*"
    else
      sign = text
    end
  end

  return sign .. "%l " .. git
end

-- AUTOCOMMANDS =====================================================
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  desc = "Don't auto-wrap comments or insert comment leader after hitting 'o'",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "o" })
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight text when yanked",
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  desc = "Disable search highlighting when there's no match under cursor",
  callback = function()
    if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
      vim.schedule(function()
        vim.cmd.nohlsearch()
      end)
    end
  end,
})

-- KEYMAPS ==========================================================
vim.keymap.set({ "i", "n", "v" }, "<C-c>", "<Esc>", { noremap = true, silent = true })

vim.keymap.set("n", "\\w", ":set wrap!<CR>", { desc = "Toggle line wrap" })

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank text into system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank current line into system clipboard" })

vim.keymap.set("n", "<C-j>", "<Cmd>cnext<CR>zz", { desc = "Display the next item in the quickfix list" })
vim.keymap.set("n", "<C-k>", "<Cmd>cprev<CR>zz", { desc = "Display the previous item in the quickfix list" })

-- Remap j/k to behave more naturally (move by screen line) with wrapped lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- PLUGINS ==========================================================
require("lazy").setup({
  spec = {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        require("catppuccin").setup({
          custom_highlights = function(colors)
            return {
              IblIndent = { fg = colors.surface1 },
              IblScope = { fg = colors.surface2 },
              MiniCursorword = { bg = colors.surface0, style = {} },
              MiniCursorwordCurrent = { bg = colors.surface0, style = {} },
              Visual = { bg = colors.surface0, style = {} },
            }
          end,
        })

        vim.cmd.colorscheme("catppuccin-latte")
      end,
    },
    {
      "https://codeberg.org/andyg/leap.nvim.git",
      config = function()
        require("leap").opts.preview = function(ch0, ch1, ch2)
          return not (ch1:match("%s") or (ch0:match("%a") and ch1:match("%a") and ch2:match("%a")))
        end

        vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
        vim.keymap.set("n", "S", "<Plug>(leap-from-window)")
      end,
    },
    {
      "lewis6991/gitsigns.nvim",
      opts = {
        signs = {
          add = { text = "▍" },
          change = { text = "▍" },
        },
        signs_staged = {
          add = { text = "▍" },
          change = { text = "▍" },
        },
      },
    },
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      opts = {
        indent = { char = "▏" },
        scope = { show_start = false },
      },
    },
    {
      "mason-org/mason-lspconfig.nvim",
      dependencies = {
        "neovim/nvim-lspconfig",
        { "mason-org/mason.nvim", opts = {} },
      },
      opts = {
        servers = {
          lua_ls = {},
          tsgo = {},
        },
      },
      config = function(_, opts)
        require("mason-lspconfig").setup({
          ensure_installed = vim.tbl_keys(opts.servers),
        })

        vim.api.nvim_create_autocmd("LspAttach", {
          -- stylua: ignore
          callback = function(ev)
            vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { buffer = ev.buf, desc = "Go to definition" })
            vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, { buffer = ev.buf, desc = "Go to declaration" })
            vim.keymap.set("n", "gr", function() MiniExtra.pickers.lsp({ scope = 'references' }) end, { buffer = ev.buf, desc = "Go to references" })
          end,
        })
      end,
    },
    {
      "nvim-mini/mini.nvim",
      lazy = false,
      -- stylua: ignore
      keys = {
        { "<leader>fb", function() MiniPick.builtin.buffers() end, desc = "Buffers" },
        { "<leader>ff", function() MiniPick.builtin.files() end, desc = "Find files" },
        { "<leader>sg", function() MiniPick.builtin.grep_live() end, desc = "Grep" },
        { "<leader>sh", function() MiniPick.builtin.help() end, desc = "Help pages" },
      },
      config = function()
        require("mini.ai").setup()
        require("mini.cursorword").setup()
        require("mini.extra").setup()
        require("mini.icons").setup()
        require("mini.pick").setup()

        require("mini.surround").setup({
          mappings = {
            add = "gsa",
            delete = "gsd",
            find = "gsf",
            find_left = "gsF",
            highlight = "gsh",
            replace = "gsr",
          },
        })
      end,
    },
    {
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      build = ":TSUpdate",
      opts = {
        parsers = { "javascript", "json", "lua", "typescript" },
      },
      config = function(_, opts)
        require("nvim-treesitter").install(opts.parsers, { summary = true })

        vim.api.nvim_create_autocmd("FileType", {
          callback = function(ev)
            local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)

            if not lang or not vim.tbl_contains(opts.parsers, lang) then
              return
            end

            if pcall(vim.treesitter.start, ev.buf) then
              -- Enable treesitter-based indentation
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end,
        })
      end,
    },
    {
      "saghen/blink.cmp",
      version = "1.*",
      event = "VimEnter",
      opts = {
        appearance = { nerd_font_variant = "normal" },
      },
      opts_extend = { "sources.default" },
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
