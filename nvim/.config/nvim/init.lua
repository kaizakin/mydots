require("karthik.core")
require("karthik.lazy")

local function set_transparent()
	local groups = {
		"Normal",
		"NormalFloat",
		"NormalNC",
		"LineNr",
		"Folded",
		"NonText",
		"SpecialKey",
		"VertSplit",
		"SignColumn",
		"EndOfBuffer",
	}
	for _, group in ipairs(groups) do
		vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
	end
end

set_transparent()

if vim.g.neovide then
	-- Set the transparency level (0.0 to 1.0)
	vim.g.neovide_opacity = 0.99

	-- Optional: Keeps buffer text sharp while background stays transparent
	vim.g.neovide_normal_opacity = 0.8
end

-- remove the ugly command line at the bottom
vim.o.cmdheight = 0
