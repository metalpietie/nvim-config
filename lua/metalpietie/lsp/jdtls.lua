-- Java LSP, tuned for Minecraft mod development (Fabric / NeoForge).
--
-- jdtls is deliberately absent from metalpietie.lsp.servers: `vim.lsp.enable`
-- can't drive it. Every project needs its own data directory, the launcher jar
-- has to be located inside the mason package, and the debug/test bundles are
-- passed at start time. nvim-jdtls owns all of that, and starts the server
-- per-buffer from after/ftplugin/java.lua.

local M = {}

local uv = vim.uv
local is_win = vim.fn.has("win32") == 1
local mason = vim.fn.stdpath("data") .. "/mason"
local jdtls_home = mason .. "/packages/jdtls"

local function glob(pattern)
    return vim.fn.glob(pattern, true, true)
end

--------------------------------------------------------------------------------
-- JDK discovery
--
-- Minecraft pins the Java version it builds against: 1.17–1.20.4 want JDK 17,
-- 1.20.5+ want JDK 21. jdtls itself needs 21 to run. Rather than hard-coding
-- paths, find every JDK on the machine and hand the whole list to jdtls as
-- `java.configuration.runtimes` so it can honour whatever toolchain a mod's
-- build.gradle asks for.
--------------------------------------------------------------------------------

local search = {
    "C:/Program Files/Java/*",
    "C:/Program Files/Eclipse Adoptium/*",
    "C:/Program Files/Microsoft/jdk*",
    "C:/Program Files/Amazon Corretto/*",
    "C:/Program Files/Zulu/*",
    "C:/Program Files/BellSoft/*",
    "C:/Program Files/Android/Android Studio/jbr",
    -- Gradle's toolchain auto-provisioning downloads JDKs here, which on a
    -- modding machine is often the only place a JDK 21 exists.
    vim.fn.expand("~/.gradle/jdks/*"),
    vim.fn.expand("~/.gradle/jdks/*/*"),
    -- IntelliJ-managed JDKs.
    vim.fn.expand("~/.jdks/*"),
    vim.fn.expand("~/scoop/apps/*jdk*/current"),
    vim.fn.expand("~/scoop/apps/temurin*/current"),
}

local function exe(home, name)
    local path = home .. "/bin/" .. name .. (is_win and ".exe" or "")
    return uv.fs_stat(path) and path or nil
end

--- Major version from a JDK's `release` file — much cheaper than shelling out
--- to `java -version` for every candidate on startup.
local function major_version(home)
    local f = io.open(home .. "/release", "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()

    local version = content:match('JAVA_VERSION="([^"]+)"')
    if not version then
        return nil
    end
    -- "1.8.0_412" -> 8, "17.0.11" -> 17, "21" -> 21
    return tonumber(version:match("^1%.(%d+)") or version:match("^(%d+)"))
end

local jdks

--- Every JDK found on this machine, newest first.
---@return { path: string, major: integer }[]
function M.jdks()
    if jdks then
        return jdks
    end

    jdks = {}
    local seen = {}

    local function add(home)
        if not home or home == "" then
            return
        end
        home = vim.fs.normalize(home)
        if seen[home] then
            return
        end
        seen[home] = true

        -- A JRE compiles nothing, and both jdtls and Gradle need javac.
        if not exe(home, "java") or not exe(home, "javac") then
            return
        end

        local major = major_version(home)
        if major then
            table.insert(jdks, { path = home, major = major })
        end
    end

    add(vim.env.JAVA_HOME)

    local on_path = vim.fn.exepath("java")
    if on_path ~= "" then
        -- <home>/bin/java -> <home>
        add(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(on_path))))
    end

    for _, pattern in ipairs(search) do
        for _, home in ipairs(glob(pattern)) do
            add(home)
        end
    end

    table.sort(jdks, function(a, b)
        return a.major > b.major
    end)

    return jdks
end

