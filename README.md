# nvim

Neovim config built on the **0.12 built-in plugin manager** (`vim.pack`).
No lazy.nvim, no bootstrap script — `vim.pack.add` clones what's missing on
first start.

## Requirements

- **Neovim 0.12+** (`init.lua` refuses to load on anything older)
- `git`, `curl`, `tar`, a C compiler — for `vim.pack` and treesitter parsers
- `tree-sitter` CLI — compiles parsers. Installed via mason (`tree-sitter`),
  also available from `npm i -g tree-sitter-cli`
- Optional per language: `go`, `node`/`npm`, `php`/`composer`,
  Flutter SDK at `~/development/flutter`
- **JDK 21+** for Java / Minecraft modding — jdtls won't start without one.
  See [Minecraft modding](#minecraft-modding).

## Layout

```
init.lua                      version guard -> require("metalpietie")
lua/metalpietie/
  init.lua                    load order
  options.lua                 vim.opt settings, filetype overrides
  keymaps.lua                 global keymaps (leader = <Space>)
  pack.lua                    vim.pack plugin list + build hooks
  autocmds.lua                yank highlight, trailing-whitespace trim
  lsp/init.lua                capabilities, diagnostics, LspAttach keymaps
  lsp/servers.lua             per-server config + mason ensure_installed
  lsp/jdtls.lua               jdtls launcher: JDK discovery, Minecraft settings
  gradle.lua                  :Gradle, project root, <leader>M maps
  plugins/*.lua               one file per plugin
after/ftplugin/go.lua         Go uses tabs
after/ftplugin/java.lua       starts jdtls for the buffer
after/ftplugin/mcfunction.lua datapack functions
```

## Plugins

Managed by `vim.pack`. Update everything with `<leader>pu` (`vim.pack.update()`).

treesitter · telescope (+fzf-native) · nvim-notify · fugitive · LuaSnip
(+friendly-snippets) · lualine · blink.cmp · mason (+mason-lspconfig) ·
nvim-lspconfig · conform · flutter-tools · ng.nvim · nvim-jdtls · nvim-dap
(+dap-ui, nvim-nio, dap-virtual-text) · harpoon2 · undotree · fidget · rose-pine

Two plugins need compiling; `pack.lua` handles it through the `PackChanged`
autocmd (`vim.pack` has no build field): LuaSnip's `jsregexp` and
`telescope-fzf-native`.

## Language support

| Language | LSP | Formatter |
|---|---|---|
| Go | `gopls` (gofumpt, staticcheck, inlay hints) | `goimports` + `gofumpt`, **on save** |
| TypeScript / JavaScript | `vtsls`, `eslint` | prettier |
| Angular | `angularls` + `vtsls` | prettier |
| Svelte | `svelte` | prettier |
| HTML / CSS | `html`, `cssls`, `emmet`, `tailwindcss` | prettier |
| PHP / WordPress | `intelephense` (WP/Woo/ACF stubs) | `php-cs-fixer` |
| Symfony | `vimfony` (only in Symfony projects) | — |
| Dart / Flutter | `dartls` via flutter-tools | `dart_format` |
| Java / Minecraft | `jdtls` via nvim-jdtls (+ debugger, test runner) | `google-java-format --aosp` |
| Lua | `lua_ls` | `stylua` |

Go is the only filetype that formats on save; everything else is `<leader>f`.

`angularls`, `tailwindcss` and `vimfony` are project-scoped: they use a
`root_dir` function that never starts the server when no marker matches.
Without that, Neovim falls back to single-file mode and loads them in every
plain `.html`/`.php` buffer.

`*.component.html` is mapped to the `htmlangular` filetype so Angular templates
get the `angular` parser and template-aware diagnostics.

### Intelephense premium

Free stubs (WordPress included) work as-is. If you have a licence key, put it in
`~/.config/intelephense/licence.txt` — intelephense reads it itself.

## Minecraft modding

Set up for **Fabric** and **NeoForge**. mason installs `jdtls`,
`java-debug-adapter`, `java-test` and `google-java-format`; nothing else needs
configuring per project.

### JDK

Install a JDK yourself — mason does not ship one, and jdtls needs **21+** to
run. Minecraft 1.20.5 and newer also compile against 21 (1.17–1.20.4 want 17).
[Temurin](https://adoptium.net/) is the usual choice; the Minecraft launcher's
bundled runtimes are JREs and won't do, since Gradle needs `javac`.

`lsp/jdtls.lua` finds JDKs on its own — `JAVA_HOME`, `java` on `PATH`,
`C:\Program Files\{Java,Eclipse Adoptium,Microsoft,Amazon Corretto,Zulu}`,
`~/.gradle/jdks` (Gradle's toolchain downloads) and `~/.jdks` — and hands the
whole set to jdtls as `java.configuration.runtimes`, so a build.gradle asking
for a toolchain other than the newest one still resolves. `:lua vim.print(
require("metalpietie.lsp.jdtls").jdks())` shows what it found.

### Project import

jdtls uses the *outermost* `settings.gradle`, so multi-loader templates
(Architectury: `common/`, `fabric/`, `neoforge/` under one build) import as a
single workspace instead of three disconnected ones. The Gradle wrapper is
always used, since Loom and NeoGradle pin the version they need.

Import is set to `interactive`: after editing `build.gradle` (new dependency,
bumped mappings), re-import with `<leader>Ju` — it doesn't happen on save,
because a mod re-import is slow.

Run `<leader>Mg` (`gradlew genSources`) once per project to decompile Minecraft;
`gd` into vanilla classes then lands in real sources. Until that runs, jdtls
falls back to Fernflower for classes without sources.

### Debugging the game

Minecraft can't be started from a debug config — the dev client only works with
the classpath and loader tweaks Gradle applies. So:

1. `<leader>MR` → `gradlew runClient --debug-jvm`. The forked JVM suspends and
   listens on port 5005.
2. `<F5>` → **Attach to Minecraft (localhost:5005)**.

Breakpoints, stepping and hot code replace work from there. The `java` DAP
adapter is registered when jdtls attaches, so open a `.java` file before `<F5>`.

### Filetypes

`*.mcmeta` → JSON · `*.accesswidener` and `*.accesstransformer.cfg` → `conf` ·
`*.mcfunction` → own filetype with `#` comments. `fabric.mod.json`,
`neoforge.mods.toml` and mixin configs are covered by their extensions already.

## Keybindings

Leader is `<Space>`, local leader `\`.

### Editing
| Key | Action |
|---|---|
| `<leader>pv` | netrw / file explorer |
| `J` / `K` (visual) | move selection down / up |
| `J` (normal) | join, keep cursor |
| `<C-d>` / `<C-u>` | half-page scroll, centred |
| `n` / `N` | next / prev search, centred |
| `<leader>p` (visual) | paste over selection, keep register |
| `<leader>y` / `<leader>Y` | yank to system clipboard |
| `<leader>pc` | paste from system clipboard |
| `<leader>d` | delete to black hole |
| `<C-c>` (insert) | escape |
| `Q` | disabled |
| `<leader>s` | substitute word under cursor |
| `<leader>f` | format buffer (conform) |
| `<leader><leader>` | source current file |
| `<leader>ee` / `<leader>ei` | Go error block / REST comment scaffold |

### Navigation
| Key | Action |
|---|---|
| `<C-k>` / `<C-j>` | quickfix next / prev |
| `<leader>k` / `<leader>j` | loclist next / prev |
| `<leader>a` | harpoon: add file |
| `<C-e>` | harpoon: menu |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | harpoon: slots 1–4 |
| `<leader>u` | undotree |

### Telescope
| Key | Action |
|---|---|
| `<leader>pf` | find files |
| `<C-p>` | git files |
| `<leader>ps` | live grep |
| `<leader>pws` / `<leader>pWs` | grep word / WORD under cursor |
| `<leader>vh` | help tags |

### LSP (buffer-local)
| Key | Action |
|---|---|
| `gd` | definition |
| `K` | hover |
| `<leader>vrr` / `<leader>vrn` | references / rename |
| `<leader>vca`, `<leader>b` | code action |
| `<leader>vws` | workspace symbol |
| `<leader>vd` | line diagnostics |
| `<leader>vi` | toggle inlay hints |
| `<C-Space>` | signature help |
| `[d` / `]d` | next / prev diagnostic (kept inverted, as before) |

### Completion (blink.cmp, insert mode)
| Key | Action |
|---|---|
| `<C-p>` / `<C-n>` | previous / next item |
| `<C-y>` | accept |
| `<C-Space>` | open menu / toggle docs |
| `<C-b>` / `<C-f>` | scroll docs |

`preset = "none"` is deliberate — blink's default preset takes `<C-e>`, which
LuaSnip uses.

### Snippets (LuaSnip)
| Key | Action |
|---|---|
| `<C-s>e` | expand |
| `<C-s>;` / `<C-s>,` | next / previous node |
| `<C-E>` | cycle choice node |

### Git (fugitive)
| Key | Action |
|---|---|
| `<leader>gs` | git status |
| `<leader>p` / `<leader>P` | push / pull --rebase *(in fugitive buffer)* |
| `<leader>t` | `:Git push -u origin ` *(in fugitive buffer)* |
| `gu` / `gh` | diffget //2 (ours) / //3 (theirs) |

### Angular (ng.nvim)
| Key | Action |
|---|---|
| `<leader>at` | go to template |
| `<leader>ac` | go to component |
| `<leader>aT` | template type-check block |

### Flutter
`<leader>Fr` run · `<leader>FR` restart · `<leader>Fq` quit · `<leader>Fd`
devices · `<leader>Fe` emulators · `<leader>Fo` outline · `<leader>Fl` log

### Java (buffer-local, jdtls)
| Key | Action |
|---|---|
| `<leader>Jo` | organize imports |
| `<leader>Jv` / `<leader>Jc` | extract variable / constant (normal + visual) |
| `<leader>Jm` (visual) | extract method |
| `<leader>Jt` / `<leader>JT` | test method under cursor / test class |
| `<leader>Ju` | re-import the Gradle build (`:JdtUpdateConfig`) |
| `<leader>Jr` | restart jdtls |

### Gradle / Minecraft
`:Gradle {task…}` runs the project's wrapper in a terminal split (with task
completion); `:GradleRoot` shows the detected build root.

| Key | Task |
|---|---|
| `<leader>Mb` / `<leader>Mc` | `build` / `clean` |
| `<leader>Mr` / `<leader>MR` | `runClient` / `runClient --debug-jvm` |
| `<leader>Ms` | `runServer` |
| `<leader>Md` | `runDatagen` |
| `<leader>Mg` | `genSources` (decompile Minecraft) |
| `<leader>Mt` | `test` |
| `<leader>Mf` | `build --refresh-dependencies` |
| `<leader>Mu` | re-import into jdtls |

### Debugging (nvim-dap)
| Key | Action |
|---|---|
| `<F5>` / `<leader>Dc` | start or continue (picks a configuration) |
| `<F10>` `<F11>` `<F12>` | step over / into / out |
| `<leader>Do` `<leader>Di` `<leader>DO` | step over / into / out |
| `<leader>Db` / `<leader>DB` | breakpoint / conditional breakpoint |
| `<leader>Dl` | log point |
| `<leader>DC` | clear all breakpoints |
| `<leader>Dh` | hover value under cursor |
| `<leader>Dr` / `<leader>Du` | toggle repl / toggle UI |
| `<leader>Dx` | terminate session |

### Misc
`<leader>nd` dismiss notifications · `<leader>pu` update plugins

> `<leader>a` (harpoon) shares a prefix with `<leader>at`/`<leader>ac`/`<leader>aT`
> (ng.nvim), so it fires after `timeoutlen`. This matches the previous config.
