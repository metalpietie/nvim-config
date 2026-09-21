local telescope = require("telescope")

telescope.setup({
    defaults = {
        path_display = { "truncate" },
        file_ignore_patterns = {
            "^%.git/", "/%.git/",
            "node_modules/", "vendor/", "%.dart_tool/", "build/",
        },
    },
    pickers = {
        find_files = {
            hidden = true,
        },
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },

        -- Renders vim.ui.select (LSP code actions, and anything else that
        -- asks the user to pick from a list) as a Telescope popup anchored
        -- at the cursor, instead of the default bottom-of-screen prompt.
        ["ui-select"] = {
            require("telescope.themes").get_cursor({
                layout_config = { width = 60, height = 12 },

                -- <C-y> confirms, to match the blink.cmp completion menu. A
                -- per-picker `mappings` table is ignored here (telescope only
                -- reads the global one), so attach the mapping instead. This
                -- runs after ui-select's own attach_mappings, which is what
                -- swaps select_default for the on_choice callback.
                attach_mappings = function(_, map)
                    map({ "i", "n" }, "<C-y>", require("telescope.actions").select_default)
                    return true
                end,
            }),
        },
    },
})

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "ui-select")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Find git files" })

vim.keymap.set("n", "<leader>pws", function()
    builtin.grep_string({ search = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })

vim.keymap.set("n", "<leader>pWs", function()
    builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
end, { desc = "Grep WORD under cursor" })

vim.keymap.set("n", "<leader>ps", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>vh", builtin.help_tags, { desc = "Help tags" })
