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
  plugins/*.lua               one file per plugin
after/ftplugin/go.lua         Go uses tabs
```

## Plugins

Managed by `vim.pack`. Update everything with `<leader>pu` (`vim.pack.update()`).

treesitter · telescope (+fzf-native) · nvim-notify · fugitive · LuaSnip
(+friendly-snippets) · lualine · blink.cmp · mason (+mason-lspconfig) ·
nvim-lspconfig · conform · flutter-tools · ng.nvim · harpoon2 · undotree ·
fidget · rose-pine

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

### Misc
`<leader>nd` dismiss notifications · `<leader>pu` update plugins

> `<leader>a` (harpoon) shares a prefix with `<leader>at`/`<leader>ac`/`<leader>aT`
> (ng.nvim), so it fires after `timeoutlen`. This matches the previous config.
