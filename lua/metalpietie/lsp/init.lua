-- Native LSP wiring for Neovim 0.12.
--
-- nvim-lspconfig is now just a data package: it ships `lsp/<name>.lua` files on
-- the runtimepath. `vim.lsp.config()` layers our overrides on top and
-- `vim.lsp.enable()` starts servers on matching filetypes.

local servers = require("metalpietie.lsp.servers")

--------------------------------------------------------------------------------
-- Capabilities: applied to every server via the "*" wildcard config.
--------------------------------------------------------------------------------
local capabilities = vim.lsp.protocol.make_client_capabilities()

local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
    capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.lsp.config("*", {
    capabilities = capabilities,
})

--------------------------------------------------------------------------------
-- Per-server overrides, then start them.
--------------------------------------------------------------------------------
for name, config in pairs(servers.configs) do
    vim.lsp.config(name, config)
end

vim.lsp.enable(servers.enable)

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        severity = { min = vim.diagnostic.severity.WARN },
    },
    severity_sort = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
        },
    },
    float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
})

--------------------------------------------------------------------------------
-- Buffer-local keymaps
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("metalpietie-lsp-attach", { clear = true }),
    callback = function(e)
        local opts = { buffer = e.buf }

        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
        end

        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "K", vim.lsp.buf.hover, "Hover")
        map("n", "<leader>vws", vim.lsp.buf.workspace_symbol, "Workspace symbol")
        map("n", "<leader>vd", vim.diagnostic.open_float, "Line diagnostics")
        map("n", "<leader>vca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>b", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>vrr", vim.lsp.buf.references, "References")
        map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename")
        map("n", "<C-Space>", vim.lsp.buf.signature_help, "Signature help")

        -- Kept in the original (inverted) orientation: [d goes forwards.
        map("n", "[d", function()
            vim.diagnostic.jump({ count = 1, float = true })
        end, "Next diagnostic")
        map("n", "]d", function()
            vim.diagnostic.jump({ count = -1, float = true })
        end, "Previous diagnostic")

        map("n", "<leader>vi", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = e.buf }), { bufnr = e.buf })
        end, "Toggle inlay hints")
    end,
})
