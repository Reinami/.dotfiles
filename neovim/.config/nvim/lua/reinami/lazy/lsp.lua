return {
    -- Core LSP and Mason
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v2.x",
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" },
            { "williamboman/mason.nvim" },
            { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "L3MON4D3/LuaSnip" },
        },
        config = function()
            local lsp_zero = require("lsp-zero")

            -- Use the recommended preset
            lsp_zero.preset("recommended")

            -- Mason setup
            require("mason").setup({})
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls", -- Add other servers as needed
                    "pyright",
                    "gopls",
                    "jsonls",
                    "ts_ls",
                    "cssls",
                },
                handlers = {
                    function(server_name)
                        require("lspconfig")[server_name].setup({})
                    end,
                },
            })

            -- Lua-specific setup
            require("lspconfig").lua_ls.setup(lsp_zero.nvim_lua_ls())

            -- Configure CMP
            local cmp = require("cmp")
            cmp.setup({
                sources = {
                    { name = "nvim_lsp" },
                },
                mapping = {
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<Up>"] = cmp.mapping.select_prev_item({ behavior = "select" }),
                    ["<Down>"] = cmp.mapping.select_next_item({ behavior = "select" }),
                    ["<C-p>"] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_prev_item({ behavior = "insert" })
                        else
                            cmp.complete()
                        end
                    end),
                    ["<C-n>"] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_next_item({ behavior = "insert" })
                        else
                            cmp.complete()
                        end
                    end),
                },
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
            })
        end,
    },
}

