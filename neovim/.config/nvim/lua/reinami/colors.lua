function SetTheme(themeName)
    vim.cmd.colorscheme(themeName)

    -- Customize highlights for transparency
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

vim.api.nvim_create_user_command(
    "SetTheme",
    SetTheme,
    { nargs = 1 }
)
