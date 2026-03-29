-- Author: Eric Ottosson <contact@ericotsn.com>
-- URL: https://github.com/ericotsn/dotfiles

if vim.g.vscode then
	return
end

-- [[ Options ]] ==============================================================

vim.g.mapleader = " "
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.mouse = "a"
vim.o.number = true
vim.o.relativenumber = true
vim.o.scrolloff = 8
vim.o.shiftwidth = 4
vim.o.smartcase = true
vim.o.tabstop = 4
vim.o.timeoutlen = 300
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.winborder = "rounded"
vim.o.wrap = false

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "‼",
			[vim.diagnostic.severity.WARN] = "!",
			[vim.diagnostic.severity.INFO] = "⁇",
			[vim.diagnostic.severity.HINT] = "?",
		},
	},
	-- Show partial inline diagnostics on the current cursor line
	virtual_text = {
		current_line = true,
		severity = vim.diagnostic.severity.ERROR,
	},
})

-- Custom 'statuscolumn' for Neovim >= 0.9
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
		local icon, icon_hl, is_default = MiniIcons.get("file", vim.fn.expand("%:t"))
		local hl = is_active and "%%#" .. icon_hl .. "#" or ""
		return is_default and "" or hl .. icon .. "  %%##"
	end

	local get_git_branch = function()
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
	vim.cmd("tabedit")
	vim.cmd("setlocal nonumber signcolumn=no statuscolumn=")

	vim.fn.jobstart({
		"lazygit",
		"--git-dir=" .. vim.fn.trim(vim.fn.system("git rev-parse --git-dir")),
		"--work-tree=" .. vim.fn.getcwd(),
	}, {
		term = true,
		on_exit = function()
			vim.schedule(function()
				if vim.api.nvim_tabpage_is_valid(0) then
					vim.cmd("tabclose")
				end
			end)
		end,
	})

	vim.cmd("startinsert")
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

-- [[ Keymaps ]] ==============================================================
-- stylua: ignore start

vim.keymap.set({ "i", "n", "v" }, "<C-c>", "<Esc>", { noremap = true, silent = true })

vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Jump to end of line" })
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Jump to beginning of line" })

vim.keymap.set("n", "\\w", ":set wrap!<CR>", { desc = "Toggle line wrap" })

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank text into system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank current line into system clipboard" })

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })

vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center cursor" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center cursor" })

vim.keymap.set("n", "<C-j>", ":cnext<CR>zz", { desc = "Display the next item in the quickfix list" })
vim.keymap.set("n", "<C-k>", ":cprev<CR>zz", { desc = "Display the previous item in the quickfix list" })
vim.keymap.set("n", "<leader>co", ":copen<CR>zz", { desc = "Open the quickfix list" })
vim.keymap.set("n", "<leader>cc", ":cclose<CR>zz", { desc = "Close the quickfix list" })

vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Jump to the next diagnostic" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Jump to the previous diagnostic" })

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

vim.keymap.set("n", "<leader>ld", vim.diagnostic.setqflist, { desc = "Add all diagnostics to the quickfix list" })

vim.keymap.set("n", "-", ":Oil<CR>", { desc = "Open parent directory" })

vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
vim.keymap.set("n", "S", "<Plug>(leap-from-window)")

vim.keymap.set("n", "<leader>?", function() MiniExtra.pickers.oldfiles() end, { desc = "Search recent files" })
vim.keymap.set("n", "<leader>fb", function() MiniPick.builtin.buffers() end, { desc = "Search buffers" })
vim.keymap.set("n", "<leader>ff", function() MiniPick.builtin.files() end, { desc = "Search files" })
vim.keymap.set("n", "<leader>sg", function() MiniPick.builtin.grep_live() end, { desc = "Search pattern matches with live feedback" })
vim.keymap.set("n", "<leader>sh", function() MiniPick.builtin.help() end, { desc = "Search help tags" })

vim.keymap.set("n", "<leader>hi", ":Gitsigns preview_hunk_inline<CR>", { desc = "Preview inline hunk" })
vim.keymap.set("n", "<leader>lh", ":Gitsigns setqflist<CR>", { desc = "Add all hunks to the quickfix list" })
vim.keymap.set("n", "\\b", ":Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle line blame" })

vim.keymap.set("n", "<leader>gg", open_lazygit, { silent = true })

