vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Options =============================================================== {{{1

vim.diagnostic.config {
  virtual_text = { current_line = true },
}

-- Show line numbers.
vim.o.number = true

-- Highlight the line where the cursor is on.
vim.o.cursorline = true

-- Show a live preview of substitutions in a separate split while typing.
vim.o.inccommand = "split"

-- Wrap long lines at word boundaries.
vim.o.linebreak = true

-- Open new splits in predictable locations and preserve the visible text
-- position when a window is resized.
vim.o.splitbelow = true
vim.o.splitkeep = "screen"
vim.o.splitright = true

-- Use spaces instead of tabs for indentation.
vim.o.expandtab = true

-- Use two spaces for indentation.
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = -1

-- Show completion menu for all matches, but don't preselect any item.
vim.o.completeopt = "menuone,noselect,fuzzy,nosort"

-- Ignore case by default, unless the search contains uppercase letters or \C.
vim.o.ignorecase = true
vim.o.smartcase = true

-- Always show the sign column to prevent text from shifting.
vim.o.signcolumn = "yes"

-- Keep some surrounding context visible while scrolling.
vim.o.scrolloff = 6

-- Save undo history across editing sessions.
vim.o.undofile = true

-- Show a border around floating and popupmenu windows.
vim.o.pumborder = "single"
vim.o.winborder = "single"

-- }}}1 // Options

-- Autocommands ========================================================== {{{1

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  desc = "Clear search highlight when cursor moves off the current match",
  callback = function()
    if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
      vim.schedule(function()
        vim.cmd.nohlsearch()
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Automatically enter insert mode in terminal buffers",
  callback = function()
    vim.cmd ":startinsert"
  end,
})

-- }}}1 // Autocommands

-- Keymaps =============================================================== {{{1

-- Move by display lines when no count is provided.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Keep the cursor in place when joining lines.
vim.keymap.set("n", "J", "mzJ`z")

-- Move to the first non-blank character or end of the line.
vim.keymap.set({ "n", "v" }, "L", "$")
vim.keymap.set({ "n", "v" }, "H", "^")

-- Yank text into the system clipboard.
vim.keymap.set({ "n", "v" }, "<Leader>y", [["+y]])
vim.keymap.set("n", "<Leader>Y", [["+Y]])

-- Paste without replacing the contents of the unnamed register.
vim.keymap.set("x", "<Leader>p", [["_dP]])

-- Keep the cursor line centered while navigating.
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<C-n>", "<Cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-p>", "<Cmd>cprev<CR>zz")

-- }}}1 // Keymaps

-- Plugins =============================================================== {{{1

-- Catppuccin ------------------------------------------------------------ {{{2

vim.pack.add {
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
}

require("catppuccin").setup {
  custom_highlights = function(C)
    local U = require "catppuccin.utils.colors"

    return {
      MiniCursorword = { bg = U.darken(C.surface1, 0.7, C.base), style = {} },
      MiniCursorwordCurrent = { link = "MiniCursorword" },
      Visual = { bg = C.surface1, style = {} },
    }
  end,
}

vim.cmd.colorscheme "catppuccin"

-- }}}2 // Catppuccin

-- Indent Blankline ------------------------------------------------------ {{{2

vim.pack.add { "https://github.com/lukas-reineke/indent-blankline.nvim.git" }

require("ibl").setup {
  indent = { char = "▏" },
  scope = { enabled = false },
}

-- }}}2 // Indent Blankline

-- Treesitter ------------------------------------------------------------ {{{2

vim.pack.add { "https://github.com/nvim-treesitter/nvim-treesitter.git" }

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    local _, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
    local installed = require("nvim-treesitter").get_installed "parsers"

    if not lang or not vim.tbl_contains(installed, lang) then
      return
    end

    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- }}}2 // Treesitter

-- Mini ------------------------------------------------------------------ {{{2

vim.pack.add { "https://github.com/nvim-mini/mini.nvim" }

require("mini.ai").setup()
require("mini.cursorword").setup()
require("mini.move").setup()
require("mini.pick").setup()

require("mini.icons").setup()
MiniIcons.tweak_lsp_kind()

require("mini.completion").setup {
  -- Effectively disable signature help.
  delay = { signature = 10 ^ 7 },
}

require("mini.surround").setup {
  mappings = {
    add = "gsa",
    delete = "gsd",
    find = "gsf",
    find_left = "gsF",
    highlight = "gsh",
    replace = "gsr",
  },
}

vim.keymap.set("n", "<Leader><Space>", "<Cmd>Pick files<CR>")
vim.keymap.set("n", "<Leader>sg", "<Cmd>Pick grep_live<CR>")
vim.keymap.set("n", "<Leader>sh", "<Cmd>Pick help<CR>")

-- }}}2 // Mini

-- Oil ------------------------------------------------------------------- {{{2

vim.pack.add { "https://github.com/stevearc/oil.nvim.git" }

require("oil").setup {
  columns = {
    { "permissions", align = "left" },
    { "size", align = "right" },
    { "mtime", align = "left" },
    { "icon", add_padding = false },
  },
  view_options = {
    sort = {
      { "mtime", "desc" },
    },
  },
}

vim.keymap.set("n", "-", "<Cmd>Oil<CR>")
vim.keymap.set("n", "_", "<Cmd>Oil .<CR>")

-- }}}2 // Oil

-- Leap ------------------------------------------------------------------ {{{2

vim.pack.add { "https://codeberg.org/andyg/leap.nvim.git" }

vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
vim.keymap.set("n", "S", "<Plug>(leap-from-window)")

-- }}}2 // Leap

-- Mason ----------------------------------------------------------------- {{{2

vim.pack.add {
  "https://github.com/neovim/nvim-lspconfig.git",
  "https://github.com/mason-org/mason.nvim.git",
  "https://github.com/mason-org/mason-lspconfig.nvim.git",
}

local servers = {
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
          },
        },
        telemetry = { enabled = false },
      },
    },
  },
}

-- Merge extra LSP settings with defaults from nvim-lspconfig.
for name, config in pairs(servers) do
  vim.lsp.config(name, config)
end

require("mason").setup()
require("mason-lspconfig").setup()

-- }}}2 // Mason

-- Conform --------------------------------------------------------------- {{{2

vim.pack.add { "https://github.com/stevearc/conform.nvim" }

require("conform").setup {
  formatters_by_ft = {
    lua = { "stylua" },
  },
}

vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format { async = true, lsp_format = "fallback", range = range }
end, { range = true })

vim.keymap.set({ "n", "v" }, "<Leader>F", "<Cmd>Format<CR>")

-- }}}2 // Conform

-- Autopairs ------------------------------------------------------------- {{{2

vim.pack.add {
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/windwp/nvim-ts-autotag",
}

require("nvim-autopairs").setup()
require("nvim-ts-autotag").setup()

-- }}}2 // Autopairs

-- Gitsigns -------------------------------------------------------------- {{{2

vim.pack.add { "https://github.com/lewis6991/gitsigns.nvim" }

require("gitsigns").setup {
  signs = {
    add = { text = "🮈" },
    change = { text = "🮈" },
  },
  signs_staged = {
    add = { text = "🮈" },
    change = { text = "🮈" },
  },
  current_line_blame_opts = {
    delay = 0,
  },
}

-- }}}2 // Gitsigns

-- }}}1 // Plugins

-- vim: foldmethod=marker foldlevel=0
