return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPre", "BufNewFile" },
  main = "ibl",
  config = function()
    local hooks = require("ibl.hooks")

    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      local function get_hl(name)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        if ok and hl and next(hl) ~= nil then
          return hl
        end
      end

      local indent_hl = get_hl("Whitespace") or get_hl("NonText") or get_hl("Comment") or {}
      local scope_hl = get_hl("LineNr") or get_hl("CursorLineNr") or get_hl("Comment") or {}

      vim.api.nvim_set_hl(0, "IblIndent", indent_hl)
      vim.api.nvim_set_hl(0, "IblWhitespace", indent_hl)
      vim.api.nvim_set_hl(0, "IblScope", scope_hl)
    end)

    require("ibl").setup({
      indent = { char = "┊" },
    })
  end,
}
