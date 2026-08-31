local map = vim.keymap.set

map('n', '<F2>', '<cmd>set number! relativenumber!<CR>', { silent = true, desc = "Toggle Line Numbers" })
map('n', '<F3>', '<cmd>set cursorline! cursorcolumn!<CR>', { silent = true, desc = "Toggle Cursor Highlight" })
