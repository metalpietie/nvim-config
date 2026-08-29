-- Order matters: options and leader keys must be set before plugins load,
-- because plugins read them at setup time.
require("metalpietie.options")
require("metalpietie.keymaps")
require("metalpietie.pack")
require("metalpietie.autocmds")
require("metalpietie.lsp")

-- Reload a lua module by name. Handy during config hacking.
function R(name)
    require("plenary.reload").reload_module(name)
end
