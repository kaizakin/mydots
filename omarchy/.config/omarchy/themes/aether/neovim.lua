return {
    {
        "bjarneo/aether.nvim",
        name = "aether",
        priority = 1000,
        opts = {
            disable_italics = false,
            colors = {
                -- Monotone shades (base00-base07)
                base00 = "#1e1e2e", -- Default background
                base01 = "#585b70", -- Lighter background (status bars)
                base02 = "#45475a", -- Selection background
                base03 = "#585b70", -- Comments, invisibles
                base04 = "#bac2de", -- Dark foreground
                base05 = "#cdd6f4", -- Default foreground
                base06 = "#cdd6f4", -- Light foreground
                base07 = "#bac2de", -- Light background

                -- Accent colors (base08-base0F)
                base08 = "#f38ba8", -- Variables, errors, red
                base09 = "#f38ba8", -- Integers, constants, orange
                base0A = "#f9e2af", -- Classes, types, yellow
                base0B = "#a6e3a1", -- Strings, green
                base0C = "#94e2d5", -- Support, regex, cyan
                base0D = "#89b4fa", -- Functions, keywords, blue
                base0E = "#cba6f7", -- Keywords, storage, magenta
                base0F = "#f9e2af", -- Deprecated, brown/yellow
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
