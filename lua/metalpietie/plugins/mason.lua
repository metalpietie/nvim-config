-- Mason installs the language servers and CLI tools; the servers themselves are
-- configured and switched on natively in `metalpietie.lsp`.

require("mason").setup({
    PATH = "prepend",
    ui = {
        border = "rounded",
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
        },
    },
})

require("mason-lspconfig").setup({
    ensure_installed = require("metalpietie.lsp.servers").mason_ensure_installed,

    -- We enable servers explicitly in metalpietie.lsp, so mason must not switch
    -- on everything that happens to be installed in the mason registry.
    automatic_enable = false,
})

-- Non-LSP tooling: formatters, linters and the treesitter parser compiler.
-- mason-lspconfig only covers language servers, so these are installed directly
-- through the registry rather than pulling in another plugin.
-- jdtls is here rather than in mason_ensure_installed because nvim-jdtls
-- launches it itself (see metalpietie.lsp.jdtls); mason-lspconfig would only
-- try to wire it into vim.lsp.enable.
local tools = {
    "prettierd",
    "gofumpt",
    "goimports",
    "php-cs-fixer",
    "stylua",
    "tree-sitter-cli",

    -- Java / Minecraft modding
    "jdtls",
    "java-debug-adapter",
    "java-test",
    "google-java-format",
}

local ok, registry = pcall(require, "mason-registry")
if ok then
    registry.refresh(function()
        for _, name in ipairs(tools) do
            local found, pkg = pcall(registry.get_package, name)
            if found and not pkg:is_installed() then
                pkg:install()
            end
        end
    end)
end

require("fidget").setup({
    notification = {
        window = { winblend = 0 },
    },
})