--- `java.configuration.runtimes`, one entry per major version.
local function runtimes()
    local out, seen = {}, {}
    for _, jdk in ipairs(M.jdks()) do
        if not seen[jdk.major] then
            seen[jdk.major] = true
            table.insert(out, {
                -- Eclipse execution environments: 8 is "JavaSE-1.8", every
                -- release since is "JavaSE-<major>".
                name = jdk.major <= 8 and ("JavaSE-1." .. jdk.major) or ("JavaSE-" .. jdk.major),
                path = jdk.path,
                default = #out == 0,
            })
        end
    end
    return out
end

--- The JDK that runs the language server itself. Current jdtls needs 21+.
local function server_java()
    for _, jdk in ipairs(M.jdks()) do
        if jdk.major >= 21 then
            return exe(jdk.path, "java")
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Debug + test bundles (java-debug-adapter, vscode-java-test via mason)
--------------------------------------------------------------------------------
local function bundles()
    local jars = glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")

    -- The test extension ships a standalone runner jar that must not be loaded
    -- into the language server; everything else in that directory is a bundle.
    for _, jar in ipairs(glob(mason .. "/packages/java-test/extension/server/*.jar")) do
        if not vim.endswith(jar, "com.microsoft.java.test.runner-jar-with-dependencies.jar") then
            table.insert(jars, jar)
        end
    end

    return jars
end

--------------------------------------------------------------------------------
-- Buffer-local keymaps: <leader>J for the jdtls-only actions. The generic LSP
-- maps (gd, K, <leader>vrn, ...) come from the LspAttach autocmd in
-- metalpietie.lsp.
--------------------------------------------------------------------------------
local function keymaps(bufnr)
    local jdtls = require("jdtls")

    local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("n", "<leader>Jo", jdtls.organize_imports, "Java: organize imports")
    map("n", "<leader>Jv", jdtls.extract_variable, "Java: extract variable")
    map("n", "<leader>Jc", jdtls.extract_constant, "Java: extract constant")
    map("v", "<leader>Jv", function()
        jdtls.extract_variable(true)
    end, "Java: extract variable")
    map("v", "<leader>Jc", function()
        jdtls.extract_constant(true)
    end, "Java: extract constant")
    map("v", "<leader>Jm", function()
        jdtls.extract_method(true)
    end, "Java: extract method")

    map("n", "<leader>Jt", jdtls.test_nearest_method, "Java: test method under cursor")
    map("n", "<leader>JT", jdtls.test_class, "Java: test class")

    -- After editing build.gradle: re-import the build so new dependencies
    -- (a new mod API, a bumped mappings version) resolve.
    map("n", "<leader>Ju", "<cmd>JdtUpdateConfig<CR>", "Java: update project config")
    map("n", "<leader>Jr", "<cmd>JdtRestart<CR>", "Java: restart jdtls")
end

