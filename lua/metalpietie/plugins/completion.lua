-- blink.cmp, mapped to the same keys the old nvim-cmp setup used:
--   <C-p>/<C-n> cycle, <C-y> accept, <C-Space> open the menu.
-- `preset = "none"` is deliberate: blink's default preset grabs <C-e>, which
-- LuaSnip uses for cycling choice nodes.

require("blink.cmp").setup({
    keymap = {
        preset = "none",

        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-y>"] = { "select_and_accept", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },

    snippets = { preset = "luasnip" },

    appearance = {
        nerd_font_variant = "mono",
    },

    completion = {
        -- Nothing is preselected; <C-y> accepts whatever is highlighted.
        list = { selection = { preselect = false, auto_insert = true } },
        menu = {
            border = "rounded",
            draw = { treesitter = { "lsp" } },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
            window = { border = "rounded" },
        },
        ghost_text = { enabled = false },
    },

    signature = {
        enabled = true,
        window = { border = "rounded" },
    },

    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
            -- Angular templates want the LSP first and buffer words as filler.
            htmlangular = { "lsp", "snippets", "buffer" },
        },
    },

    -- No rust toolchain on this box, so the prebuilt binary is downloaded for
    -- the pinned release tag. If that ever fails, blink falls back to the pure
    -- Lua matcher and warns instead of erroring.
    fuzzy = { implementation = "prefer_rust_with_warning" },

    cmdline = {
        enabled = true,
        keymap = {
            preset = "none",
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
            ["<C-y>"] = { "select_and_accept", "fallback" },
            ["<C-Space>"] = { "show" },
        },
        completion = { menu = { auto_show = true } },
    },
})
