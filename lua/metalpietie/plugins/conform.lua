local conform = require("conform")

local prettier = { "prettierd", "prettier", stop_after_first = true }

conform.setup({
    formatters_by_ft = {
        go = { "goimports", "gofumpt" },

        html = prettier,
        htmlangular = prettier,
        css = prettier,
        scss = prettier,
        less = prettier,
        javascript = prettier,
        javascriptreact = prettier,
        typescript = prettier,
        typescriptreact = prettier,
        svelte = prettier,
        json = prettier,
        jsonc = prettier,
        yaml = prettier,
        markdown = prettier,

        php = { "php_cs_fixer" },
        dart = { "dart_format" },
        lua = { "stylua" },
        java = { "google-java-format" },
    },

    formatters = {
        -- Google's own style is 2-space; --aosp switches it to the 4-space
        -- variant, which is what Minecraft, Fabric and NeoForge sources use.
        ["google-java-format"] = {
            prepend_args = { "--aosp" },
        },
    },

    -- Only Go formats automatically, matching the previous BufWritePre hook.
    -- Everything else is on demand with <leader>f.
    format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype ~= "go" then
            return nil
        end
        return { timeout_ms = 3000, lsp_format = "fallback" }
    end,
})
