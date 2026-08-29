local ls = require("luasnip")

ls.setup({
    history = true,
    updateevents = "TextChanged,TextChangedI",
    enable_autosnippets = true,
})

require("luasnip.loaders.from_vscode").lazy_load()

-- Let one filetype pull in another's snippets.
ls.filetype_extend("javascript", { "jsdoc" })
ls.filetype_extend("typescript", { "jsdoc" })
ls.filetype_extend("php", { "html", "css", "javascript" })
ls.filetype_extend("htmlangular", { "html" })
ls.filetype_extend("svelte", { "html", "css", "javascript", "typescript" })

vim.keymap.set({ "i" }, "<C-s>e", function()
    ls.expand()
end, { silent = true, desc = "Expand snippet" })

vim.keymap.set({ "i", "s" }, "<C-s>;", function()
    ls.jump(1)
end, { silent = true, desc = "Next snippet node" })

vim.keymap.set({ "i", "s" }, "<C-s>,", function()
    ls.jump(-1)
end, { silent = true, desc = "Previous snippet node" })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end, { silent = true, desc = "Cycle snippet choice" })
