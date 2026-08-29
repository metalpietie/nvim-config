-- metalpietie's neovim config
-- Requires Neovim 0.12+ (uses the built-in `vim.pack` plugin manager).

if vim.fn.has("nvim-0.12") == 0 then
    vim.api.nvim_echo({
        { "This config requires Neovim 0.12+ (vim.pack).\n", "ErrorMsg" },
        { "Detected: " .. tostring(vim.version()) .. "\n", "WarningMsg" },
    }, true, {})
    return
end

require("metalpietie")
