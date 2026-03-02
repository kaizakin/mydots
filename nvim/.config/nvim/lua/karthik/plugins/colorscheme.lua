return {
	{
		"ydkulks/cursor-dark.nvim",
		priority = 1000,
		config = function()
			require("cursor-dark").setup({
				style = "dark-midnight", -- This matches the "extra dark" Cursor vibe
				transparent = false,
			})
			vim.cmd.colorscheme("cursor-dark")
		end,
	},
}
