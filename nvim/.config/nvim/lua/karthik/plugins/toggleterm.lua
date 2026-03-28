return {
	"akinsho/toggleterm.nvim",
	version = "*",
	lazy = false,
	config = function()
		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<c-j>]], -- This is your shortcut (Ctrl + j)
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
		function _G.set_terminal_keymaps()
			local opts = { buffer = 0 }
			vim.keymap.set("t", "<C-j>", [[<Cmd>exe v:count1 . "ToggleTerm"<CR>]], opts)
		end

		-- This applys the mapping only when a terminal buffer is opened
		-- vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
	end,
}
