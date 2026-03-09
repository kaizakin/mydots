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
