# Fzf-Lua Options

## Setup

## Globals

#### winopts.row

Type: `number`, Default: `0.35`

Screen row where to place the fzf-lua float window, between 0-1 will represent precentage of `vim.o.lines` (0: top, 1: bottom), if >= 1 will attempt to place the float in the exact screen line.

#### winopts.col

Type: `number`, Default: `0.55`

Screen column where to place the fzf-lua float window, between 0-1 will represent precentage of `vim.o.columns` (0: leftmost, 1: rightmost), if >= 1 will attempt to place the float in the exact screen column.

#### winopts.preview.border

Type: `string`, Default: `border`

Applies only to fzf native previewers (i.e. `bat`, `git_status`), set to `noborder` to hide the preview border, consult `man fzf` for all vailable options.

### Cmd: files

Files picker, will enumrate the filesystem of the current working directory using `fd`, `rg` and `grep` or `dir.exe`.

#### files.cwd

Type: `string`, Default: `nil`

Sets the current working directory.

#### files.cwd_prompt

Type: `boolean`, Default: `true`

Display the current working directory in the prompt (`fzf.vim` style).

#### files.cwd_prompt_shorten_len

Type: `number`, Default: `32`

Prompt over this length will be shortened, e.g.  `~/.config/nvim/lua/` will be shortened to `~/.c/n/lua/` (for more info see `:help pathshorten`).

<sub><sup>*Requires `cwd_prompt=true`</sup></sub>

#### files.cwd_prompt_shorten_val

Type: `number`, Default: `1`

Length of shortened prompt path parts, e.g. set to `2`, `~/.config/nvim/lua/` will be shortened to `~/.co/nv/lua/` (for more info see `:help pathshorten`).

<sub><sup>*Requires `cwd_prompt=true`</sup></sub>

### Cmd: LSP commands

#### lsp_references

LSP references

#### async_or_timeout

Type: `number|boolean`, Default: `5000`

Whether LSP calls are made block, set to `true` for asynchronous, otherwise defines the timeout
(ms) for the LPS request via `vim.lsp.buf_request_sync`.

<!--- vim: set nospell: -->
