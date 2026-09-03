-- 4-space indent is the global default already, and it's what both Fabric and
-- NeoForge use, so only the ruler needs moving: Minecraft sources and mixin
-- signatures run well past 80 columns.
vim.opt_local.colorcolumn = "120"

require("metalpietie.lsp.jdtls").start()
