local builtin = require "fzf-lua"
local utils = require "fzf-lua.utils"
local defaults = require "fzf-lua.defaults".defaults
local serpent = require "fzf-lua.lib.serpent"

local M = {}

function M.run_command(cmd, ...)
  local args = { ... }
  cmd = cmd or "builtin"

  if not builtin[cmd] then
    utils.info(string.format("invalid command '%s'", cmd))
    return
  end

  local opts = {}

  for _, arg in ipairs(args) do
    local key = arg:match("^[^=]+")
    local val = arg:match("=") and arg:match("=(.*)$")
    local ok, loaded = serpent.load(val or "true")
    if ok and (type(loaded) ~= "table" or not vim.tbl_isempty(loaded)) then
      opts[key] = loaded
    else
      opts[key] = val or true
    end
  end

  builtin[cmd](opts)
end

function M._candidates(line, cmp_items)
  local function to_cmp_items(t, data)
    local cmp = require("cmp")
    return vim.tbl_map(function(v)
      return {
        label = v,
        filterText = v,
        insertText = v,
        kind = cmp.lsp.CompletionItemKind.Variable,
        data = data,
      }
    end, t)
  end
  local builtin_list = vim.tbl_filter(function(k)
    return builtin._excluded_metamap[k] == nil
  end, vim.tbl_keys(builtin))

  local l = vim.split(line, "%s+")
  local n = #l - 2

  if n == 0 then
    local commands = vim.tbl_flatten({ builtin_list })
    table.sort(commands)

    commands = vim.tbl_filter(function(val)
      return vim.startswith(val, l[2])
    end, commands)

    return cmp_items and to_cmp_items(commands) or commands
  end

  -- Not all commands have their opts under the same key
  local function cmd2key(cmd)
    local cmd2cfg = {
      {
        patterns = { "^git_", "^dap", "^tmux_" },
        transform = function(c) return c:gsub("_", ".") end
      },
      {
        patterns = { "^lsp_code_actions$" },
        transform = function(_) return "lsp.code_actions" end
      },
      { patterns = { "^lsp_.*_symbols$" }, transform = function(_) return "lsp.symbols" end },
      { patterns = { "^lsp_" },            transform = function(_) return "lsp" end },
      { patterns = { "^diagnostics_" },    transform = function(_) return "dianostics" end },
      { patterns = { "^tags" },            transform = function(_) return "tags" end },
      { patterns = { "grep" },             transform = function(_) return "grep" end },
      { patterns = { "^complete_bline$" }, transform = function(_) return "complete_line" end },
    }
    for _, v in pairs(cmd2cfg) do
      for _, p in ipairs(v.patterns) do
        if cmd:match(p) then return v.transform(cmd) end
      end
    end
    return cmd
  end

  local cmd_cfg_key = cmd2key(l[2])
  local cmd_opts = utils.map_get(defaults, cmd_cfg_key) or {}
  local opts = vim.tbl_filter(function(k)
    return not k:match("^_")
  end, vim.tbl_keys(utils.map_flatten(cmd_opts)))

  -- Add globals recursively, e.g. `winopts.fullscreen`
  -- will be later retrieved using `utils.map_get(...)`
  for k, v in pairs({
    winopts       = false,
    keymap        = false,
    fzf_opts      = false,
    fzf_tmux_opts = false,
    __HLS         = "hls", -- rename prefix
  }) do
    opts = vim.tbl_flatten({ opts, vim.tbl_keys(utils.map_flatten(defaults[k] or {}, v or k)) })
  end

  -- Add generic options that apply to all pickers
  for _, o in ipairs({ "query" }) do
    table.insert(opts, o)
  end

  table.sort(opts)

  opts = vim.tbl_filter(function(val)
    return vim.startswith(val, l[#l])
  end, opts)

  return cmp_items and to_cmp_items(opts, { cmd = cmd_cfg_key }) or opts
end

return M
