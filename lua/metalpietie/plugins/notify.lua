local notify = require("notify")

notify.setup({
    background_colour = "#000000",
    render = "compact",
    stages = "static",
    timeout = 3000,
})

vim.notify = notify

vim.keymap.set("n", "<leader>nd", function()
    notify.dismiss({ silent = true, pending = true })
end, { desc = "Dismiss notifications" })
