vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })

local group = vim.api.nvim_create_augroup("metalpietie-fugitive", { clear = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    pattern = "*",
    callback = function()
        if vim.bo.ft ~= "fugitive" then
            return
        end

        local opts = { buffer = vim.api.nvim_get_current_buf(), remap = false }

        vim.keymap.set("n", "<leader>p", function()
            vim.cmd.Git("push")
        end, opts)

        -- Rebase always.
        vim.keymap.set("n", "<leader>P", function()
            vim.cmd.Git({ "pull", "--rebase" })
        end, opts)

        -- Set the upstream branch when it wasn't configured up front.
        vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts)
    end,
})

-- Merge conflict resolution: take ours / take theirs.
vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
