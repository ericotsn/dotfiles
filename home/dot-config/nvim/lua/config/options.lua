vim.opt.textwidth = 70

vim.keymap.set({ "i", "n", "s" }, "<Esc>", function()
  vim.cmd("noh")
  return "<Esc>"
end, { expr = true, silent = true })
