return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local builtin = require("telescope.builtin") -- Added for direct picker control
		local has_ts_parsers, ts_parsers = pcall(require, "nvim-treesitter.parsers")

		-- nvim-treesitter removed parsers.ft_to_lang in newer versions, but
		-- telescope 0.1.x still calls it for preview highlighting.
		if has_ts_parsers and ts_parsers.ft_to_lang == nil then
			ts_parsers.ft_to_lang = function(ft)
				return vim.treesitter.language.get_lang(ft) or ft
			end
		end

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
			},
			pickers = {
				-- This forces ALL find_files calls to look inside hidden folders and ignore .gitignore boundaries
				find_files = {
					hidden = true,
					no_ignore = true,
				},
			},
		})

		telescope.load_extension("fzf")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>ff", function()
			builtin.find_files({
				hidden = true,
				no_ignore = true,
			})
		end, { desc = "Fuzzy find ALL files in cwd (inc. hidden & ignored)" })

		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
		keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
	end,
}
