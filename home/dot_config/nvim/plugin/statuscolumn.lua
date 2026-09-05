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

function _G.StatusColumn()
  local row = vim.v.lnum - 1 -- The extmark API is 0-based
  local buffer = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local number_width = math.max(3, #tostring(vim.api.nvim_buf_line_count(buffer)))
  local number = vim.v.virtnum == 0 and string.format("%" .. number_width .. "d ", vim.v.lnum)
    or string.rep(" ", number_width + 1)
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

  return sign .. number .. git .. "%C "
end
