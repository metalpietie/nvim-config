-- Per-server configuration.
--
-- nvim-lspconfig ships an `lsp/<name>.lua` for each server, which Neovim 0.12
-- picks up off the runtimepath automatically. Everything here is an *override*
-- merged on top of that, applied via `vim.lsp.config()` in the sibling init.lua.
--
-- dartls is deliberately absent: flutter-tools owns it and starts it from the
-- Flutter SDK, not from mason. jdtls is absent for the same reason — nvim-jdtls
-- starts it per-project, see metalpietie.lsp.jdtls.

local M = {}

-- When no root marker matches, Neovim starts a server in single-file mode
-- anyway. That's wrong for project-scoped servers: angularls in a plain HTML
-- file, or the Symfony helper in a WordPress tree. Passing a root_dir function
-- that simply never calls `on_dir` keeps the server from starting at all.
local function require_root(markers)
    return function(bufnr, on_dir)
        local name = vim.api.nvim_buf_get_name(bufnr)
        local root = vim.fs.root(name ~= "" and name or bufnr, markers)
        if root then
            on_dir(root)
        end
    end
end

-- Server names as nvim-lspconfig knows them. mason-lspconfig maps these to the
-- matching mason package.
M.mason_ensure_installed = {
    "lua_ls",
    "gopls",
    "vtsls",
    "eslint",
    "angularls",
    "svelte",
    "html",
    "cssls",
    "tailwindcss",
    "emmet_language_server",
    "jsonls",
    "yamlls",
    "intelephense",
}

-- Servers to switch on: everything mason installs, plus anything found on PATH
-- that mason doesn't manage (appended below).
M.enable = vim.deepcopy(M.mason_ensure_installed)

M.configs = {}

--------------------------------------------------------------------------------
-- Lua
--------------------------------------------------------------------------------
M.configs.lua_ls = {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = {
                globals = {
                    "vim",
                    "it", "describe", "before_each", "after_each",
                    -- Defined by this config.
                    "ColorMyPencils", "R",
                },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            telemetry = { enable = false },
            hint = { enable = true },
        },
    },
}

--------------------------------------------------------------------------------
-- Go
--------------------------------------------------------------------------------
M.configs.gopls = {
    settings = {
        gopls = {
            gofumpt = true,
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            semanticTokens = true,
            analyses = {
                unusedparams = true,
                unusedwrite = true,
                nilness = true,
                shadow = true,
                useany = true,
            },
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
        },
    },
}

--------------------------------------------------------------------------------
-- TypeScript / JavaScript
--------------------------------------------------------------------------------
M.configs.vtsls = {
    settings = {
        vtsls = {
            -- Angular workspaces pin their own TypeScript; use it rather than
            -- whatever version vtsls bundles.
            autoUseWorkspaceTsdk = true,
            experimental = {
                completion = { enableServerSideFuzzyMatch = true },
            },
        },
        typescript = {
            tsdk = "node_modules/typescript/lib",
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
            },
        },
        javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
            },
        },
    },
}

M.configs.eslint = {
    settings = {
        workingDirectories = { mode = "auto" },
    },
}

--------------------------------------------------------------------------------
-- Angular
--------------------------------------------------------------------------------
-- lspconfig computes the ngserver/tsserver probe locations itself; all this does
-- is keep angularls out of projects that aren't Angular.
M.configs.angularls = {
    filetypes = { "typescript", "html", "htmlangular" },
    root_dir = require_root({ "angular.json", "project.json", "nx.json" }),
}

--------------------------------------------------------------------------------
-- Svelte
--------------------------------------------------------------------------------
M.configs.svelte = {
    on_attach = function(client, bufnr)
        -- The Svelte server needs telling when a .ts/.js file changes, or
        -- component types in .svelte files go stale.
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = vim.api.nvim_create_augroup("metalpietie-svelte-" .. bufnr, { clear = true }),
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
                client:notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(ctx.file) })
            end,
        })
    end,
}

--------------------------------------------------------------------------------
-- HTML / CSS / Emmet / Tailwind
--------------------------------------------------------------------------------
M.configs.html = {
    filetypes = { "html", "templ", "htmlangular" },
    init_options = {
        provideFormatter = false, -- prettier does this, via conform
    },
}

M.configs.cssls = {
    settings = {
        css = { validate = true, lint = { unknownAtRules = "ignore" } },
        scss = { validate = true, lint = { unknownAtRules = "ignore" } },
        less = { validate = true, lint = { unknownAtRules = "ignore" } },
    },
    init_options = {
        provideFormatter = false,
    },
}

