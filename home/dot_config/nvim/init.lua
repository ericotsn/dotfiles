if vim.g.vscode then
  return
end

-- [[ Options ]] ==============================================================

vim.g.mapleader = " " -- Use space as the one and only true Leader key

-- General
vim.o.mouse = "a" -- Enable mouse support for all available modes
vim.o.undofile = true -- Enable persistent undo (see also `:h undodir`)
vim.o.writebackup = false -- Disable write backups to preserve inodes

-- Appearance
vim.o.colorcolumn = "+1" -- Highlight column after 'textwidth'
vim.o.cursorline = true -- Highlight current line
vim.o.linebreak = true -- Wrap long lines at 'breakat' (if 'wrap' is set)
vim.o.number = true -- Show absolute line numbers
vim.o.splitbelow = true -- Open horizontal splits below
vim.o.splitkeep = "screen" -- Keep screen contents stable when splitting
vim.o.splitright = true -- Open vertical splits to the right
vim.o.winborder = "rounded" -- Use rounded borders for floating windows

-- Editing
vim.o.expandtab = true -- Convert tabs to spaces
vim.o.ignorecase = true -- Ignore case when searching (UNLESS `\C` or uppercase)
vim.o.inccommand = "split" -- Show substitution previews in a split window
vim.o.shiftwidth = 4 -- Number of spaces to use for each step of indentation
vim.o.smartcase = true -- Override 'ignorecase' if search pattern contains uppercase
vim.o.tabstop = 4 -- Number of spaces each tab counts for

vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "‼",
      [vim.diagnostic.severity.WARN] = "!",
      [vim.diagnostic.severity.INFO] = "⁇",
      [vim.diagnostic.severity.HINT] = "?",
    },
  },
  virtual_text = {
    current_line = true,
    severity = vim.diagnostic.severity.ERROR,
  },
}

-- Custom 'statuscolumn' for Neovim
vim.o.statuscolumn = "%!v:lua.StatusColumn()"

function _G.StatusColumn()
  local row = vim.v.lnum - 1 -- The extmark API is 0-based
  local buffer = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { row, 0 }, { row, -1 }, { details = true, type = "sign" })
  local sign, git = "  ", " "

  for _, mark in ipairs(marks) do
    local d = mark[4]
    local hl = d.sign_hl_group or ""

    if hl:find("GitSign", 1, true) then
      git = "%#" .. hl .. "#" .. vim.fn.strcharpart(d.sign_text or " ", 0, 1) .. "%*"
    elseif hl ~= "" then
      sign = "%#" .. hl .. "#" .. (d.sign_text or "  ") .. "%*"
    else
      sign = d.sign_text or "  "
    end
  end

  return sign .. "%l " .. git .. "%C "
end

-- Custom 'statusline' for Neovim
vim.g.statusline_orig = vim.o.statusline
vim.o.statusline = "%{%v:lua.StatusLine()%}"

function _G.StatusLine()
  local is_active = vim.api.nvim_get_current_win() == tonumber(vim.g.actual_curwin or -1)

  local get_file_icon = function()
    local ok, _ = pcall(require, "mini.icons")
    if not ok then
      return ""
    end

    local icon, icon_hl, is_default = MiniIcons.get("file", vim.fn.expand "%:t")
    local hl = is_active and "%%#" .. icon_hl .. "#" or ""
    return is_default and "" or hl .. icon .. "  %%##"
  end

  local get_git_branch = function()
    local ok, _ = pcall(require, "gitsigns")
    if not ok then
      return ""
    end

    local head = vim.b.gitsigns_head
    local status = is_active and vim.b.gitsigns_status or ""
    return head and "󰘬 " .. head .. (status and " " .. status or "") or ""
  end

  local statusline = vim.g.statusline_orig
  statusline = statusline:gsub("%%f", " " .. get_file_icon() .. "%%f", 1)
  statusline = statusline:gsub("%%=", get_git_branch() .. "%%=", 1)
  return statusline
end

-- [[ Functions ]] ============================================================

