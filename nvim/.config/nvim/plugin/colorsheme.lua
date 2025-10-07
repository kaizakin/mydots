return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- ensures it loads last
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        float = {
          transparent = false, -- makes floating windows opaque
          solid = true, -- enables solid background for floats
          border = "rounded", -- optional: sets rounded borders, can use "single", "double", etc.
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
