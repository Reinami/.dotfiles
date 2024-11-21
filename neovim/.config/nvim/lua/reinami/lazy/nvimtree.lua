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
                on_attach = function(bufnr)
                    local api = require("nvim-tree.api")

                    vim.keymap.set("n", "%", api.fs.create, { noremap = true, silent = true, buffer = bufnr })
                    vim.keymap.set("n", "D", api.fs.remove, { noremap = true, silent = true, buffer = bufnr })
                    vim.keymap.set("n", "d", api.fs.mkdir, { noremap = true, silent = true, buffer = bufnr })
                    vim.keymap.set("n", "R", api.fs.rename, { noremap = true, silent = true, buffer = bufnr })
            })

            local api = require("nvim-tree.api")

            vim.keymap.set("n", "<C-t>", api.tree.toggle, { noremap = true, silent = true, desc = "Toggle NvimTree" })
            vim.keymap.set("n", "<leader>e", toggle_tree_focus, {noremap = true, silent = true, desc = "Focus NvimTree"})
        end,
    },
}
