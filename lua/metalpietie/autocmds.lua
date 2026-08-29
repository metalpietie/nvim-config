local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local metalpietie = augroup("metalpietie", { clear = true })

autocmd("TextYankPost", {
    group = metalpietie,
    pattern = "*",
    callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 40 })
    end,
})

-- Trim trailing whitespace on write, but leave the cursor where it was.
autocmd("BufWritePre", {
    group = metalpietie,
    pattern = "*",
    callback = function()
        local view = vim.fn.winsaveview()
        vim.cmd([[keeppatterns %s/\s\+$//e]])
        vim.fn.winrestview(view)
    end,
})

-- 2-space indent for everything conform hands to prettier (see
-- metalpietie.plugins.conform), matching prettier's own default tabWidth.
-- The global 4-space default in metalpietie.options is for everything else.
autocmd("FileType", {
    group = metalpietie,
    pattern = {
        "html", "htmlangular", "css", "scss", "less",
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "svelte", "json", "jsonc", "yaml", "markdown",
    },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
    end,
})
