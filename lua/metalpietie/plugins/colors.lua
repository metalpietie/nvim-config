-- Global so `:lua ColorMyPencils()` still works from anywhere, same as before.
function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
end

require("rose-pine").setup({
    variant = "auto",
    dark_variant = "main",
    styles = {
        bold = true,
        italic = false,
        transparency = true,
    },
})

ColorMyPencils()
