local function SetTheme(opts)
    local themeName
    if type(opts) == "string" then
        themeName = opts -- Direct string passed
    elseif type(opts) == "table" and opts.args then
        themeName = opts.args -- Called as a user command
    else
        error("Invalid argument passed to SetTheme")
    end

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

return {
    SetTheme = SetTheme
}
