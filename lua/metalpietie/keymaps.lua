vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move the visual selection up/down, reindenting as it goes.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Join without moving the cursor.
vim.keymap.set("n", "J", "mzJ`z")

-- Keep the cursor centred while jumping around.
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste over a selection without clobbering the unnamed register.
vim.keymap.set("x", "<leader>p", [["_dP]])

-- System clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>pc", [["+p]])

-- Delete to the black hole register.
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<leader>f", function()
    require("conform").format({ lsp_format = "fallback" })
end, { desc = "Format buffer" })

-- Quickfix / location list
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Substitute the word under the cursor across the buffer.
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Go error boilerplate
vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>")
vim.keymap.set("n", "<leader>ei", "o// GET<Esc>o<CR>// POST<Esc>o<CR>// PUT<Esc>o<CR>// PATCH<Esc>o<CR>// DELETE<Esc>o<CR>// STATIC<Esc>gg2j<Esc>")

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end, { desc = "Source current file" })

-- Plugin management (vim.pack)
vim.keymap.set("n", "<leader>pu", function()
    vim.pack.update()
end, { desc = "Update plugins" })
