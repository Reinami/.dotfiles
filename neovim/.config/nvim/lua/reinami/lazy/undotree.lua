return {
    "mbbill/undotree",
    config = function()
        local function toggle_undo_tree()
            vim.cmd.UndotreeToggle()
            vim.cmd.UndotreeFocus()
        end
        vim.keymap.set("n", "<C-z>", toggle_undo_tree)
    end,
}
