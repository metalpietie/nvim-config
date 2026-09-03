-- Gradle glue for Minecraft mod projects (Fabric Loom / NeoGradle).
--
-- Every mod loader drives the toolchain through the project's own Gradle
-- wrapper: `gradlew runClient` launches Minecraft, `genSources` decompiles it,
-- `runDatagen` regenerates the JSON. This module runs those in a terminal split
-- and exposes the project root, which metalpietie.lsp.jdtls reuses.

local M = {}

local is_win = vim.fn.has("win32") == 1

--- Directory to start an upward search from, for any buffer.
local function start_dir(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr or 0)
    -- jdt:// and other URI buffers have no on-disk path.
    if path == "" or path:match("^%a[%w+.%-]*://") then
        return vim.uv.cwd()
    end
    return vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
end

--- Root of the Gradle build a buffer belongs to, or nil.
---
--- Multi-loader mod templates (Architectury and friends) nest `common/`,
--- `fabric/` and `neoforge/` subprojects — each with its own build.gradle —
--- under a single settings.gradle. Taking the *outermost* settings file means
--- jdtls imports the whole build as one workspace; anchoring on the nearest
--- build.gradle instead would leave `common/` unresolvable from the loader
--- subprojects.
---@param bufnr integer|nil
---@return string|nil
function M.root(bufnr)
    local dir = start_dir(bufnr)
    if not dir then
        return nil
    end

    local settings = vim.fs.find({ "settings.gradle", "settings.gradle.kts" }, {
        path = dir,
        upward = true,
        limit = math.huge,
    })
    if #settings > 0 then
        return vim.fs.dirname(settings[#settings])
    end

    local build = vim.fs.find({ "gradlew", "build.gradle", "build.gradle.kts" }, {
        path = dir,
        upward = true,
    })[1]
    return build and vim.fs.dirname(build) or nil
end

--- The wrapper script for a build, falling back to a `gradle` on PATH.
---@param root string
---@return string|nil
function M.wrapper(root)
    local wrapper = root .. (is_win and "/gradlew.bat" or "/gradlew")
    if vim.uv.fs_stat(wrapper) then
        return wrapper
    end
    return vim.fn.executable("gradle") == 1 and "gradle" or nil
end

--- Run gradle tasks in a terminal split at the bottom.
---@param args string[]
function M.run(args)
    local root = M.root()
    if not root then
        vim.notify("No Gradle project found for this buffer.", vim.log.levels.WARN)
        return
    end

    local wrapper = M.wrapper(root)
    if not wrapper then
        vim.notify(
            "No gradlew in " .. root .. " and no gradle on PATH.",
            vim.log.levels.ERROR
        )
        return
    end

    local cmd = vim.list_extend({ wrapper }, args)

    -- A fresh empty buffer, because jobstart({term = true}) takes over the
    -- current one.
    vim.cmd("botright new")
    vim.bo.bufhidden = "wipe"
    local bufnr = vim.api.nvim_get_current_buf()

    vim.fn.jobstart(cmd, {
        term = true,
        cwd = root,
        on_exit = function(_, code)
            local level = code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
            vim.notify(("gradle %s exited %d"):format(table.concat(args, " "), code), level)
        end,
    })

    vim.api.nvim_buf_set_name(bufnr, "gradle://" .. table.concat(args, " "))
    -- Terminals scroll; follow the output rather than sitting at the top.
    vim.cmd("normal! G")
end

-- Tasks worth completing: the Gradle basics plus the ones Loom and NeoGradle
-- add. Not exhaustive — `:Gradle <anything>` still works.
local tasks = {
    "build", "clean", "jar", "test", "check", "assemble",
    "runClient", "runServer", "runData", "runDatagen", "runGameTest",
    "genSources", "genSourcesWithVineflower", "migrateMappings",
    "remapJar", "publishToMavenLocal", "dependencies", "tasks",
    "--refresh-dependencies", "--debug-jvm", "--stacktrace", "--info", "--offline",
}

vim.api.nvim_create_user_command("Gradle", function(opts)
    M.run(opts.fargs)
end, {
    nargs = "+",
    desc = "Run the project's Gradle wrapper in a terminal split",
    complete = function(lead)
        return vim.tbl_filter(function(task)
            return vim.startswith(task, lead)
        end, tasks)
    end,
})

vim.api.nvim_create_user_command("GradleRoot", function()
    vim.notify(M.root() or "No Gradle project found for this buffer.")
end, { desc = "Show the Gradle root of the current buffer" })

--------------------------------------------------------------------------------
-- Keymaps: <leader>M for Minecraft. Global rather than buffer-local, so they
-- work from build.gradle and the mod's JSON files too.
--------------------------------------------------------------------------------
local function map(lhs, args, desc)
    vim.keymap.set("n", "<leader>M" .. lhs, function()
        M.run(args)
    end, { desc = "Gradle: " .. desc })
end

map("b", { "build" }, "build")
map("c", { "clean" }, "clean")
map("r", { "runClient" }, "runClient")
map("R", { "runClient", "--debug-jvm" }, "runClient, waiting for the debugger")
map("s", { "runServer" }, "runServer")
map("d", { "runDatagen" }, "runDatagen")
map("g", { "genSources" }, "genSources (decompile Minecraft)")
map("t", { "test" }, "test")
map("f", { "build", "--refresh-dependencies" }, "build --refresh-dependencies")

vim.keymap.set("n", "<leader>Mu", function()
    -- :JdtUpdateConfig only exists once jdtls has attached to a Java buffer.
    if vim.fn.exists(":JdtUpdateConfig") == 2 then
        vim.cmd.JdtUpdateConfig()
    else
        vim.notify("jdtls is not attached; open a .java file first.", vim.log.levels.WARN)
    end
end, { desc = "Gradle: re-import the build into jdtls" })

return M