local function open_lazygit()
  vim.cmd "tabedit"
  vim.cmd "setlocal nonumber signcolumn=no statuscolumn="

  vim.fn.jobstart({
    "lazygit",
    "--git-dir=" .. vim.fn.trim(vim.fn.system "git rev-parse --git-dir"),
    "--work-tree=" .. vim.fn.getcwd(),
  }, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_tabpage_is_valid(0) then
          vim.cmd "tabclose"
        end
      end)
    end,
  })

  vim.cmd "startinsert"
end

local function toggle_qf()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and "cclose" or "copen")
end

-- [[ Autocommands ]] =========================================================

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text briefly",
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

vim.api.nvim_create_autocmd("LspProgress", {
  desc = "Display LSP progress lifecycle messages",
  callback = function(ev)
    local value = ev.data.params.value
    vim.api.nvim_echo({ { value.message or "done" } }, false, {
      id = "lsp." .. ev.data.client_id,
      kind = "progress",
      source = "vim.lsp",
      title = value.title,
      status = value.kind ~= "end" and "running" or "success",
      percent = value.percentage,
    })
  end,
})

-- [[ Keymaps ]] ==============================================================

local keymap_set = function(value)
  local lhs, rhs, desc = value[1], value[2], value[3]
  local mode = value.mode or "n"
  local opts = {}

  if type(desc) == "string" then
    opts.desc = desc
  end

  for k, v in pairs(value) do
    if type(k) ~= "number" and k ~= "mode" then
      opts[k] = v
    end
  end

  vim.keymap.set(mode, lhs, rhs, opts)
end

