return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }, -- Telescope requires plenary.nvim
    config = function()
        local builtin = require("telescope.builtin")

        -- Key mappings
        vim.keymap.set("n", "<C-f>", builtin.find_files, {})
        vim.keymap.set("n", "<C-g>", builtin.git_files, {})
        vim.keymap.set("n", "<C-s>", function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)
    end,
}
