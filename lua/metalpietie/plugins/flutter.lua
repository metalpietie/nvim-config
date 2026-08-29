-- flutter-tools starts dartls from the Flutter SDK itself, so dartls must not
-- also be installed/enabled through mason.

local flutter_path = vim.fn.expand("~/development/flutter/bin/flutter")

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
    capabilities = blink.get_lsp_capabilities(capabilities)
end

require("flutter-tools").setup({
    -- The SDK isn't on PATH on this machine, so point at it directly.
    flutter_path = vim.uv.fs_stat(flutter_path) and flutter_path or nil,

    debugger = {
        enabled = false,
        run_via_dap = false,
    },

    dev_log = {
        enabled = false,
        open_cmd = "tabedit",
    },

    widget_guides = { enabled = true },

    lsp = {
        capabilities = capabilities,
        -- Document color highlighting is a Neovim 0.12+ core feature now
        -- (enabled by default, background style) rather than flutter-tools'
        -- own lsp.color option, which is deprecated on 0.12+.
        settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            updateImportsOnRename = true,
        },
    },
})

vim.keymap.set("n", "<leader>Fr", "<cmd>FlutterRun<CR>", { desc = "Flutter run" })
vim.keymap.set("n", "<leader>FR", "<cmd>FlutterRestart<CR>", { desc = "Flutter restart" })
vim.keymap.set("n", "<leader>Fq", "<cmd>FlutterQuit<CR>", { desc = "Flutter quit" })
vim.keymap.set("n", "<leader>Fd", "<cmd>FlutterDevices<CR>", { desc = "Flutter devices" })
vim.keymap.set("n", "<leader>Fe", "<cmd>FlutterEmulators<CR>", { desc = "Flutter emulators" })
vim.keymap.set("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter outline" })
vim.keymap.set("n", "<leader>Fl", "<cmd>FlutterLogToggle<CR>", { desc = "Flutter log" })