local keys = {
  { "<C-c>", "<Esc>", mode = { "i", "n", "v" }, noremap = true, silent = true },

  { "L", "$", "Jump to end of line", mode = { "n", "v" } },
  { "H", "^", "Jump to beginning of line", mode = { "n", "v" } },

  { "\\w", "<Cmd>set wrap!<CR>", "Toggle line wrap" },

  { "<Leader>y", [["+y]], "Yank text into system clipboard", mode = { "n", "v" } },
  { "<Leader>Y", [["+Y]], "Yank current line into system clipboard" },

  { "<Leader>p", [["_dP]], "Paste without overwriting register", mode = "x" },

  { "<C-u>", "<C-u>zz", "Scroll up and center cursor" },
  { "<C-d>", "<C-d>zz", "Scroll down and center cursor" },

  { "<Leader>w", "<Cmd>update<CR>", "Write the current buffer" },
  { "<Leader>q", "<Cmd>quit<CR>", "Quit the current file" },
  { "<Leader>Q", "<Cmd>wqa<CR>", "Write all buffers and quit" },

  { "<C-h>", "<C-w><C-h>", "Move focus to the left window" },
  { "<C-j>", "<C-w><C-j>", "Move focus to the lower window" },
  { "<C-k>", "<C-w><C-k>", "Move focus to the upper window" },
  { "<C-l>", "<C-w><C-l>", "Move focus to the right window" },

  { "<C-1>", "<Cmd>tabnext1<CR>", mode = { "n", "t" } },
  { "<C-2>", "<Cmd>tabnext2<CR>", mode = { "n", "t" } },
  { "<C-3>", "<Cmd>tabnext3<CR>", mode = { "n", "t" } },
  { "<C-4>", "<Cmd>tabnext4<CR>", mode = { "n", "t" } },
  { "<C-5>", "<Cmd>tabnext5<CR>", mode = { "n", "t" } },
  { "<C-6>", "<Cmd>tabnext6<CR>", mode = { "n", "t" } },
  { "<C-7>", "<Cmd>tabnext7<CR>", mode = { "n", "t" } },
  { "<C-8>", "<Cmd>tabnext8<CR>", mode = { "n", "t" } },
  { "<C-9>", "<Cmd>tabnext9<CR>", mode = { "n", "t" } },

  { "<Leader>tt", "<Cmd>tab term<CR>", "Open terminal in new tab" },
  { "<Leader>tv", "<Cmd>vert term<CR>", "Open terminal in vertical split" },

  { "<C-q>", toggle_qf, "Toggle the quickfix list", silent = true },
  { "<M-n>", "<Cmd>cnext<CR>zz", "Display the next item in the quickfix list" },
  { "<M-p>", "<Cmd>cprev<CR>zz", "Display the previous item in the quickfix list" },

  { "<Leader>a", "<Cmd>edit #<CR>", "Open the alternate file" },

  { "<C-f>", "<Cmd>Open .<CR>", "Open the current working directory with the system default handler" },

  { "<Leader>ld", "<Cmd>lua vim.diagnostic.setqflist()<CR>", "Add all diagnostics to the quickfix list" },
  { "]d", "<Cmd>lua vim.diagnostic.jump({ count = 1, float = true })<CR>", "Jump to the next diagnostic" },
  { "[d", "<Cmd>lua vim.diagnostic.jump({ count = -1, float = true })<CR>", "Jump to the previous diagnostic" },

  { "j", "v:count == 0 ? 'gj' : 'j'", mode = { "n", "x" }, expr = true, silent = true },
  { "k", "v:count == 0 ? 'gk' : 'k'", mode = { "n", "x" }, expr = true, silent = true },

  { "-", "<Cmd>Oil<CR>", "Open parent directory with Oil" },
  { "_", "<Cmd>Oil .<CR>", "Open the current working directory with Oil" },

  { "s", "<Plug>(leap)", mode = { "n", "x", "o" } },
  { "S", "<Plug>(leap-from-window)" },

  { "<Leader>sh", "<Cmd>Pick help<CR>", "Search help tags" },
  { "<Leader>sk", "<Cmd>Pick keymaps<CR>", "Search keymaps" },
  { "<Leader>sf", "<Cmd>Pick files<CR>", "Search files" },
  { "<Leader>sg", "<Cmd>Pick grep_live<CR>", "Search patterns matches with live feedback" },
  { "<Leader>s.", "<Cmd>Pick oldfiles<CR>", "Search recent files" },
  { "<Leader><Leader>", "<Cmd>Pick buffers<CR>", "Search open buffers" },

  { "<Leader>hi", "<Cmd>Gitsigns preview_hunk_inline<CR>", "Preview inline hunk" },
  { "<Leader>lh", "<Cmd>Gitsigns setqflist<CR>", "Add all hunks to the quickfix list" },
  { "\\b", "<Cmd>Gitsigns toggle_current_line_blame<CR>", "Toggle line blame" },
  { "]h", "<Cmd>Gitsigns nav_hunk next<CR>", "Jump to the next hunk" },
  { "[h", "<Cmd>Gitsigns nav_hunk prev<CR>", "Jump to the previous hunk" },

  { "<Leader>gg", open_lazygit, silent = true },
}

for _, key in ipairs(keys) do
  keymap_set(key)
end

-- [[ Plugins ]] ==============================================================

-- catppuccin -----------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/catppuccin/nvim.git", name = "catppuccin" },
}

require("catppuccin").setup {
  lsp_styles = {
    underlines = {
      errors = { "undercurl" },
      hints = { "undercurl" },
      warnings = { "undercurl" },
      information = { "undercurl" },
    },
  },
  custom_highlights = function(colors)
    local darken = require("catppuccin.utils.colors").darken

    return {
      CursorLine = { bg = colors.none },
      Folded = { bg = darken(colors.sky, 0.14, colors.base) },
      IblIndent = { fg = colors.surface0 },
      IblScope = { fg = colors.surface1 },
      MiniCursorword = { bg = colors.crust, style = {} },
      MiniCursorwordCurrent = { link = "MiniCursorword" },
      UfoFoldedEllipsis = { fg = colors.sky, bg = colors.none },
      Visual = { bg = colors.surface0, style = {} },
      ColorColumn = { bg = colors.mantle },
    }
  end,
}

vim.cmd.colorscheme "catppuccin-latte"

-- nvim-treesitter ------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/nvim-treesitter/nvim-treesitter.git" },
}

local parsers = {
  "bash",
  "dockerfile",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "terraform",
  "tsx",
  "typescript",
  "yaml",
}

require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    local _, lang = ev.match, vim.treesitter.language.get_lang(ev.match)

    if not lang or not vim.tbl_contains(parsers, lang) then
      return
    end

    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- gitsigns -------------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/lewis6991/gitsigns.nvim.git" },
}

require("gitsigns").setup {
  signs = {
    add = { text = "▍" },
    change = { text = "▍" },
  },
  signs_staged = {
    add = { text = "▍" },
    change = { text = "▍" },
  },
  current_line_blame_opts = {
    delay = 0,
  },
}

-- nvim-ufo -------------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/kevinhwang91/nvim-ufo.git" },
  { src = "https://github.com/kevinhwang91/promise-async.git" },
}

vim.o.foldcolumn = "1"
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

vim.o.fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldinner: ,foldclose:"

require("ufo").setup {
  open_fold_hl_timeout = 0,
  provider_selector = function()
    return { "treesitter", "indent" }
  end,
}

-- leap -----------------------------------------------------------------------
vim.pack.add {
  { src = "https://codeberg.org/andyg/leap.nvim.git" },
}

require("leap").opts.preview = function(ch0, ch1, ch2)
  return not (ch1:match "%s" or (ch0:match "%a" and ch1:match "%a" and ch2:match "%a"))
end

-- indent-blankline -----------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim.git" },
}

require("ibl").setup {
  indent = { char = "▏" },
  scope = { show_start = false },
}

-- mini -----------------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/nvim-mini/mini.nvim" },
}

require("mini.ai").setup()
require("mini.cursorword").setup()
require("mini.extra").setup()
require("mini.icons").setup()
require("mini.move").setup()
require("mini.pick").setup()

if _G.MiniPick ~= nil then
  local default_show = _G.MiniPick.default_show
  -- Override `default_show` instead of using `source.show` to preserve the
  -- hide/show behavior of icons using the built-in pickers.
  _G.MiniPick.default_show = function(buf_id, items, query, opts)
    default_show(buf_id, items, query, opts)
    if not (opts and opts.show_icons) then
      return
    end

    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)) do
      local col = vim.fn.byteidx(line, 1)
      vim.api.nvim_buf_set_text(buf_id, row - 1, col, row - 1, col, { " " })
      vim.api.nvim_buf_set_text(buf_id, row - 1, 0, row - 1, 0, { " " })
    end
  end
end

require("mini.surround").setup {
  mappings = {
    add = "gsa", -- Add surrounding in Normal and Visual modes
    delete = "gsd", -- Delete surrounding
    find = "gsf", -- Find surrounding (to the right)
    find_left = "gsF", -- Find surrounding (to the left)
    highlight = "gsh", -- Highlight surrounding
    replace = "gsr", -- Replace surrounding
  },
}

-- LSP (nvim-lspconfig, mason, etc.) ------------------------------------------
vim.pack.add {
  { src = "https://github.com/neovim/nvim-lspconfig.git" },
  { src = "https://github.com/mason-org/mason.nvim.git" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim.git" },
}

local servers = {
  basedpyright = {},
  biome = {},
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
  oxlint = {},
  ruff = {},
  tsgo = {},
}

-- Merge extra LSP settings with the defaults from `nvim-lspconfig`, etc.
for name, config in pairs(servers) do
  vim.lsp.config(name, config)
end

require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = vim.tbl_keys(servers),
}

-- oil ------------------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/stevearc/oil.nvim.git" },
}

require("oil").setup {
  columns = {
    "permissions",
    "size",
    "mtime",
    "icon",
  },
  view_options = {
    sort = {
      { "mtime", "desc" },
    },
  },
}

-- conform --------------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/stevearc/conform.nvim.git" },
}

require("conform").setup {
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  formatters_by_ft = {
    javascript = { "oxfmt", "biome", "prettierd", stop_after_first = true },
    typescript = { "oxfmt", "biome", "prettierd", stop_after_first = true },
    typescriptreact = { "oxfmt", "biome", "prettierd", stop_after_first = true },
    json = { "oxfmt", "jq", stop_after_first = true },
    jsonc = { "oxfmt", "jq", stop_after_first = true },
    lua = { "stylua" },
    sh = { "shfmt" },
  },
}

-- blink.cmp ------------------------------------------------------------------
vim.pack.add {
  { src = "https://github.com/saghen/blink.cmp.git", version = "v1.10.2" },
}

require("blink.cmp").setup {
  keymap = { preset = "default" },
  appearance = { nerd_font_variant = "normal" },
  completion = { documentation = { auto_show = true } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust_with_warning" },
}
