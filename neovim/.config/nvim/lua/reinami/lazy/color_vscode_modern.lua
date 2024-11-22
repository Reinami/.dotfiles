return {
    "gmr458/vscode_modern_theme.nvim",
    config = function()
        require("vscode_modern").setup({
            cursorline = true,
            transparent_background = true,
            nvim_tree_darker = true,
        })
    end,
}
