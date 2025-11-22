return {
    {
        "bjarneo/aether.nvim",
        name = "aether",
        priority = 1000,
        opts = {
            disable_italics = false,
            colors = {
                -- Monotone shades (base00-base07)
                base00 = "#141414", -- Default background
                base01 = "#b7b3b3", -- Lighter background (status bars)
                base02 = "#141414", -- Selection background
                base03 = "#b7b3b3", -- Comments, invisibles
                base04 = "#F5F5F5", -- Dark foreground
                base05 = "#ffffff", -- Default foreground
                base06 = "#ffffff", -- Light foreground
                base07 = "#F5F5F5", -- Light background

                -- Accent colors (base08-base0F)
                base08 = "#958989", -- Variables, errors, red
                base09 = "#ada4a4", -- Integers, constants, orange
                base0A = "#b2aaaa", -- Classes, types, yellow
                base0B = "#a39999", -- Strings, green
                base0C = "#dddada", -- Support, regex, cyan
                base0D = "#c0baba", -- Functions, keywords, blue
                base0E = "#cfcaca", -- Keywords, storage, magenta
                base0F = "#cac5c5", -- Deprecated, brown/yellow
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
