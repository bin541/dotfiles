local group = vim.api.nvim_create_augroup("UserHighlights", { clear = true })

local function set_highlights()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#4F5258", ctermbg = 240 })
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#4F5258", ctermbg = 240 })
  vim.api.nvim_set_hl(0, "CursorLineNr", { bold = true, fg = "#ffffff", ctermfg = 15 })
end

set_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = set_highlights,
  desc = "Reapply user highlights after a colorscheme change",
})
