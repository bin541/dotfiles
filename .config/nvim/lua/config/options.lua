local opt = vim.opt

opt.title = true
opt.titlestring = "%{fnamemodify(expand('%:~'), ':h')}"
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorcolumn = true

opt.clipboard = "unnamedplus"