M.configs.tailwindcss = {
    filetypes = {
        "html", "htmlangular", "css", "scss", "less", "php", "svelte",
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "templ", "dart",
    },
    -- Only in projects that actually use Tailwind. Tailwind v4 dropped the
    -- requirement for a tailwind.config.*/postcss.config.* file (config now
    -- lives in CSS via `@import "tailwindcss"`), so fall back to checking
    -- whether package.json actually depends on tailwindcss.
    root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root_files = {
            "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs",
            "tailwind.config.ts", "postcss.config.js", "postcss.config.ts",
        }
        root_files = require("lspconfig.util").insert_package_json(root_files, "tailwindcss", fname)
        local found = vim.fs.find(root_files, { path = fname, upward = true })[1]
        if found then
            on_dir(vim.fs.dirname(found))
        end
    end,
    settings = {
        tailwindCSS = {
            includeLanguages = {
                htmlangular = "html",
                templ = "html",
                php = "html",
            },
        },
    },
}

M.configs.emmet_language_server = {
    filetypes = {
        "html", "htmlangular", "css", "scss", "less", "php", "svelte",
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "templ",
    },
}

--------------------------------------------------------------------------------
-- PHP (+ WordPress)
--------------------------------------------------------------------------------
-- Intelephense reads its premium licence key from
-- ~/.config/intelephense/licence.txt on its own. The WordPress/WooCommerce/ACF
-- stubs below are bundled with intelephense and are free.
M.configs.intelephense = {
    filetypes = { "php" },
    root_markers = { "composer.json", "wp-config.php", "style.css", ".git" },
    settings = {
        intelephense = {
            stubs = {
                "bcmath", "bz2", "calendar", "Core", "curl", "date", "dba",
                "dom", "enchant", "fileinfo", "filter", "ftp", "gd", "gettext",
                "hash", "iconv", "imap", "intl", "json", "ldap", "libxml",
                "mbstring", "mcrypt", "mysql", "mysqli", "password", "pcntl",
                "pcre", "PDO", "pdo_mysql", "Phar", "readline", "recode",
                "Reflection", "regex", "session", "SimpleXML", "soap",
                "sockets", "sodium", "SPL", "standard", "superglobals",
                "sysvsem", "sysvshm", "tokenizer", "xml", "xdebug",
                "xmlreader", "xmlwriter", "yaml", "zip", "zlib",
                -- WordPress ecosystem
                "wordpress", "woocommerce", "acf-pro", "acf-stubs",
                "wordpress-globals", "wp-cli", "genesis", "polylang", "sbi",
            },
            format = {
                enable = true,
                braces = "k&r",
            },
            diagnostics = {
                enable = true,
                undefinedTypes = true,
                undefinedFunctions = true,
                undefinedConstants = true,
                undefinedClassConstants = true,
                undefinedMethods = true,
                undefinedProperties = true,
                undefinedVariables = true,
            },
            files = {
                -- WordPress core files blow past the default 1MB limit.
                maxSize = 10000000,
                associations = { "*.php", "*.phtml", "*.inc" },
            },
            environment = {
                includePaths = {
                    -- Point intelephense at a global WP install if one exists,
                    -- so core functions resolve outside a WP project root.
                    vim.fn.expand("~/.composer/vendor/php-stubs"),
                },
            },
        },
    },
}

-- Symfony helper (twig/service-container awareness). Only attaches in actual
-- Symfony projects so it stays out of WordPress work.
M.configs.vimfony = {
    cmd = { "vimfony" },
    filetypes = { "php", "twig", "yaml", "xml" },
    root_dir = require_root({ "symfony.lock", "bin/console" }),
    before_init = function(_, config)
        local root = config.root_dir
        if not root then
            return
        end
        config.init_options = {
            roots = { "templates" },
            container_xml_path = root .. "/var/cache/dev/App_KernelDevDebugContainer.xml",
            vendor_dir = root .. "/vendor",
        }
    end,
}

if vim.fn.executable("vimfony") == 1 then
    table.insert(M.enable, "vimfony")
end

--------------------------------------------------------------------------------
-- Data formats
--------------------------------------------------------------------------------
M.configs.jsonls = {
    settings = {
        json = { validate = { enable = true } },
    },
}

M.configs.yamlls = {
    settings = {
        yaml = {
            keyOrdering = false,
            schemaStore = { enable = true },
        },
    },
}

return M
