local M = {}

M.parsers = {
  "bash",
  "c",
  "cpp",
  "go",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

function M.install()
  require("nvim-treesitter").install(M.parsers):wait(300000)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
      if language and vim.treesitter.language.add(language) then
        vim.treesitter.start(args.buf, language)
      end
    end,
    desc = "Start Tree-sitter highlighting when a parser is available",
  })
end

return M
