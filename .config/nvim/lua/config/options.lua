vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.title = true
opt.titlestring = "%{fnamemodify(expand('%:~'), ':h')}"
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorcolumn = true

opt.clipboard = "unnamedplus"
opt.termguicolors = true

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2

opt.ignorecase = true
opt.smartcase = true

opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 300

opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.list = true
opt.listchars = {
  tab = "» ",
  trail = "·",
  extends = "›",
  precedes = "‹",
}
opt.wrap = false
opt.linebreak = true
