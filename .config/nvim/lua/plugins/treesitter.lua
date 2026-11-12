return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = function()
    require("config.treesitter").install()
  end,
  config = function()
    require("config.treesitter").setup()
  end,
}
