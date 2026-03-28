return {
	"akinsho/toggleterm.nvim",
	version = "*",
	keys = {
		-- Mapping for Normal Mode (n) and Terminal Mode (t)
		{ [[<C-\>]], "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle Terminal" },
	},
	config = function()
		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<c-\>]], -- This is your shortcut (Ctrl + \)
			direction = "float", -- Can be 'float', 'horizontal', or 'vertical'
			shade_terminals = true,
			insert_mappings = true,
			terminal_mappings = true,
			float_opts = {
				border = "curved",
			},
			winbar = {
				enabled = false,
				name_formatter = function(term) --  term: Terminal
					return term.name
				end,
			},
		})
	end,
}
