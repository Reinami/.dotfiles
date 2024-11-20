return {
    "mbbill/undotree",
    config = function()
        -- Keymap to toggle UndoTree
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
    end,
}
