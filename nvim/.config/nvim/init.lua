require("karthik.core")
require("karthik.lazy")

-- Allow Ctrl+V to paste from system clipboard in Insert mode
vim.keymap.set("i", "<C-v>", "<C-r>+", { noremap = true, silent = true })

-- Allow Ctrl+V to paste in Command mode (very useful for paths/URLs)
vim.keymap.set("c", "<C-v>", "<C-r>+", { noremap = true, silent = true })
