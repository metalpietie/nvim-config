-- Plugin management via Neovim 0.12's built-in `vim.pack`.
--
-- `vim.pack.add` clones anything missing (synchronously, on first start only),
-- puts it on the runtimepath and sources its plugin/ files. There are no build
-- hooks in the spec, so plugins that need compiling are handled by the
-- PackChanged autocmd below — which must be registered *before* add() runs.

local build_steps = {
    -- jsregexp powers LuaSnip's regex transformations. Optional: LuaSnip works
    -- without it, so a failure here is a warning rather than an error.
    ["LuaSnip"] = { "make", "install_jsregexp" },
    ["telescope-fzf-native.nvim"] = { "make" },
}

vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("metalpietie-pack-build", { clear = true }),
    callback = function(ev)
        local data = ev.data
        if data.kind == "delete" then
            return
        end

        local cmd = build_steps[data.spec.name]
        if not cmd then
            return
        end

        vim.notify(("Building %s..."):format(data.spec.name), vim.log.levels.INFO)
        local result = vim.system(cmd, { cwd = data.path }):wait()
        if result.code ~= 0 then
            vim.notify(
                ("Build failed for %s:\n%s"):format(data.spec.name, result.stderr or ""),
                vim.log.levels.WARN
            )
        end
    end,
})

local function gh(repo, opts)
    local spec = vim.tbl_extend("force", { src = "https://github.com/" .. repo }, opts or {})
    return spec
end

vim.pack.add({
    -- Colours
    gh("rose-pine/neovim", { name = "rose-pine" }),

    -- Library used by telescope / harpoon / flutter-tools
    gh("nvim-lua/plenary.nvim"),
    gh("nvim-tree/nvim-web-devicons"),

    -- Syntax & structure
    gh("nvim-treesitter/nvim-treesitter", { version = "main" }),

    -- Fuzzy finding
    gh("nvim-telescope/telescope.nvim"),
    gh("nvim-telescope/telescope-fzf-native.nvim"),

    -- UI
    gh("rcarriga/nvim-notify"),
    gh("nvim-lualine/lualine.nvim"),
    gh("j-hui/fidget.nvim"),

    -- Git
    gh("tpope/vim-fugitive"),

    -- LSP: mason installs the servers, nvim-lspconfig ships the lsp/ configs
    -- that Neovim 0.12 reads natively via `vim.lsp.enable`.
    gh("mason-org/mason.nvim"),
    gh("mason-org/mason-lspconfig.nvim"),
    gh("neovim/nvim-lspconfig"),

    -- Completion + snippets. Both are pinned to a major version: blink.cmp
    -- only downloads its prebuilt fuzzy-matcher binary on tagged releases
    -- (there is no rust toolchain on this machine to build it from source).
    gh("Saghen/blink.cmp", { version = vim.version.range("1") }),
    gh("L3MON4D3/LuaSnip", { version = vim.version.range("2") }),
    gh("rafamadriz/friendly-snippets"),

    -- Formatting
    gh("stevearc/conform.nvim"),

    -- Language extras
    gh("nvim-flutter/flutter-tools.nvim"),
    gh("joeveiga/ng.nvim"),

    -- Navigation
    gh("ThePrimeagen/harpoon", { version = "harpoon2" }),
    gh("mbbill/undotree"),
})

-- Plugin configuration. Colours first so everything else inherits the palette.
-- mason before treesitter: mason.setup() prepends its bin dir (tree-sitter
-- CLI lives there) to $PATH, and treesitter's install check needs that done
-- first or it wrongly reports the CLI as missing on a fresh install.
require("metalpietie.plugins.colors")
require("metalpietie.plugins.notify")
require("metalpietie.plugins.mason")
require("metalpietie.plugins.treesitter")
require("metalpietie.plugins.telescope")
require("metalpietie.plugins.lualine")
require("metalpietie.plugins.fugitive")
require("metalpietie.plugins.snippets")
require("metalpietie.plugins.completion")
require("metalpietie.plugins.conform")
require("metalpietie.plugins.flutter")
require("metalpietie.plugins.ng")
require("metalpietie.plugins.harpoon")
require("metalpietie.plugins.undotree")