--------------------------------------------------------------------------------
-- Start
--------------------------------------------------------------------------------
function M.start()
    if vim.bo.buftype ~= "" then
        return
    end

    local ok, jdtls = pcall(require, "jdtls")
    if not ok then
        return
    end

    local launcher = glob(jdtls_home .. "/plugins/org.eclipse.equinox.launcher_*.jar")[1]
    if not launcher then
        vim.notify_once(
            "jdtls is not installed. Run :Mason and install jdtls.",
            vim.log.levels.WARN
        )
        return
    end

    local java = server_java()
    if not java then
        vim.notify_once(
            "No JDK 21+ found. jdtls needs one to run, and Minecraft 1.20.5+ "
                .. "builds against 21. Install a JDK (Temurin 21) or set JAVA_HOME.",
            vim.log.levels.WARN
        )
        return
    end

    local root = require("metalpietie.gradle").root()
        or vim.fs.root(0, { "pom.xml", "mvnw", ".git" })
        or vim.fs.dirname(vim.api.nvim_buf_get_name(0))

    -- One data directory per project, and never a shared one: jdtls stores the
    -- whole compiled index there. The hash keeps two mods with the same
    -- directory name apart.
    local workspace = ("%s/jdtls/%s-%s"):format(
        vim.fn.stdpath("cache"),
        vim.fn.fnamemodify(root, ":t"),
        vim.fn.sha256(root):sub(1, 8)
    )

    local config_dir = jdtls_home
        .. (is_win and "/config_win" or (vim.fn.has("mac") == 1 and "/config_mac" or "/config_linux"))

    local cmd = {
        java,
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Dsun.zip.disableMemoryMapping=true",
        "-XX:+UseParallelGC",
        "-XX:GCTimeRatio=4",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-Xms100m",
        -- A decompiled Minecraft jar plus a mod's dependencies is a big index;
        -- the default 1G heap makes jdtls thrash on import.
        "-Xmx4g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-jar", launcher,
        "-configuration", config_dir,
        "-data", workspace,
    }

    local lombok = jdtls_home .. "/lombok.jar"
    if uv.fs_stat(lombok) then
        table.insert(cmd, 2, "-javaagent:" .. lombok)
    end

    -- Same capabilities the rest of the servers get; nvim-jdtls calls
    -- vim.lsp.start() directly, which doesn't pick up the "*" config from
    -- metalpietie.lsp.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok_blink, blink = pcall(require, "blink.cmp")
    if ok_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
    end

    local extended = vim.tbl_deep_extend("force", jdtls.extendedClientCapabilities or {}, {
        resolveAdditionalTextEditsSupport = true,
    })

    local jars = bundles()

    jdtls.start_or_attach({
        name = "jdtls",
        cmd = cmd,
        root_dir = root,
        capabilities = capabilities,
        init_options = {
            bundles = jars,
            extendedClientCapabilities = extended,
        },
        settings = {
            java = {
                signatureHelp = { enabled = true },
                -- Fernflower decompiles library classes that ship without
                -- sources, so `gd` into Minecraft internals lands on something
                -- readable even before `gradlew genSources`.
                contentProvider = { preferred = "fernflower" },
                references = { includeDecompiledSources = true },
                eclipse = { downloadSources = true },
                maven = { downloadSources = true },
                errors = { incompleteClasspath = { severity = "warning" } },

                configuration = {
                    -- Mod builds are slow to import; re-import on demand
                    -- (<leader>Ju) rather than on every build.gradle write.
                    updateBuildConfiguration = "interactive",
                    runtimes = runtimes(),
                },

                import = {
                    gradle = {
                        enabled = true,
                        -- Loom and NeoGradle pin a Gradle version in the
                        -- wrapper; using anything else breaks the import.
                        wrapper = { enabled = true },
                    },
                    maven = { enabled = true },
                    exclusions = {
                        "**/node_modules/**",
                        "**/.metadata/**",
                        -- The Minecraft run directory: worlds, logs, resource
                        -- packs, and a copy of every mod in the dev launch.
                        "**/run/**",
                        "**/.gradle/**",
                    },
                },

                completion = {
                    importOrder = { "java", "javax", "com", "org", "net" },
                    favoriteStaticMembers = {
                        "org.junit.jupiter.api.Assertions.*",
                        "org.junit.Assert.*",
                        "java.util.Objects.requireNonNull",
                        "java.util.Objects.requireNonNullElse",
                    },
                    -- java.awt in particular: it has a Color, a List, a
                    -- Component and a Font too, and its completions bury the
                    -- Minecraft ones.
                    filteredTypes = {
                        "java.awt.*",
                        "com.sun.*",
                        "sun.*",
                        "jdk.*",
                        "io.micrometer.shaded.*",
                    },
                },

                sources = {
                    organizeImports = {
                        -- Mixin and registry classes import a lot from one
                        -- package; star imports there are unreadable.
                        starThreshold = 9999,
                        staticStarThreshold = 9999,
                    },
                },

                codeGeneration = {
                    useBlocks = true,
                    hashCodeEquals = { useJava7Objects = true },
                    toString = {
                        template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                    },
                },

                inlayHints = { parameterNames = { enabled = "literals" } },
            },
        },
        on_attach = function(_, bufnr)
            keymaps(bufnr)

            if #jars > 0 and pcall(require, "dap") then
                require("jdtls").setup_dap({ hotcodereplace = "auto" })
                -- Discovers `main` classes for launch configs. Minecraft itself
                -- is started by Gradle, so the configuration that matters is
                -- the attach one in metalpietie.plugins.dap.
                pcall(require("jdtls.dap").setup_dap_main_class_configs)
            end
        end,
    })
end

return M
