return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Neo-tree Explorer (Root Dir)" },
			{ "<leader>be", "<cmd>Neotree buffers<cr>", desc = "Neo-tree Buffers" },
			{ "<leader>ge", "<cmd>Neotree git_status<cr>", desc = "Neo-tree Git Status" },
		},
		opts = {
			close_if_last_window = true, -- Close Neo-tree if it's the last window left open
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,
			filesystem = {
				filesystem_count_to_count = false,
				follow_current_file = {
					enabled = true, -- Focuses the active buffer in the tree automatically
				},
				filtered_items = {
					visible = false, -- Hide dotfiles or gitignored files by default
					hide_dotfiles = false,
					hide_gitignored = false,
				},
				window = {
					mappings = {
						["<bs>"] = "navigate_up",
						["."] = "set_root",
						["H"] = "toggle_hidden",
						["/"] = "fuzzy_finder",
						["f"] = "filter_on_submit",
					},
				},
			},
			buffers = {
				follow_current_file = {
					enabled = true,
				},
			},
		},
		config = function(_, opts)
			require("neo-tree").setup(opts)

			-- Open neo-tree automatically, rooted at the directory nvim was started in
			-- (cd into it first if nvim was launched with a directory argument, e.g. `nvim .`)
			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					if vim.fn.argc() == 1 then
						local arg = vim.fn.argv(0)
						local stat = vim.uv.fs_stat(arg)
						if stat and stat.type == "directory" then
							vim.cmd.cd(arg)
						end
					end
					require("neo-tree.command").execute({ action = "show", dir = vim.fn.getcwd() })
				end,
			})
		end,
	},
}
