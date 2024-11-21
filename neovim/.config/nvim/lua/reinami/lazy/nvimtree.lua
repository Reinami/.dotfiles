local function toggle_tree_focus()
    local view = require("nvim-tree.view")
    if view.is_visible() and view.get_winnr() == vim.api.nvim_get_current_win() then
        vim.cmd("wincmd p")
    else
        api.tree.focus()
    end
end

return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons", -- Optional: File icons
        },
        config = function()
            require("nvim-tree").setup({
                sort = {
                    sorter = "case_sensitive",
                },
                view = {
                    width = 30,
                },
                renderer = {
                    group_empty = true,
                },
                filters = {
                    dotfiles = true,
                },
            })

            vim.keymap.set("n", "<leader>e", api.tree.toggle, { noremap = true, silent = true, desc = "Toggle NvimTree" })
            vim.keymap.set("n", "<C-e>", toggle_tree_focus, {noremap = true, silent = true, desc = "Focus NvimTree"})
        end,
    },
}
