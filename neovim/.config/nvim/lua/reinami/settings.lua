vim.api.nvim_command('set fileformat=unix')

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 15
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

-- clipboard shenanigans for WSL

vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
        ["+"] = "clip.exe",
        ["*"] = "clip.exe"
    },
    paste = {
        ["+"] = "powershell.exe -Command Get-Clipboard",
        ["*"] = "powershell.exe -Command Get-Clipboard"
    },
    cache_enabled = 0
}

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.cmd([[%s/\r//g]])
    end,
    pattern = "*",
})

vim.api.nvim_create_autocmd("TextChangedI", {
    pattern = "*",
    callback = function()
        vim.cmd([[%s/\r//g]])
    end,
})