local function lsp_keymap(ev)
	vim.keymap.set( "n", "gd", vim.lsp.buf.definition, { desc = "Jump to the definition of the symbol under the cursor", buffer = ev.buf })
	vim.keymap.set( "n", "gD", vim.lsp.buf.declaration, { desc = "Jump to the declaration of the symbol under the cursor", buffer = ev.buf })
	vim.keymap.set("n", "gri", function()
		MiniExtra.pickers.lsp({ scope = "implementation" })
	end, { desc = "List all the implementations for the symbol under the cursor", buffer = ev.buf })
	vim.keymap.set("n", "grr", function()
		MiniExtra.pickers.lsp({ scope = "references" })
	end, { desc = "List all the references to the symbol under the cursor", buffer = ev.buf })
	vim.keymap.set( "n", "grt", vim.lsp.buf.type_definition, { desc = "Go to the definition of the type of the symbol under the cursor", buffer = ev.buf })
	vim.keymap.set("n", "gO", function()
		MiniExtra.pickers.lsp({ scope = "document_symbol" })
	end, { desc = "List all symbols in the current buffer", buffer = ev.buf })
end
-- stylua: ignore end

-- [[ Plugins ]] ==============================================================

-- catppuccin -----------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim.git", name = "catppuccin" },
})

require("catppuccin").setup({
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
			IblIndent = { fg = colors.surface1 },
			IblScope = { fg = colors.surface2 },
			MiniCursorword = { bg = colors.surface0, style = {} },
			MiniCursorwordCurrent = { link = "MiniCursorword" },
			UfoFoldedEllipsis = { fg = colors.sky, bg = colors.none },
			Visual = { bg = colors.surface1, style = {} },
		}
	end,
})

vim.cmd.colorscheme("catppuccin-frappe")

-- nvim-treesitter ------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter.git" },
})

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
vim.pack.add({
	{ src = "https://github.com/lewis6991/gitsigns.nvim.git" },
})

require("gitsigns").setup({
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
})

-- nvim-ufo -------------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/kevinhwang91/nvim-ufo.git" },
	{ src = "https://github.com/kevinhwang91/promise-async.git" },
})

vim.o.foldcolumn = "1"
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

vim.o.fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldinner: ,foldclose:"

require("ufo").setup({
	open_fold_hl_timeout = 0,
	provider_selector = function()
		return { "treesitter", "indent" }
	end,
})

-- leap -----------------------------------------------------------------------
vim.pack.add({
	{ src = "https://codeberg.org/andyg/leap.nvim.git" },
})

require("leap").opts.preview = function(ch0, ch1, ch2)
	return not (ch1:match("%s") or (ch0:match("%a") and ch1:match("%a") and ch2:match("%a")))
end

-- indent-blankline -----------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim.git" },
})

require("ibl").setup({
	indent = { char = "▏" },
	scope = { show_start = false },
})

-- mini -----------------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/nvim-mini/mini.nvim" },
})

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
		end
	end
end

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

-- LSP (nvim-lspconfig, mason, etc.) ------------------------------------------
vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig.git" },
	{ src = "https://github.com/mason-org/mason.nvim.git" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim.git" },
})

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
require("mason-lspconfig").setup({
	ensure_installed = vim.tbl_keys(servers),
})

vim.api.nvim_create_autocmd("LspAttach", { callback = lsp_keymap })

-- oil ------------------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim.git" },
})

require("oil").setup({
	columns = {
		"permissions",
		"size",
		"mtime",
		"icon",
	},
})

-- conform --------------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim.git" },
})

require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		javascript = { "oxfmt", "biome", "prettierd", stop_after_first = true },
		typescript = { "oxfmt", "biome", "prettierd", stop_after_first = true },
		typescriptreact = { "oxfmt", "biome", "prettierd", stop_after_first = true },
		lua = { "stylua" },
	},
	formatters = {
		oxfmt = {
			condition = function(_, ctx)
				return vim.fs.find({ ".oxfmtrc.json", ".oxfmtrc.jsonc" }, {
					path = ctx.filename,
					upward = true,
					stop = vim.uv.os_homedir(),
				})[1] ~= nil
			end,
		},
		biome = {
			condition = function(_, ctx)
				return vim.fs.find({ "biome.json", "biome.jsonc" }, {
					path = ctx.filename,
					upward = true,
					stop = vim.uv.os_homedir(),
				})[1] ~= nil
			end,
		},
		ruff = {
			condition = function(_, ctx)
				return vim.fs.find({ "ruff.toml", ".ruff.toml" }, {
					path = ctx.filename,
					upward = true,
					stop = vim.uv.os_homedir(),
				})[1] ~= nil
			end,
		},
	},
})

-- blink.cmp ------------------------------------------------------------------
vim.pack.add({
	{ src = "https://github.com/saghen/blink.cmp.git", version = "v1.10.1" },
})

require("blink.cmp").setup({
	keymap = { preset = "default" },
	appearance = { nerd_font_variant = "normal" },
	completion = { documentation = { auto_show = true } },
	sources = { default = { "lsp", "path", "snippets", "buffer" } },
	fuzzy = { implementation = "prefer_rust_with_warning" },
})
