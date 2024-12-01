return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")

        -- REQUIRED
        harpoon:setup()
        -- REQUIRED

        -- Key mappings
        vim.keymap.set("n", "<A-Up>", function() harpoon:list():add() end)
        vim.keymap.set("n", "<A-Down>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        vim.keymap.set("n", "<A-left>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<A-Right>", function() harpoon:list():next() end)
    end,
}
