local function open_lazygit()
  local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()

  vim.cmd "tabnew"
  local lazygit_tab = vim.api.nvim_get_current_tabpage()
  local lazygit_buf = vim.api.nvim_get_current_buf()

  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.statuscolumn = ""

  local job_id = vim.fn.jobstart({ "lazygit" }, {
    cwd = cwd,
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_tabpage_is_valid(lazygit_tab) then
          vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(lazygit_tab))
        end
        if vim.api.nvim_buf_is_valid(lazygit_buf) then
          vim.api.nvim_buf_delete(lazygit_buf, { force = true })
        end
      end)
    end,
  })

  if job_id <= 0 then
    vim.cmd "tabclose"
    vim.notify("Could not start Lazygit", vim.log.levels.ERROR)
  end
end

vim.keymap.set("n", "<Leader>gg", open_lazygit, { silent = true })
