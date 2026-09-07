vim.o.statuscolumn = "%!v:lua.StatusColumn()"

vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "‼",
      [vim.diagnostic.severity.WARN] = "!",
      [vim.diagnostic.severity.INFO] = "?",
      [vim.diagnostic.severity.HINT] = "?",
    },
  },
}

local function highlight(text, group)
  return group == "" and text or "%#" .. group .. "#" .. text .. "%*"
end

function _G.StatusColumn()
  local buffer = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  if vim.bo[buffer].buftype == "terminal" then
    return ""
  end

  local row = vim.v.lnum - 1 -- The extmark API is 0-based
  local number = vim.v.virtnum == 0 and tostring(vim.v.lnum) or ""
  local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, { row, 0 }, { row, -1 }, { details = true, type = "sign" })
  local sign, git = "", ""

  for _, mark in ipairs(marks) do
    local d = mark[4]
    local hl = d.sign_hl_group or ""

    if hl:find("GitSign", 1, true) then
      git = highlight(vim.fn.strcharpart(d.sign_text or "", 0, 1), hl)
    else
      sign = highlight(d.sign_text or "", hl)
    end
  end

  return "%-2.2(" .. sign .. "%) %3.3(" .. number .. "%) %-1.1(" .. git .. "%) %1.1C "
end
