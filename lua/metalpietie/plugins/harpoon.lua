local harpoon = require("harpoon")

harpoon:setup()

-- Note: <leader>a shares a prefix with the ng.nvim <leader>at/<leader>ac/<leader>aT
-- maps, so it fires after 'timeoutlen'. That's how it behaved before too.
vim.keymap.set("n", "<leader>a", function()
    harpoon:list():add()
end, { desc = "Harpoon add file" })

vim.keymap.set("n", "<C-e>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon menu" })

vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end, { desc = "Harpoon 1" })
vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end, { desc = "Harpoon 2" })
vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end, { desc = "Harpoon 3" })
vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end, { desc = "Harpoon 4" })
