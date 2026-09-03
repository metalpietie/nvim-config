-- nvim-treesitter `main` branch. The old `require("nvim-treesitter.configs").setup`
-- API is gone: parsers are installed imperatively and highlighting is turned on
-- per-buffer with `vim.treesitter.start()`.
--
-- Needs the `tree-sitter` CLI on PATH to compile parsers.

local ts = require("nvim-treesitter")

ts.setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})

local parsers = {
    -- core
    "bash", "c", "comment", "diff", "lua", "luadoc", "query", "regex",
    "vim", "vimdoc", "printf",
    -- git
    "git_config", "git_rebase", "gitcommit", "gitignore",
    -- go
    "go", "gomod", "gosum", "gowork", "gotmpl", "templ",
    -- web / js / ts / angular / svelte
    "html", "css", "scss", "javascript", "typescript", "tsx", "jsdoc",
    "angular", "svelte", "vue",
    -- php / wordpress
    "php", "php_only", "phpdoc", "twig",
    -- dart / flutter
    "dart",
    -- java / minecraft modding (gradle builds are groovy or kotlin DSL,
    -- gradle.properties is `properties`)
    "java", "groovy", "kotlin", "properties",
    -- data & config
    -- jsonc is served by the `json` parser upstream; there is no separate one.
    "json", "json5", "yaml", "toml", "xml", "sql", "dockerfile",
    "markdown", "markdown_inline", "editorconfig", "ssh_config",
}

-- Only compile what is actually missing, otherwise every startup would rebuild
-- the whole list.
local ok, config = pcall(require, "nvim-treesitter.config")
if ok then
    local installed = {}
    for _, name in ipairs(config.get_installed("parsers")) do
        installed[name] = true
    end

    local missing = vim.tbl_filter(function(name)
        return not installed[name]
    end, parsers)

    if #missing > 0 then
        if vim.fn.executable("tree-sitter") == 0 then
            vim.notify(
                "tree-sitter CLI not found on PATH; cannot install parsers: "
                    .. table.concat(missing, ", "),
                vim.log.levels.WARN
            )
        else
            ts.install(missing)
        end
    end
end

-- Angular templates (*.component.html) get the `angular` parser; Neovim already
-- detects them as the `htmlangular` filetype.
vim.treesitter.language.register("angular", "htmlangular")
vim.treesitter.language.register("templ", "templ")
-- Neovim calls .properties files `jproperties`; the parser is named `properties`.
vim.treesitter.language.register("properties", "jproperties")

local group = vim.api.nvim_create_augroup("metalpietie-treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not vim.treesitter.language.add(lang) then
            return
        end

        vim.treesitter.start(ev.buf, lang)

        -- Treesitter indentation, where the parser supplies indents.
        local has_indents = not vim.tbl_isempty(
            vim.api.nvim_get_runtime_file("queries/" .. lang .. "/indents.scm", true)
        )
        if has_indents then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
