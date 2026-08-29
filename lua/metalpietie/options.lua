vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20"

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
vim.opt.undodir = vim.fn.expand("$HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.opt.splitright = true
vim.opt.splitbelow = true

-- Treesitter-backed folds, but start fully unfolded.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
vim.opt.foldlevel = 99

-- netrw
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 0

vim.filetype.add({
    extension = {
        templ = "templ",
    },
    pattern = {
        -- Angular component templates. Without this they come through as plain
        -- `html`, which loses the angular treesitter parser and the angularls
        -- template intelligence (control flow, bindings, pipes).
        [".*%.component%.html"] = "htmlangular",
    },
})
