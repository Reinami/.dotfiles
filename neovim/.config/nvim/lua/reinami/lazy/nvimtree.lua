local function toggle_tree_focus()
    local view = require("nvim-tree.view")
    local api = require("nvim-tree.api")

    if view.is_visible() and view.get_winnr() == vim.api.nvim_get_current_win() then
        vim.cmd("wincmd p")
    else
        api.tree.focus()
    end
end

local function on_tree_attach(bufnr)
    local api = require("nvim-tree.api")

    api.config.mappings.default_on_attach(bufnr)

    vim.keymap.set("n", "<CR>", api.node.open.edit, { noremap = true, silent = true, buffer = bufnr })
    vim.keymap.set("n", "%", api.fs.create, { noremap = true, silent = true, buffer = bufnr })
    vim.keymap.set("n", "d", api.fs.remove, { noremap = true, silent = true, buffer = bufnr })
    vim.keymap.set("n", "r", api.fs.rename, { noremap = true, silent = true, buffer = bufnr })
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
                    dotfiles = false,
                },
                on_attach = on_tree_attach,
            })

            local api = require("nvim-tree.api")

            vim.keymap.set("n", "<leader>e", api.tree.open, { noremap = true, silent = true, desc = "Toggle NvimTree" })
            vim.keymap.set("n", "<C-e>", toggle_tree_focus, {noremap = true, silent = true, desc = "Focus NvimTree"})
        end,
    },
}
