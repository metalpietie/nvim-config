-- Debug Adapter Protocol.
--
-- Java is what this exists for. Minecraft can't be launched from a DAP launch
-- config: the dev client only works when Gradle assembles the classpath and
-- applies the loader's tweaks. So the workflow is
--
--     :Gradle runClient --debug-jvm      (<leader>MR)
--
-- which forks a JVM that suspends on port 5005, and then <F5> -> "Attach to
-- Minecraft" from here.
--
-- The `java` *adapter* is registered by nvim-jdtls (jdtls.setup_dap) the first
-- time jdtls attaches to a buffer, so open a .java file before starting a
-- session. The configurations below are declared up front.

local dap = require("dap")
local dapui = require("dapui")

require("nvim-dap-virtual-text").setup({
    commented = true,
    virt_text_pos = "eol",
})

dapui.setup({
    icons = { expanded = "", collapsed = "", current_frame = "" },
    layouts = {
        {
            elements = {
                { id = "scopes", size = 0.4 },
                { id = "stacks", size = 0.3 },
                { id = "watches", size = 0.15 },
                { id = "breakpoints", size = 0.15 },
            },
            size = 45,
            position = "left",
        },
        {
            elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } },
            size = 12,
            position = "bottom",
        },
    },
    floating = { border = "rounded" },
})

--------------------------------------------------------------------------------
-- Signs
--------------------------------------------------------------------------------
local signs = {
    DapBreakpoint = { text = "●", texthl = "DiagnosticError" },
    DapBreakpointCondition = { text = "◆", texthl = "DiagnosticWarn" },
    DapLogPoint = { text = "◇", texthl = "DiagnosticInfo" },
    DapBreakpointRejected = { text = "○", texthl = "DiagnosticHint" },
    DapStopped = { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" },
}
for name, opts in pairs(signs) do
    vim.fn.sign_define(name, opts)
end

--------------------------------------------------------------------------------
-- Open the UI with the session, close it when the session ends.
--------------------------------------------------------------------------------
dap.listeners.after.event_initialized["metalpietie"] = function()
    dapui.open()
end
dap.listeners.before.event_terminated["metalpietie"] = function()
    dapui.close()
end
dap.listeners.before.event_exited["metalpietie"] = function()
    dapui.close()
end

--------------------------------------------------------------------------------
-- Java: attach configurations.
--
-- nvim-jdtls rewrites dap.configurations.java when it discovers the project's
-- main classes, so these are (re-)inserted just before the picker opens rather
-- than only once at startup.
--------------------------------------------------------------------------------
local java_attach = {
    {
        type = "java",
        request = "attach",
        name = "Attach to Minecraft (localhost:5005)",
        hostName = "127.0.0.1",
        port = 5005,
    },
    {
        type = "java",
        request = "attach",
        name = "Attach to JVM (choose port)",
        hostName = "127.0.0.1",
        port = function()
            return tonumber(vim.fn.input("Debug port: ", "5005"))
        end,
    },
}

local function continue()
    local configs = dap.configurations.java or {}
    local names = {}
    for _, config in ipairs(configs) do
        names[config.name] = true
    end

    for i, config in ipairs(java_attach) do
        if not names[config.name] then
            table.insert(configs, i, config)
        end
    end
    dap.configurations.java = configs

    dap.continue()
end

--------------------------------------------------------------------------------
-- Keymaps: function keys for stepping, <leader>D for everything else.
--------------------------------------------------------------------------------
local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = "Debug: " .. desc })
end

map("<F5>", continue, "start / continue")
map("<F10>", dap.step_over, "step over")
map("<F11>", dap.step_into, "step into")
map("<F12>", dap.step_out, "step out")

map("<leader>Db", dap.toggle_breakpoint, "toggle breakpoint")
map("<leader>DB", function()
    dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, "conditional breakpoint")
map("<leader>Dl", function()
    dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
end, "log point")
map("<leader>Dc", continue, "start / continue")
map("<leader>Do", dap.step_over, "step over")
map("<leader>Di", dap.step_into, "step into")
map("<leader>DO", dap.step_out, "step out")
map("<leader>Dr", dap.repl.toggle, "toggle repl")
map("<leader>Dh", require("dap.ui.widgets").hover, "hover value")
map("<leader>Du", dapui.toggle, "toggle UI")
map("<leader>Dx", function()
    dap.terminate()
    dapui.close()
end, "terminate session")
map("<leader>DC", dap.clear_breakpoints, "clear all breakpoints")
