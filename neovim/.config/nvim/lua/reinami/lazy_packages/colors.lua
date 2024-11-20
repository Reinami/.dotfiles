function SetThemeColor(color)
    color = color or "kanagawa"
    vim.cmd.colorscheme(color)

    -- Customize highlights for transparency
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
    "rebelot/kanagawa.nvim",
    config = function()
        require("kanagawa").setup({
            transparent = true, -- Enable transparent background
            theme = "wave", -- Choose "wave", "dragon", or "lotus" themes
            overrides = function(colors)
                return {
                    -- Ensure Normal and NormalFloat retain transparency
                    Normal = { bg = "none" },
                    NormalFloat = { bg = "none" },
                }
            end,
        })

        -- Apply the colorscheme
        vim.cmd("colorscheme kanagawa")
        
        -- Apply additional customizations
        SetThemeColor()
    end,
}
