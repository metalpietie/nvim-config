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
    },
})

pcall(telescope.load_extension, "fzf")

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
