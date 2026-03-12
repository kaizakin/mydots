return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<c-\>]], -- This is your shortcut (Ctrl + \)
			direction = "float", -- Can be 'float', 'horizontal', or 'vertical'
			shade_terminals = true,
		})
	end,
}
