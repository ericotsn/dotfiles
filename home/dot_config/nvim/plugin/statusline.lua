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
